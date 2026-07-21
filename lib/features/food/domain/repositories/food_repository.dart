import 'package:life_ledger/core/error/result.dart';
import 'package:life_ledger/features/food/domain/entities/food_entry.dart';
import 'package:life_ledger/features/food/domain/entities/food_item.dart';

/// Catalog + logging persistence for food (docs/08 F3).
abstract interface class FoodRepository {
  /// Searches the catalog by name/alias prefix (docs/17 §4).
  Future<Result<List<FoodItem>>> search(String query, {int limit = 20});

  /// The user's most-recently-logged distinct foods (Quick Add default,
  /// docs/05 §5.2).
  Future<Result<List<FoodItem>>> recents(String userId, {int limit = 8});

  /// The user's favorite foods.
  Future<Result<List<FoodItem>>> favorites(String userId);

  /// Creates a user food and returns it.
  Future<Result<FoodItem>> createCustomFood(FoodItem item);

  /// Toggles the favorite flag on a catalog item.
  Future<Result<void>> setFavorite(String foodItemId, {required bool value});

  /// Logs a food entry (nutrition derived from item × quantity).
  Future<Result<FoodEntry>> logEntry({
    required String userId,
    required String foodItemId,
    required double quantity,
    required MealSlot mealSlot,
    String? note,
  });

  /// Edits an entry's quantity/meal/note.
  Future<Result<FoodEntry>> editEntry({
    required String entryId,
    double? quantity,
    MealSlot? mealSlot,
    String? note,
  });

  /// Soft-deletes an entry (recoverable via Undo, docs/05 §6).
  Future<Result<void>> deleteEntry(String entryId);

  /// Restores a soft-deleted entry (the Undo action).
  Future<Result<void>> restoreEntry(String entryId);

  /// All entries for a local date, ordered by time (the meal timeline,
  /// docs/08 F3).
  Future<Result<List<FoodEntry>>> entriesForDate(
    String userId,
    String localDate,
  );

  /// The day's derived nutrition totals, aggregated in SQL for the dashboard
  /// (docs/08 F10, docs/14 §4).
  Future<Result<Nutrition>> totalsForDate(String userId, String localDate);
}
