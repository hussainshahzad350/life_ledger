import 'package:equatable/equatable.dart';
import 'package:life_ledger/features/food/domain/entities/food_item.dart';

/// The meal an entry belongs to (docs/04 §4.4).
enum MealSlot {
  /// Morning meal.
  breakfast,

  /// Midday meal.
  lunch,

  /// Evening meal.
  dinner,

  /// Anything between meals.
  snack;

  /// The meal slot suggested for a given local [hour] (docs/05 §5.2 —
  /// pre-select by time of day to remove a decision).
  static MealSlot forHour(int hour) {
    if (hour < 11) return MealSlot.breakfast;
    if (hour < 15) return MealSlot.lunch;
    if (hour < 21) return MealSlot.dinner;
    return MealSlot.snack;
  }
}

/// A logged food (docs/04 §4.4, docs/08 F3): a [FoodItem] consumed in some
/// [quantity] (multiples of the item's serving) at a meal.
///
/// Nutrition is **derived** from the item × quantity (docs/04 §9), so the
/// entry carries a snapshot of the item for display and totals.
class FoodEntry extends Equatable {
  /// Creates an entry.
  const FoodEntry({
    required this.id,
    required this.userId,
    required this.item,
    required this.quantity,
    required this.mealSlot,
    required this.loggedAt,
    required this.localDate,
    this.note,
  });

  /// Row id (UUID).
  final String id;

  /// Owning profile id.
  final String userId;

  /// The catalog food (joined for display/totals).
  final FoodItem item;

  /// Number of servings logged (> 0).
  final double quantity;

  /// Which meal this belongs to.
  final MealSlot mealSlot;

  /// UTC instant of consumption.
  final DateTime loggedAt;

  /// The user's local calendar day (`YYYY-MM-DD`, docs/04 §4.4).
  final String localDate;

  /// Optional note.
  final String? note;

  /// This entry's contribution to daily nutrition (item × quantity).
  Nutrition get nutrition => item.nutrition.scaled(quantity);

  @override
  List<Object?> get props => [
    id,
    userId,
    item,
    quantity,
    mealSlot,
    loggedAt,
    localDate,
    note,
  ];
}
