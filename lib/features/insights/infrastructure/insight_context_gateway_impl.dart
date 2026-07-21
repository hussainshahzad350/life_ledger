import 'package:life_ledger/core/ai/ai_constants.dart';
import 'package:life_ledger/core/ai/insight.dart';
import 'package:life_ledger/core/database/app_database.dart';
import 'package:life_ledger/core/error/failure.dart';
import 'package:life_ledger/core/error/result.dart';
import 'package:life_ledger/core/time/clock.dart';
import 'package:life_ledger/features/goals/domain/entities/goal.dart';
import 'package:life_ledger/features/goals/domain/repositories/goal_repository.dart';
import 'package:life_ledger/features/insights/domain/insight_record.dart';
import 'package:sqflite/sqflite.dart';

/// Builds an [InsightContext] from persisted data (docs/07 §3).
///
/// This is the seam between storage and the pure rule engine: it pre-aggregates
/// the trailing window into the per-date maps the rules expect, treating a
/// missing date as "not logged" (never zero). Curated food↔symptom flag pairs
/// (`foodFlagDates`) are a documented sourcing task (docs/07 §5, docs/17); until
/// that catalog lands the food↔symptom rule simply stays silent.
class InsightContextGatewayImpl implements InsightContextGateway {
  /// Creates the gateway.
  InsightContextGatewayImpl({
    required AppDatabase db,
    required GoalRepository goals,
    required Clock clock,
  }) : _db = db,
       _goals = goals,
       _clock = clock;

  final AppDatabase _db;
  final GoalRepository _goals;
  final Clock _clock;

  @override
  Future<Result<InsightContext>> buildContext(
    String userId, {
    int windowDays = AiConstants.corrWindowDays,
  }) async {
    final today = _clock.localDate();
    final window = dateWindow(today, windowDays);
    final startDate = window.first;
    final args = [userId, startDate, today];
    try {
      final db = _db.database;

      final proteinRows = await db.rawQuery('''
        SELECT fe.local_date AS d, SUM(fi.protein_g * fe.quantity) AS v
        FROM food_entry fe
        JOIN food_item fi ON fi.id = fe.food_item_id
        WHERE fe.user_id = ? AND fe.local_date BETWEEN ? AND ?
          AND fe.is_deleted = 0
        GROUP BY fe.local_date
        ''', args);
      final waterRows = await _groupSum('water_entry', 'amount_ml', args);
      final weightRows = await db.rawQuery('''
        SELECT local_date AS d, AVG(weight_kg) AS v
        FROM weight_entry
        WHERE user_id = ? AND local_date BETWEEN ? AND ? AND is_deleted = 0
        GROUP BY local_date
        ''', args);
      final moodRows = await db.rawQuery('''
        SELECT local_date AS d, AVG(mood) AS v
        FROM mood_entry
        WHERE user_id = ? AND local_date BETWEEN ? AND ? AND is_deleted = 0
        GROUP BY local_date
        ''', args);
      final sleepRows = await _groupSum('sleep_entry', 'duration_min', args);
      final symptomRows = await db.rawQuery('''
        SELECT se.local_date AS d, st.name AS name
        FROM symptom_entry se
        JOIN symptom_type st ON st.id = se.symptom_type_id
        WHERE se.user_id = ? AND se.local_date BETWEEN ? AND ?
          AND se.is_deleted = 0
        ''', args);
      final waterEventRows = await db.query(
        'water_entry',
        columns: ['local_date', 'logged_at', 'amount_ml'],
        where: 'user_id = ? AND local_date BETWEEN ? AND ? AND is_deleted = 0',
        whereArgs: args,
      );

      final proteinByDate = _toDoubleMap(proteinRows);
      final waterByDate = _toDoubleMap(waterRows);
      final weightByDate = _toDoubleMap(weightRows);
      final moodByDate = <String, int>{
        for (final r in moodRows) r['d']! as String: (r['v']! as num).round(),
      };
      final sleepByDate = <String, int>{
        for (final r in sleepRows) r['d']! as String: (r['v']! as num).round(),
      };

      final symptomDates = <String, Set<String>>{};
      for (final r in symptomRows) {
        final name = r['name']! as String;
        final date = r['d']! as String;
        (symptomDates[name] ??= <String>{}).add(date);
      }

      final waterEventsByDate = <String, List<WaterEvent>>{};
      for (final r in waterEventRows) {
        final date = r['local_date']! as String;
        final at = DateTime.fromMillisecondsSinceEpoch(
          r['logged_at']! as int,
          isUtc: true,
        ).toLocal();
        (waterEventsByDate[date] ??= <WaterEvent>[]).add(
          WaterEvent(
            hourOfDay: at.hour,
            amountMl: (r['amount_ml']! as num).toDouble(),
          ),
        );
      }

      // Logged days = any day the window touched any tracker.
      final loggedDates = <String>{
        ...proteinByDate.keys,
        ...waterByDate.keys,
        ...weightByDate.keys,
        ...moodByDate.keys,
        ...sleepByDate.keys,
        for (final dates in symptomDates.values) ...dates,
      };

      final activeGoals =
          (await _goals.getActiveGoals(userId)).valueOrNull ?? const <Goal>[];
      double goalOf(GoalType type) {
        for (final g in activeGoals) {
          if (g.type == type) return g.targetValue;
        }
        return 0;
      }

      return Result.success(
        InsightContext(
          today: today,
          proteinGByDate: proteinByDate,
          proteinGoalG: goalOf(GoalType.protein),
          waterMlByDate: waterByDate,
          waterGoalMl: goalOf(GoalType.water),
          weightKgByDate: weightByDate,
          moodByDate: moodByDate,
          sleepMinutesByDate: sleepByDate,
          loggedDates: loggedDates,
          symptomDates: symptomDates,
          waterEventsByDate: waterEventsByDate,
        ),
      );
    } on DatabaseException catch (e) {
      return Result.failure(
        DatabaseFailure('insight context build failed', cause: e),
      );
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
}
