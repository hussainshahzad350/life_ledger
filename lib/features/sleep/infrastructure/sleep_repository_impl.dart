import 'package:life_ledger/core/database/app_database.dart';
import 'package:life_ledger/core/error/failure.dart';
import 'package:life_ledger/core/error/result.dart';
import 'package:life_ledger/core/time/clock.dart';
import 'package:life_ledger/core/utils/id_generator.dart';
import 'package:life_ledger/features/sleep/domain/sleep_entry.dart';
import 'package:sqflite/sqflite.dart';

/// SQLite implementation of [SleepRepository] over `sleep_entry`
/// (docs/04 §4.5).
class SleepRepositoryImpl implements SleepRepository {
  /// Creates the repository.
  SleepRepositoryImpl({
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
  Future<Result<SleepEntry>> add({
    required String userId,
    required int durationMin,
    int? quality,
  }) async {
    if (durationMin < 0) {
      return const Result.failure(
        ValidationFailure(field: 'durationMin', reason: 'must be >= 0'),
      );
    }
    if (quality != null && (quality < 1 || quality > 5)) {
      return const Result.failure(
        ValidationFailure(field: 'quality', reason: 'must be 1..5'),
      );
    }
    try {
      final now = _clock.nowUtc();
      final entry = SleepEntry(
        id: _ids.newId(),
        userId: userId,
        durationMin: durationMin,
        quality: quality,
        loggedAt: now,
        localDate: _clock.localDate(),
      );
      await _db.database.insert('sleep_entry', <String, Object?>{
        'id': entry.id,
        'user_id': userId,
        'logged_at': now.millisecondsSinceEpoch,
        'local_date': entry.localDate,
        'duration_min': durationMin,
        'quality': quality,
        'created_at': now.millisecondsSinceEpoch,
        'updated_at': now.millisecondsSinceEpoch,
      });
      return Result.success(entry);
    } on DatabaseException catch (e) {
      return Result.failure(DatabaseFailure('sleep write failed', cause: e));
    }
  }

  @override
  Future<Result<SleepEntry?>> forDate(String userId, String localDate) async {
    try {
      final rows = await _db.database.query(
        'sleep_entry',
        where: 'user_id = ? AND local_date = ? AND is_deleted = 0',
        whereArgs: [userId, localDate],
        orderBy: 'logged_at DESC, rowid DESC',
        limit: 1,
      );
      if (rows.isEmpty) return const Result.success(null);
      final row = rows.single;
      return Result.success(
        SleepEntry(
          id: row['id']! as String,
          userId: row['user_id']! as String,
          durationMin: row['duration_min']! as int,
          quality: row['quality'] as int?,
          loggedAt: DateTime.fromMillisecondsSinceEpoch(
            row['logged_at']! as int,
            isUtc: true,
          ),
          localDate: row['local_date']! as String,
        ),
      );
    } on DatabaseException catch (e) {
      return Result.failure(DatabaseFailure('sleep read failed', cause: e));
    }
  }
}
