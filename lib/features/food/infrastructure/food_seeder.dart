import 'package:life_ledger/core/database/app_database.dart';
import 'package:life_ledger/core/error/failure.dart';
import 'package:life_ledger/core/error/result.dart';
import 'package:life_ledger/features/food/infrastructure/food_dtos.dart';
import 'package:life_ledger/features/food/infrastructure/starter_foods.dart';
import 'package:sqflite/sqflite.dart';

/// Seeds the bundled starter foods (docs/17 §5) idempotently on startup.
///
/// The starter set is loaded from Dart (not a migration) so it can grow
/// without a schema bump; stable `sf-*` ids + `INSERT OR IGNORE` make it
/// safe to run on every launch. It does not overwrite user edits.
class FoodSeeder {
  /// Creates the seeder.
  FoodSeeder(this._db);

  final AppDatabase _db;

  /// Inserts any missing starter foods. Returns the number inserted.
  Future<Result<int>> seed() async {
    try {
      const seedTime = 0; // installer-seeded marker (not user data).
      var inserted = 0;
      await _db.database.transaction((txn) async {
        for (final item in StarterFoods.all) {
          final count = await txn.insert(
            'food_item',
            FoodDtos.itemToRow(item, now: seedTime, createdAt: seedTime),
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
          if (count > 0) inserted++;
        }
      });
      return Result.success(inserted);
    } on DatabaseException catch (e) {
      return Result.failure(DatabaseFailure('food seed failed', cause: e));
    }
  }
}
