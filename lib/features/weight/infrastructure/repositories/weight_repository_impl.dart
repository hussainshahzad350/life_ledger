import 'package:life_ledger/core/database/app_database.dart';
import 'package:life_ledger/core/error/failure.dart';
import 'package:life_ledger/core/error/result.dart';
import 'package:life_ledger/core/time/clock.dart';
import 'package:life_ledger/core/utils/id_generator.dart';
import 'package:life_ledger/features/weight/domain/entities/weight_entry.dart';
import 'package:life_ledger/features/weight/domain/repositories/weight_repository.dart';
import 'package:sqflite/sqflite.dart';

/// SQLite implementation of [WeightRepository] over `weight_entry`
/// (docs/04 §4.5). `local_date` is stamped at write time (docs/04 §4.4).
class WeightRepositoryImpl implements WeightRepository {
  /// Creates the repository.
  WeightRepositoryImpl({
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
  Future<Result<WeightEntry>> addEntry({
    required String userId,
    required double weightKg,
  }) async {
    try {
      final nowUtc = _clock.nowUtc();
      final entry = WeightEntry(
        id: _ids.newId(),
        userId: userId,
        weightKg: weightKg,
        loggedAt: nowUtc,
        localDate: _clock.localDate(),
      );
      await _db.database.insert('weight_entry', <String, Object?>{
        'id': entry.id,
        'user_id': entry.userId,
        'logged_at': entry.loggedAt.millisecondsSinceEpoch,
        'local_date': entry.localDate,
        'weight_kg': entry.weightKg,
        'created_at': nowUtc.millisecondsSinceEpoch,
        'updated_at': nowUtc.millisecondsSinceEpoch,
      });
      return Result.success(entry);
    } on DatabaseException catch (e) {
      return Result.failure(DatabaseFailure('weight write failed', cause: e));
    }
  }

  @override
  Future<Result<WeightEntry?>> getLatest(String userId) async {
    try {
      final rows = await _db.database.query(
        'weight_entry',
        where: 'user_id = ? AND is_deleted = 0',
        whereArgs: [userId],
        orderBy: 'logged_at DESC',
        limit: 1,
      );
      if (rows.isEmpty) return const Result.success(null);
      final row = rows.single;
      return Result.success(
        WeightEntry(
          id: row['id']! as String,
          userId: row['user_id']! as String,
          weightKg: (row['weight_kg']! as num).toDouble(),
          loggedAt: DateTime.fromMillisecondsSinceEpoch(
            row['logged_at']! as int,
            isUtc: true,
          ),
          localDate: row['local_date']! as String,
        ),
      );
    } on DatabaseException catch (e) {
      return Result.failure(DatabaseFailure('weight read failed', cause: e));
    }
  }
}
