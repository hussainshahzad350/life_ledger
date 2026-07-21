import 'package:life_ledger/core/database/app_database.dart';
import 'package:life_ledger/core/error/failure.dart';
import 'package:life_ledger/core/error/result.dart';
import 'package:life_ledger/core/time/clock.dart';
import 'package:life_ledger/core/utils/id_generator.dart';
import 'package:life_ledger/features/food/domain/entities/food_entry.dart';
import 'package:life_ledger/features/food/domain/entities/food_item.dart';
import 'package:life_ledger/features/food/domain/repositories/food_repository.dart';
import 'package:life_ledger/features/food/infrastructure/food_dtos.dart';
import 'package:sqflite/sqflite.dart';

/// SQLite implementation of [FoodRepository] over `food_item`/`food_entry`
/// (docs/04 §4.3/§4.4). Nutrition is derived from item × quantity
/// (docs/04 §9); day grouping uses the stamped `local_date` (docs/04 §4.4).
class FoodRepositoryImpl implements FoodRepository {
  /// Creates the repository.
  FoodRepositoryImpl({
    required AppDatabase db,
    required Clock clock,
    required IdGenerator ids,
  }) : _db = db,
       _clock = clock,
       _ids = ids;

  final AppDatabase _db;
  final Clock _clock;
  final IdGenerator _ids;

  Database get _database => _db.database;

  @override
  Future<Result<List<FoodItem>>> search(String query, {int limit = 20}) async {
    try {
      final rows = await _database.query(
        'food_item',
        where: 'is_deleted = 0 AND name LIKE ?',
        whereArgs: ['$query%'],
        orderBy: 'is_favorite DESC, name',
        limit: limit,
      );
      return Result.success(rows.map(FoodDtos.itemFromRow).toList());
    } on DatabaseException catch (e) {
      return Result.failure(DatabaseFailure('food search failed', cause: e));
    }
  }

  @override
  Future<Result<List<FoodItem>>> recents(String userId, {int limit = 8}) async {
    try {
      // Distinct foods, most-recently logged first.
      final rows = await _database.rawQuery(
        '''
        SELECT ${FoodDtos.joinedEntryColumns},
               MAX(fe.logged_at) AS last_logged
        FROM food_entry fe
        JOIN food_item fi ON fi.id = fe.food_item_id
        WHERE fe.user_id = ? AND fe.is_deleted = 0
        GROUP BY fe.food_item_id
        ORDER BY last_logged DESC
        LIMIT ?
        ''',
        [userId, limit],
      );
      return Result.success(rows.map(FoodDtos.itemFromRow).toList());
    } on DatabaseException catch (e) {
      return Result.failure(DatabaseFailure('recents query failed', cause: e));
    }
  }

  @override
  Future<Result<List<FoodItem>>> favorites(String userId) async {
    try {
      final rows = await _database.query(
        'food_item',
        where: 'is_deleted = 0 AND is_favorite = 1',
        orderBy: 'name',
      );
      return Result.success(rows.map(FoodDtos.itemFromRow).toList());
    } on DatabaseException catch (e) {
      return Result.failure(
        DatabaseFailure('favorites query failed', cause: e),
      );
    }
  }

  @override
  Future<Result<FoodItem>> createCustomFood(FoodItem item) async {
    try {
      final now = _clock.nowUtc().millisecondsSinceEpoch;
      final stored = FoodItem(
        id: _ids.newId(),
        name: item.name,
        brand: item.brand,
        isCustom: true,
        isFavorite: item.isFavorite,
        servingSize: item.servingSize,
        servingUnit: item.servingUnit,
        nutrition: item.nutrition,
      );
      await _database.insert('food_item', FoodDtos.itemToRow(stored, now: now));
      return Result.success(stored);
    } on DatabaseException catch (e) {
      return Result.failure(
        DatabaseFailure('create custom food failed', cause: e),
      );
    }
  }

  @override
  Future<Result<void>> setFavorite(
    String foodItemId, {
    required bool value,
  }) async {
    try {
      await _database.update(
        'food_item',
        {
          'is_favorite': value ? 1 : 0,
          'updated_at': _clock.nowUtc().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [foodItemId],
      );
      return const Result.success(null);
    } on DatabaseException catch (e) {
      return Result.failure(DatabaseFailure('set favorite failed', cause: e));
    }
  }

  @override
  Future<Result<FoodEntry>> logEntry({
    required String userId,
    required String foodItemId,
    required double quantity,
    required MealSlot mealSlot,
    String? note,
  }) async {
    if (quantity <= 0) {
      return const Result.failure(
        ValidationFailure(field: 'quantity', reason: 'must be > 0'),
      );
    }
    try {
      final now = _clock.nowUtc();
      final id = _ids.newId();
      await _database.insert('food_entry', <String, Object?>{
        'id': id,
        'user_id': userId,
        'food_item_id': foodItemId,
        'logged_at': now.millisecondsSinceEpoch,
        'local_date': _clock.localDate(),
        'meal_slot': mealSlot.name,
        'quantity': quantity,
        'note': note,
        'created_at': now.millisecondsSinceEpoch,
        'updated_at': now.millisecondsSinceEpoch,
      });
      return _entryById(id);
    } on DatabaseException catch (e) {
      return Result.failure(DatabaseFailure('log entry failed', cause: e));
    }
  }

  @override
  Future<Result<FoodEntry>> editEntry({
    required String entryId,
    double? quantity,
    MealSlot? mealSlot,
    String? note,
  }) async {
    if (quantity != null && quantity <= 0) {
      return const Result.failure(
        ValidationFailure(field: 'quantity', reason: 'must be > 0'),
      );
    }
    try {
      final values = <String, Object?>{
        'updated_at': _clock.nowUtc().millisecondsSinceEpoch,
        'quantity': ?quantity,
        'meal_slot': ?mealSlot?.name,
        'note': ?note,
      };
      await _database.update(
        'food_entry',
        values,
        where: 'id = ?',
        whereArgs: [entryId],
      );
      return _entryById(entryId);
    } on DatabaseException catch (e) {
      return Result.failure(DatabaseFailure('edit entry failed', cause: e));
    }
  }

  @override
  Future<Result<void>> deleteEntry(String entryId) =>
      _setDeleted(entryId, deleted: true);

  @override
  Future<Result<void>> restoreEntry(String entryId) =>
      _setDeleted(entryId, deleted: false);

  Future<Result<void>> _setDeleted(
    String entryId, {
    required bool deleted,
  }) async {
    try {
      await _database.update(
        'food_entry',
        {
          'is_deleted': deleted ? 1 : 0,
          'updated_at': _clock.nowUtc().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [entryId],
      );
      return const Result.success(null);
    } on DatabaseException catch (e) {
      return Result.failure(DatabaseFailure('soft-delete failed', cause: e));
    }
  }

  @override
  Future<Result<List<FoodEntry>>> entriesForDate(
    String userId,
    String localDate,
  ) async {
    try {
      final rows = await _database.rawQuery(
        '''
        SELECT ${FoodDtos.joinedEntryColumns}
        FROM food_entry fe
        JOIN food_item fi ON fi.id = fe.food_item_id
        WHERE fe.user_id = ? AND fe.local_date = ? AND fe.is_deleted = 0
        ORDER BY fe.logged_at ASC
        ''',
        [userId, localDate],
      );
      return Result.success(rows.map(FoodDtos.entryFromJoinedRow).toList());
    } on DatabaseException catch (e) {
      return Result.failure(DatabaseFailure('timeline query failed', cause: e));
    }
  }

  Future<Result<FoodEntry>> _entryById(String entryId) async {
    final rows = await _database.rawQuery(
      '''
      SELECT ${FoodDtos.joinedEntryColumns}
      FROM food_entry fe
      JOIN food_item fi ON fi.id = fe.food_item_id
      WHERE fe.id = ?
      ''',
      [entryId],
    );
    if (rows.isEmpty) {
      return Result.failure(NotFoundFailure(entity: 'FoodEntry', id: entryId));
    }
    return Result.success(FoodDtos.entryFromJoinedRow(rows.single));
  }
}
