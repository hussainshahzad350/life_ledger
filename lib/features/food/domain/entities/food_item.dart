import 'package:equatable/equatable.dart';

/// Per-serving nutrition for a catalog food (docs/04 §4.3). All values are
/// per one [FoodItem.servingSize] of [FoodItem.servingUnit].
class Nutrition extends Equatable {
  /// Creates a nutrition record.
  const Nutrition({
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.fiberG,
    required this.sugarG,
  });

  /// Zero nutrition (a convenient neutral element for summing).
  static const Nutrition zero = Nutrition(
    calories: 0,
    proteinG: 0,
    carbsG: 0,
    fatG: 0,
    fiberG: 0,
    sugarG: 0,
  );

  /// Energy in kcal.
  final double calories;

  /// Protein in grams.
  final double proteinG;

  /// Carbohydrate in grams.
  final double carbsG;

  /// Fat in grams.
  final double fatG;

  /// Fiber in grams.
  final double fiberG;

  /// Sugar in grams.
  final double sugarG;

  /// Scales every value by [factor] (a logged quantity of servings).
  Nutrition scaled(double factor) => Nutrition(
    calories: calories * factor,
    proteinG: proteinG * factor,
    carbsG: carbsG * factor,
    fatG: fatG * factor,
    fiberG: fiberG * factor,
    sugarG: sugarG * factor,
  );

  /// Adds two nutrition records component-wise.
  Nutrition operator +(Nutrition other) => Nutrition(
    calories: calories + other.calories,
    proteinG: proteinG + other.proteinG,
    carbsG: carbsG + other.carbsG,
    fatG: fatG + other.fatG,
    fiberG: fiberG + other.fiberG,
    sugarG: sugarG + other.sugarG,
  );

  @override
  List<Object?> get props => [calories, proteinG, carbsG, fatG, fiberG, sugarG];
}

/// A catalog food — bundled starter set, seeded, or user-created
/// (docs/04 §4.3, docs/17).
class FoodItem extends Equatable {
  /// Creates a food item.
  const FoodItem({
    required this.id,
    required this.name,
    this.brand,
    this.isCustom = false,
    this.isFavorite = false,
    required this.servingSize,
    required this.servingUnit,
    required this.nutrition,
    this.sourceRef,
  });

  /// Row id (UUID).
  final String id;

  /// Food name (canonical English, docs/17 §2.6).
  final String name;

  /// Optional brand.
  final String? brand;

  /// Whether the user created this item.
  final bool isCustom;

  /// Whether the user favorited it (docs/08 F3).
  final bool isFavorite;

  /// One serving's size, in [servingUnit].
  final double servingSize;

  /// The serving unit (`g`, `ml`, `piece`, …, docs/17 §2.4).
  final String servingUnit;

  /// Per-serving nutrition.
  final Nutrition nutrition;

  /// Provenance of the nutrition data (null for user-created).
  final String? sourceRef;

  @override
  List<Object?> get props => [
    id,
    name,
    brand,
    isCustom,
    isFavorite,
    servingSize,
    servingUnit,
    nutrition,
    sourceRef,
  ];
}
