import 'package:life_ledger/core/database/app_database.dart';
import 'package:life_ledger/core/error/failure.dart';
import 'package:life_ledger/core/error/result.dart';
import 'package:life_ledger/core/time/clock.dart';
import 'package:life_ledger/core/utils/id_generator.dart';
import 'package:life_ledger/features/water/domain/repositories/water_repository.dart';
import 'package:sqflite/sqflite.dart';

/// SQLite implementation of [WaterRepository] over `water_entry`
/// (docs/04 §4.5). Totals are aggregated in SQL (docs/14 §4).
class WaterRepositoryImpl implements WaterRepository {
  /// Creates the repository.
  WaterRepositoryImpl({
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
  Future<Result<double>> addWater({
    required String userId,
    required double amountMl,
  }) async {
    if (amountMl <= 0) {
      return const Result.failure(
        ValidationFailure(field: 'amountMl', reason: 'must be > 0'),
      );
    }
    try {
      final now = _clock.nowUtc();
      final localDate = _clock.localDate();
      await _db.database.insert('water_entry', <String, Object?>{
        'id': _ids.newId(),
        'user_id': userId,
        'logged_at': now.millisecondsSinceEpoch,
        'local_date': localDate,
        'amount_ml': amountMl,
        'created_at': now.millisecondsSinceEpoch,
        'updated_at': now.millisecondsSinceEpoch,
      });
      return totalForDate(userId, localDate);
    } on DatabaseException catch (e) {
      return Result.failure(DatabaseFailure('add water failed', cause: e));
    }
  }

  @override
  Future<Result<double>> totalForDate(String userId, String localDate) async {
    try {
      final rows = await _db.database.rawQuery(
        '''
        SELECT COALESCE(SUM(amount_ml), 0) AS total
        FROM water_entry
        WHERE user_id = ? AND local_date = ? AND is_deleted = 0
        ''',
        [userId, localDate],
      );
      return Result.success((rows.single['total']! as num).toDouble());
    } on DatabaseException catch (e) {
      return Result.failure(DatabaseFailure('water total failed', cause: e));
    }
  }
}
