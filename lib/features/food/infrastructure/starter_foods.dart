import 'package:life_ledger/features/food/domain/entities/food_item.dart';

/// A small, clearly-marked **starter** food catalog bundled so the app is
/// useful offline on first launch (docs/17 §5, [why-offline-first]).
///
/// Values are approximate, generic per-serving figures for common foods,
/// tagged `sourceRef: 'starter-set'`. They are a bootstrap only — the full
/// licensed catalog (USDA + localized data) replaces/extends this later
/// (docs/17 §5, research/usda.md, research/pakistan-nutrition-data.md).
/// Ids are stable (`sf-*`) so the seed is idempotent across launches.
abstract final class StarterFoods {
  /// Provenance tag stamped on every starter row.
  static const String sourceTag = 'starter-set';

  /// The bundled starter catalog.
  static const List<FoodItem> all = [
    FoodItem(
      id: 'sf-egg',
      name: 'Egg',
      servingSize: 1,
      servingUnit: 'piece',
      sourceRef: sourceTag,
      nutrition: Nutrition(
        calories: 72,
        proteinG: 6.3,
        carbsG: 0.4,
        fatG: 4.8,
        fiberG: 0,
        sugarG: 0.2,
      ),
    ),
    FoodItem(
      id: 'sf-oatmeal',
      name: 'Oatmeal',
      servingSize: 1,
      servingUnit: 'cup',
      sourceRef: sourceTag,
      nutrition: Nutrition(
        calories: 158,
        proteinG: 6,
        carbsG: 27,
        fatG: 3.2,
        fiberG: 4,
        sugarG: 1,
      ),
    ),
    FoodItem(
      id: 'sf-banana',
      name: 'Banana',
      servingSize: 1,
      servingUnit: 'piece',
      sourceRef: sourceTag,
      nutrition: Nutrition(
        calories: 105,
        proteinG: 1.3,
        carbsG: 27,
        fatG: 0.4,
        fiberG: 3.1,
        sugarG: 14,
      ),
    ),
    FoodItem(
      id: 'sf-greek-yogurt',
      name: 'Greek yogurt',
      servingSize: 170,
      servingUnit: 'g',
      sourceRef: sourceTag,
      nutrition: Nutrition(
        calories: 100,
        proteinG: 17,
        carbsG: 6,
        fatG: 0.7,
        fiberG: 0,
        sugarG: 4,
      ),
    ),
    FoodItem(
      id: 'sf-chicken-breast',
      name: 'Chicken breast',
      servingSize: 100,
      servingUnit: 'g',
      sourceRef: sourceTag,
      nutrition: Nutrition(
        calories: 165,
        proteinG: 31,
        carbsG: 0,
        fatG: 3.6,
        fiberG: 0,
        sugarG: 0,
      ),
    ),
    FoodItem(
      id: 'sf-white-rice',
      name: 'White rice (cooked)',
      servingSize: 1,
      servingUnit: 'cup',
      sourceRef: sourceTag,
      nutrition: Nutrition(
        calories: 205,
        proteinG: 4.3,
        carbsG: 45,
        fatG: 0.4,
        fiberG: 0.6,
        sugarG: 0.1,
      ),
    ),
    FoodItem(
      id: 'sf-roti',
      name: 'Roti',
      servingSize: 1,
      servingUnit: 'piece',
      sourceRef: sourceTag,
      nutrition: Nutrition(
        calories: 120,
        proteinG: 3,
        carbsG: 18,
        fatG: 3.7,
        fiberG: 2,
        sugarG: 0.5,
      ),
    ),
    FoodItem(
      id: 'sf-daal',
      name: 'Daal (lentils, cooked)',
      servingSize: 1,
      servingUnit: 'cup',
      sourceRef: sourceTag,
      nutrition: Nutrition(
        calories: 230,
        proteinG: 18,
        carbsG: 40,
        fatG: 0.8,
        fiberG: 15.6,
        sugarG: 3.6,
      ),
    ),
    FoodItem(
      id: 'sf-apple',
      name: 'Apple',
      servingSize: 1,
      servingUnit: 'piece',
      sourceRef: sourceTag,
      nutrition: Nutrition(
        calories: 95,
        proteinG: 0.5,
        carbsG: 25,
        fatG: 0.3,
        fiberG: 4.4,
        sugarG: 19,
      ),
    ),
    FoodItem(
      id: 'sf-milk',
      name: 'Milk (whole)',
      servingSize: 240,
      servingUnit: 'ml',
      sourceRef: sourceTag,
      nutrition: Nutrition(
        calories: 149,
        proteinG: 7.7,
        carbsG: 12,
        fatG: 8,
        fiberG: 0,
        sugarG: 12,
      ),
    ),
    FoodItem(
      id: 'sf-bread',
      name: 'Whole wheat bread',
      servingSize: 1,
      servingUnit: 'slice',
      sourceRef: sourceTag,
      nutrition: Nutrition(
        calories: 80,
        proteinG: 4,
        carbsG: 14,
        fatG: 1.1,
        fiberG: 2,
        sugarG: 1.5,
      ),
    ),
    FoodItem(
      id: 'sf-almonds',
      name: 'Almonds',
      servingSize: 28,
      servingUnit: 'g',
      sourceRef: sourceTag,
      nutrition: Nutrition(
        calories: 164,
        proteinG: 6,
        carbsG: 6,
        fatG: 14,
        fiberG: 3.5,
        sugarG: 1.2,
      ),
    ),
  ];
}
