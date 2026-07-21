import 'package:life_ledger/core/database/app_database.dart';
import 'package:life_ledger/core/error/failure.dart';
import 'package:life_ledger/core/error/result.dart';
import 'package:life_ledger/core/time/clock.dart';
import 'package:life_ledger/features/goals/domain/entities/goal.dart';
import 'package:life_ledger/features/reports/domain/report_models.dart';
import 'package:sqflite/sqflite.dart';

/// SQLite implementation of [ReportRepository] (docs/08 F12).
///
/// Aggregation is pushed into indexed `GROUP BY local_date` queries — one per
/// metric over the same date window — then merged in Dart into one point per
/// calendar day. The window is bounded (≤ 365 days) so even the year view
/// stays well inside the NFR-3 budget (docs/14 §4).
class ReportRepositoryImpl implements ReportRepository {
  /// Creates the repository.
  ReportRepositoryImpl({required AppDatabase db, required Clock clock})
    : _db = db,
      _clock = clock;

  final AppDatabase _db;
  final Clock _clock;

  @override
  Future<Result<ReportSummary>> summary({
    required String userId,
    required ReportRange range,
    DateTime? anchor,
  }) async {
    final window = ReportWindow.of(range, anchor ?? _clock.nowLocal());
    final args = [userId, window.startDate, window.endDate];
    try {
      final db = _db.database;

      final nutrition = await db.rawQuery('''
        SELECT fe.local_date AS d,
               SUM(fi.calories * fe.quantity) AS calories,
               SUM(fi.protein_g * fe.quantity) AS protein
        FROM food_entry fe
        JOIN food_item fi ON fi.id = fe.food_item_id
        WHERE fe.user_id = ? AND fe.local_date BETWEEN ? AND ?
          AND fe.is_deleted = 0
        GROUP BY fe.local_date
        ''', args);
      final water = await _groupSum('water_entry', 'amount_ml', args);
      final weight = await db.rawQuery('''
        SELECT local_date AS d, AVG(weight_kg) AS v
        FROM weight_entry
        WHERE user_id = ? AND local_date BETWEEN ? AND ? AND is_deleted = 0
        GROUP BY local_date
        ''', args);
      final sleep = await _groupSum('sleep_entry', 'duration_min', args);
      final mood = await db.rawQuery('''
        SELECT local_date AS d, AVG(mood) AS v
        FROM mood_entry
        WHERE user_id = ? AND local_date BETWEEN ? AND ? AND is_deleted = 0
        GROUP BY local_date
        ''', args);
      final exercise = await _groupSum('exercise_entry', 'duration_min', args);
      final symptoms = await db.rawQuery('''
        SELECT local_date AS d, COUNT(*) AS v
        FROM symptom_entry
        WHERE user_id = ? AND local_date BETWEEN ? AND ? AND is_deleted = 0
        GROUP BY local_date
        ''', args);

      final cal = <String, double>{};
      final prot = <String, double>{};
      for (final r in nutrition) {
        final d = r['d']! as String;
        cal[d] = (r['calories'] as num?)?.toDouble() ?? 0;
        prot[d] = (r['protein'] as num?)?.toDouble() ?? 0;
      }
      final waterByDay = _toDoubleMap(water);
      final weightByDay = _toDoubleMap(weight);
      final sleepByDay = _toDoubleMap(sleep);
      final moodByDay = _toDoubleMap(mood);
      final exByDay = _toDoubleMap(exercise);
      final sympByDay = _toDoubleMap(symptoms);

      final points = [
        for (final d in window.dates)
          DailyPoint(
            localDate: d,
            calories: cal[d] ?? 0,
            proteinG: prot[d] ?? 0,
            waterMl: waterByDay[d] ?? 0,
            weightKg: weightByDay[d],
            sleepMin: sleepByDay[d]?.round(),
            moodAvg: moodByDay[d],
            exerciseMin: exByDay[d]?.round() ?? 0,
            symptomCount: sympByDay[d]?.round() ?? 0,
          ),
      ];

      final goals = await _overlappingGoals(userId, window);

      return Result.success(
        ReportSummary(
          range: range,
          window: window,
          points: points,
          goals: goals,
        ),
      );
    } on DatabaseException catch (e) {
      return Result.failure(DatabaseFailure('report query failed', cause: e));
    }
  }

  Future<List<Map<String, Object?>>> _groupSum(
    String table,
    String column,
    List<Object?> args,
  ) {
    return _db.database.rawQuery('''
      SELECT local_date AS d, SUM($column) AS v
      FROM $table
      WHERE user_id = ? AND local_date BETWEEN ? AND ? AND is_deleted = 0
      GROUP BY local_date
      ''', args);
  }

  Map<String, double> _toDoubleMap(List<Map<String, Object?>> rows) {
    return {
      for (final r in rows)
        r['d']! as String: (r['v'] as num?)?.toDouble() ?? 0,
    };
  }

  /// Goals whose validity window intersects the report window (any type),
  /// so [ReportSummary.targetFor] can resolve the goal in force per day.
  Future<List<Goal>> _overlappingGoals(
    String userId,
    ReportWindow window,
  ) async {
    final startMs = _dayStartMs(window.startDate);
    final endMs =
        _dayStartMs(window.endDate) + const Duration(days: 1).inMilliseconds;
    final rows = await _db.database.query(
      'goal',
      where:
          'user_id = ? AND is_deleted = 0 AND effective_from < ? '
          'AND (effective_to IS NULL OR effective_to > ?)',
      whereArgs: [userId, endMs, startMs],
    );
    return rows.map(_goalFromRow).toList();
  }

  int _dayStartMs(String localDate) {
    final p = localDate.split('-').map(int.parse).toList();
    return DateTime(p[0], p[1], p[2]).millisecondsSinceEpoch;
  }

  Goal _goalFromRow(Map<String, Object?> row) => Goal(
    id: row['id']! as String,
    userId: row['user_id']! as String,
    type: GoalType.values.byName(row['type']! as String),
    targetValue: (row['target_value']! as num).toDouble(),
    source: GoalSource.values.byName(row['source']! as String),
    effectiveFrom: DateTime.fromMillisecondsSinceEpoch(
      row['effective_from']! as int,
    ),
    effectiveTo: row['effective_to'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(row['effective_to']! as int),
  );
}
