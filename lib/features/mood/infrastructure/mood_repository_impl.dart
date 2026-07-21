import 'package:life_ledger/core/database/app_database.dart';
import 'package:life_ledger/core/error/failure.dart';
import 'package:life_ledger/core/error/result.dart';
import 'package:life_ledger/core/time/clock.dart';
import 'package:life_ledger/core/utils/id_generator.dart';
import 'package:life_ledger/features/mood/domain/mood_entry.dart';
import 'package:sqflite/sqflite.dart';

/// SQLite implementation of [MoodRepository] over `mood_entry`
/// (docs/04 §4.5).
class MoodRepositoryImpl implements MoodRepository {
  /// Creates the repository.
  MoodRepositoryImpl({
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
  Future<Result<MoodEntry>> add({
    required String userId,
    required int mood,
    String? note,
  }) async {
    if (mood < 1 || mood > 5) {
      return const Result.failure(
        ValidationFailure(field: 'mood', reason: 'must be 1..5'),
      );
    }
    try {
      final now = _clock.nowUtc();
      final entry = MoodEntry(
        id: _ids.newId(),
        userId: userId,
        mood: mood,
        note: note,
        loggedAt: now,
        localDate: _clock.localDate(),
      );
      await _db.database.insert('mood_entry', <String, Object?>{
        'id': entry.id,
        'user_id': userId,
        'logged_at': now.millisecondsSinceEpoch,
        'local_date': entry.localDate,
        'mood': mood,
        'note': note,
        'created_at': now.millisecondsSinceEpoch,
        'updated_at': now.millisecondsSinceEpoch,
      });
      return Result.success(entry);
    } on DatabaseException catch (e) {
      return Result.failure(DatabaseFailure('mood write failed', cause: e));
    }
  }

  @override
  Future<Result<MoodEntry?>> forDate(String userId, String localDate) async {
    try {
      final rows = await _db.database.query(
        'mood_entry',
        where: 'user_id = ? AND local_date = ? AND is_deleted = 0',
        whereArgs: [userId, localDate],
        orderBy: 'logged_at DESC, rowid DESC',
        limit: 1,
      );
      if (rows.isEmpty) return const Result.success(null);
      final row = rows.single;
      return Result.success(
        MoodEntry(
          id: row['id']! as String,
          userId: row['user_id']! as String,
          mood: row['mood']! as int,
          note: row['note'] as String?,
          loggedAt: DateTime.fromMillisecondsSinceEpoch(
            row['logged_at']! as int,
            isUtc: true,
          ),
          localDate: row['local_date']! as String,
        ),
      );
    } on DatabaseException catch (e) {
      return Result.failure(DatabaseFailure('mood read failed', cause: e));
    }
  }
}
