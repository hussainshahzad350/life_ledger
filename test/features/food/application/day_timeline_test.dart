import 'package:flutter_test/flutter_test.dart';
import 'package:life_ledger/features/food/application/food_use_cases.dart';
import 'package:life_ledger/features/food/domain/entities/food_entry.dart';
import 'package:life_ledger/features/food/domain/entities/food_item.dart';

FoodEntry entry(String id, MealSlot slot, double kcal, {double protein = 0}) {
  return FoodEntry(
    id: id,
    userId: 'u1',
    quantity: 1,
    mealSlot: slot,
    loggedAt: DateTime.utc(2026, 7, 21),
    localDate: '2026-07-21',
    item: FoodItem(
      id: 'f-$id',
      name: id,
      servingSize: 1,
      servingUnit: 'piece',
      nutrition: Nutrition(
        calories: kcal,
        proteinG: protein,
        carbsG: 0,
        fatG: 0,
        fiberG: 0,
        sugarG: 0,
      ),
    ),
  );
}

void main() {
  group('DayTimeline (docs/05 §5.3)', () {
    test('groups entries by meal and sums nutrition', () {
      final timeline = DayTimeline.fromEntries([
        entry('a', MealSlot.breakfast, 100, protein: 10),
        entry('b', MealSlot.breakfast, 50),
        entry('c', MealSlot.lunch, 200, protein: 20),
      ]);
      expect(timeline.byMeal[MealSlot.breakfast], hasLength(2));
      expect(timeline.byMeal[MealSlot.lunch], hasLength(1));
      expect(timeline.byMeal[MealSlot.dinner], isEmpty);
      expect(timeline.total.calories, 350);
      expect(timeline.total.proteinG, 30);
      expect(timeline.isEmpty, isFalse);
    });

    test('empty entries produce an empty timeline with all slots present', () {
      final timeline = DayTimeline.fromEntries([]);
      expect(timeline.isEmpty, isTrue);
      expect(timeline.byMeal.keys, containsAll(MealSlot.values));
      expect(timeline.total, Nutrition.zero);
    });
  });

  group('MealSlot.forHour (docs/05 §5.2)', () {
    test('preselects a sensible meal by time of day', () {
      expect(MealSlot.forHour(8), MealSlot.breakfast);
      expect(MealSlot.forHour(12), MealSlot.lunch);
      expect(MealSlot.forHour(19), MealSlot.dinner);
      expect(MealSlot.forHour(23), MealSlot.snack);
    });
  });
}
