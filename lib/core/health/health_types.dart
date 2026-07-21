import 'package:equatable/equatable.dart';

/// Biological sex as used by the BMR equation (docs/06 Rule 1).
/// `unspecified` computes with averaged constants at reduced confidence.
enum Sex {
  /// Male constants in Mifflin–St Jeor.
  male,

  /// Female constants in Mifflin–St Jeor.
  female,

  /// Averaged constants; result flagged reduced-confidence.
  unspecified,
}

/// Self-reported activity level mapping to a PAL multiplier (docs/06 Rule 2).
enum ActivityLevel {
  /// Little or no exercise (PAL 1.2).
  sedentary,

  /// Light exercise 1–3 days/week (PAL 1.375).
  light,

  /// Moderate exercise 3–5 days/week (PAL 1.55).
  moderate,

  /// Hard exercise 6–7 days/week (PAL 1.725).
  active,

  /// Very hard exercise / physical job (PAL 1.9).
  veryActive,
}

/// The user's weight objective, adjusting the calorie goal (docs/06 Rule 3).
enum WeightObjective {
  /// Keep current weight (no adjustment).
  maintain,

  /// Gradual loss (default −500 kcal/day, floored).
  lose,

  /// Gradual gain (default +300 kcal/day).
  gain,
}

/// A computed health value plus honesty metadata.
///
/// The engine never hides uncertainty: results derived from assumptions
/// (unspecified sex, non-adult age) set [reducedConfidence] and explain why
/// in [notes] (docs/06 Rules 1/7, docs/07 §1 uncertainty mandate).
class Estimate extends Equatable {
  /// Creates an estimate.
  const Estimate(
    this.value, {
    this.reducedConfidence = false,
    this.notes = const [],
  });

  /// The computed value.
  final double value;

  /// True when the inputs force an assumption-based or out-of-validation
  /// computation.
  final bool reducedConfidence;

  /// Plain-language reasons for reduced confidence or applied clamps.
  final List<String> notes;

  @override
  List<Object?> get props => [value, reducedConfidence, notes];
}

/// WHO adult BMI category (docs/06 Rule 7).
enum BmiCategory {
  /// BMI < 18.5.
  underweight,

  /// 18.5 ≤ BMI < 25.
  normal,

  /// 25 ≤ BMI < 30.
  overweight,

  /// BMI ≥ 30.
  obese,
}

/// BMI value + category, always paired with the screening-tool caveat in UI.
class BmiResult extends Equatable {
  /// Creates a BMI result.
  const BmiResult({required this.value, required this.category});

  /// The BMI value (kg/m²).
  final double value;

  /// The WHO category for [value].
  final BmiCategory category;

  @override
  List<Object?> get props => [value, category];
}

/// Daily macronutrient gram targets derived from the calorie and protein
/// goals (docs/06 Rule 5).
class MacroGoals extends Equatable {
  /// Creates macro goals.
  const MacroGoals({
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.fiberG,
    required this.sugarCeilingG,
  });

  /// Protein target in grams (set first — docs/06 Rule 4).
  final double proteinG;

  /// Carbohydrate target in grams (share of post-protein energy).
  final double carbsG;

  /// Fat target in grams (share of post-protein energy).
  final double fatG;

  /// Fiber minimum target in grams (docs/06 Rule 5b).
  final double fiberG;

  /// Added-sugar **ceiling** in grams — a limit, never a goal to hit.
  final double sugarCeilingG;

  @override
  List<Object?> get props => [proteinG, carbsG, fatG, fiberG, sugarCeilingG];
}
