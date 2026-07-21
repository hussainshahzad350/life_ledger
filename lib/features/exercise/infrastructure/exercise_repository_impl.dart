import 'package:life_ledger/core/database/app_database.dart';
import 'package:life_ledger/core/error/failure.dart';
import 'package:life_ledger/core/error/result.dart';
import 'package:life_ledger/core/time/clock.dart';
import 'package:life_ledger/core/utils/id_generator.dart';
import 'package:life_ledger/features/exercise/domain/exercise_entry.dart';
import 'package:sqflite/sqflite.dart';

/// SQLite implementation of [ExerciseRepository] over `exercise_entry`
/// (docs/04 §4.5).
class ExerciseRepositoryImpl implements ExerciseRepository {
  /// Creates the repository.
  ExerciseRepositoryImpl({
    required AppDatabase db,
    required Clock clock,
    required IdGenerator ids,
  }) : _db = db,
       _clock = clock,
       _ids = ids;

  final AppDatabase _db;
  final Clock _clock;
  final IdGenerator _ids;

  @override
  Future<Result<ExerciseEntry>> add({
    required String userId,
    required String activity,
    required int durationMin,
    ExerciseIntensity? intensity,
    double? energyKcal,
  }) async {
    if (activity.trim().isEmpty) {
      return const Result.failure(
        ValidationFailure(field: 'activity', reason: 'must not be empty'),
      );
    }
    if (durationMin < 0) {
      return const Result.failure(
        ValidationFailure(field: 'durationMin', reason: 'must be >= 0'),
      );
    }
    if (energyKcal != null && energyKcal < 0) {
      return const Result.failure(
        ValidationFailure(field: 'energyKcal', reason: 'must be >= 0'),
      );
    }
    try {
      final now = _clock.nowUtc();
      final entry = ExerciseEntry(
        id: _ids.newId(),
        userId: userId,
        activity: activity.trim(),
        durationMin: durationMin,
        intensity: intensity,
        energyKcal: energyKcal,
        loggedAt: now,
        localDate: _clock.localDate(),
      );
      await _db.database.insert('exercise_entry', <String, Object?>{
        'id': entry.id,
        'user_id': userId,
        'logged_at': now.millisecondsSinceEpoch,
        'local_date': entry.localDate,
        'activity': entry.activity,
        'duration_min': durationMin,
        'intensity': intensity?.name,
        'energy_kcal': energyKcal,
        'created_at': now.millisecondsSinceEpoch,
        'updated_at': now.millisecondsSinceEpoch,
      });
      return Result.success(entry);
    } on DatabaseException catch (e) {
      return Result.failure(DatabaseFailure('exercise write failed', cause: e));
    }
  }

  @override
  Future<Result<List<ExerciseEntry>>> forDate(
    String userId,
    String localDate,
  ) async {
    try {
      final rows = await _db.database.query(
        'exercise_entry',
        where: 'user_id = ? AND local_date = ? AND is_deleted = 0',
        whereArgs: [userId, localDate],
        orderBy: 'logged_at DESC, rowid DESC',
      );
      return Result.success(
        rows
            .map(
              (r) => ExerciseEntry(
                id: r['id']! as String,
                userId: r['user_id']! as String,
                activity: r['activity']! as String,
                durationMin: r['duration_min']! as int,
                intensity: ExerciseIntensity.fromToken(
                  r['intensity'] as String?,
                ),
                energyKcal: (r['energy_kcal'] as num?)?.toDouble(),
                loggedAt: DateTime.fromMillisecondsSinceEpoch(
                  r['logged_at']! as int,
                  isUtc: true,
                ),
                localDate: r['local_date']! as String,
              ),
            )
            .toList(),
      );
    } on DatabaseException catch (e) {
      return Result.failure(DatabaseFailure('exercise read failed', cause: e));
    }
  }
}
