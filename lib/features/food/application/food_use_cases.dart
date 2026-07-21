import 'package:life_ledger/core/error/result.dart';
import 'package:life_ledger/features/food/domain/entities/food_entry.dart';
import 'package:life_ledger/features/food/domain/entities/food_item.dart';
import 'package:life_ledger/features/food/domain/repositories/food_repository.dart';

/// Logs a food entry (docs/08 F3). Thin orchestration over the repository;
/// quantity validation lives in the domain/repository.
class LogFoodEntry {
  /// Creates the use case.
  const LogFoodEntry(this._repository);

  final FoodRepository _repository;

  /// Logs [quantity] servings of [foodItemId] at [mealSlot].
  Future<Result<FoodEntry>> call({
    required String userId,
    required String foodItemId,
    required double quantity,
    required MealSlot mealSlot,
    String? note,
  }) => _repository.logEntry(
    userId: userId,
    foodItemId: foodItemId,
    quantity: quantity,
    mealSlot: mealSlot,
    note: note,
  );
}

/// Returns the day's food entries, grouped into meal timelines
/// (docs/08 F3, docs/05 §5.3).
class GetDayTimeline {
  /// Creates the use case.
  const GetDayTimeline(this._repository);

  final FoodRepository _repository;

  /// Loads and groups [localDate]'s entries by meal, in meal order.
  Future<Result<DayTimeline>> call({
    required String userId,
    required String localDate,
  }) async {
    final result = await _repository.entriesForDate(userId, localDate);
    return result.map(DayTimeline.fromEntries);
  }
}

/// The day's food entries grouped by meal, with derived totals.
class DayTimeline {
  /// Creates a timeline from pre-grouped data.
  const DayTimeline({required this.byMeal, required this.total});

  /// Groups [entries] by meal (in canonical meal order) and sums nutrition.
  factory DayTimeline.fromEntries(List<FoodEntry> entries) {
    final byMeal = <MealSlot, List<FoodEntry>>{
      for (final slot in MealSlot.values) slot: <FoodEntry>[],
    };
    var total = Nutrition.zero;
    for (final entry in entries) {
      byMeal[entry.mealSlot]!.add(entry);
      total = total + entry.nutrition;
    }
    return DayTimeline(byMeal: byMeal, total: total);
  }

  /// Entries grouped by meal (every slot present, possibly empty).
  final Map<MealSlot, List<FoodEntry>> byMeal;

  /// The day's total nutrition across all meals.
  final Nutrition total;

  /// Whether nothing has been logged yet (drives the empty state).
  bool get isEmpty => byMeal.values.every((list) => list.isEmpty);
}
