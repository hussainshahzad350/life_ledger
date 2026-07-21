/// Every named constant of the health engine — the **single source of truth**
/// mirroring the table in docs/06-health-rules.md §11. No health formula in
/// the codebase may use a numeric literal; it must reference a constant here.
///
/// Sources are registered in `/research`; `[verify]`-tagged citations are
/// resolved before any figure ships in-app (docs/06 §11 note).
abstract final class HealthConstants {
  // Mifflin–St Jeor BMR coefficients (Mifflin & St Jeor, 1990 — docs/06 Rule 1).

  /// Weight coefficient (kcal per kg).
  static const double msjWeight = 10;

  /// Height coefficient (kcal per cm).
  static const double msjHeight = 6.25;

  /// Age coefficient (kcal per year, subtracted).
  static const double msjAge = 5;

  /// Additive constant for males.
  static const double msjConstMale = 5;

  /// Additive constant for females.
  static const double msjConstFemale = -161;

  /// Additive constant for `unspecified` sex: the average of the male and
  /// female constants — an explicit product assumption, flagged as a
  /// reduced-confidence estimate (docs/06 Rule 1 Assumptions).
  static const double msjConstUnspecified = (msjConstMale + msjConstFemale) / 2;

  // Physical Activity Level multipliers (Harris–Benedict bands — docs/06 Rule 2).

  /// Little or no exercise.
  static const double palSedentary = 1.2;

  /// Light exercise 1–3 days/week.
  static const double palLight = 1.375;

  /// Moderate exercise 3–5 days/week.
  static const double palModerate = 1.55;

  /// Hard exercise 6–7 days/week.
  static const double palActive = 1.725;

  /// Very hard exercise or a physical job.
  static const double palVeryActive = 1.9;

  // Calorie goal (docs/06 Rule 3).

  /// Wishnofsky approximation: ~7,700 kcal per kg of body fat (Evidence C —
  /// a documented simplification, never presented as a promise).
  static const double energyPerKg = 7700;

  /// Default daily deficit for a `lose` objective (≈0.45 kg/week).
  static const double deficitKcal = 500;

  /// Default daily surplus for a `gain` objective.
  static const double surplusKcal = 300;

  /// Product safety floor: computed calorie goals never go below this
  /// (docs/06 Rule 3 Assumptions/Safety).
  static const double minCalorieFloor = 1200;

  // Protein goal (g per kg body weight — docs/06 Rule 4).

  /// RDA baseline (IOM/NASEM DRI).
  static const double proteinRda = 0.8;

  /// Product default factor per activity level. Values sit inside the
  /// sourced 1.2–2.0 g/kg guidance band; the moderate value matches the
  /// docs/06 worked example (71 kg × 1.4 ≈ 99 g).
  static const double proteinFactorSedentary = 1.2;

  /// Light activity default factor.
  static const double proteinFactorLight = 1.3;

  /// Moderate activity default factor.
  static const double proteinFactorModerate = 1.4;

  /// Active default factor.
  static const double proteinFactorActive = 1.6;

  /// Very active default factor.
  static const double proteinFactorVeryActive = 2.0;

  /// Minimum factor applied when the objective is `gain` (muscle-sparing).
  static const double proteinFactorGainMin = 1.6;

  /// Hard cap on the goal factor (docs/06 Rule 4).
  static const double proteinHardCap = 2.2;

  // Atwater energy densities (kcal per gram — docs/06 Rule 5).

  /// Protein energy density.
  static const double kcalPerGramProtein = 4;

  /// Carbohydrate energy density.
  static const double kcalPerGramCarb = 4;

  /// Fat energy density.
  static const double kcalPerGramFat = 9;

  /// Alcohol energy density (tracked for completeness; not a v1 category).
  static const double kcalPerGramAlcohol = 7;

  /// Share of post-protein energy allocated to carbs (within AMDR).
  static const double carbShare = 0.60;

  /// Share of post-protein energy allocated to fat (within AMDR).
  static const double fatShare = 0.40;

  // Fiber & added sugar (docs/06 Rule 5b).

  /// Fiber adequate-intake target per 1,000 kcal (IOM).
  static const double fiberPer1000Kcal = 14;

  /// WHO free-sugar ceiling as a share of total energy (a limit, not a goal).
  static const double addedSugarMaxPct = 0.10;

  // Water goal (docs/06 Rule 6).

  /// Body-weight method: ml per kg (30–35 ml/kg guidance band).
  static const double waterMlPerKg = 33;

  /// Lower clamp of the water-goal safety band (ml).
  static const double minWaterMl = 1500;

  /// Upper clamp of the water-goal safety band (ml) — hyponatremia guard.
  static const double maxWaterMl = 4000;

  // BMI cutoffs (WHO adult classification — docs/06 Rule 7).

  /// Below this: underweight.
  static const double bmiUnderweightMax = 18.5;

  /// Below this (and ≥ [bmiUnderweightMax]): normal.
  static const double bmiNormalMax = 25.0;

  /// Below this (and ≥ [bmiNormalMax]): overweight; at/above: obese.
  static const double bmiOverweightMax = 30.0;

  // Health score defaults (goal-adherence indicator — docs/06 Rule 8).

  /// Calories-in-band component weight.
  static const double scoreWeightCalories = 0.25;

  /// Protein component weight.
  static const double scoreWeightProtein = 0.25;

  /// Water component weight.
  static const double scoreWeightWater = 0.20;

  /// Fiber component weight.
  static const double scoreWeightFiber = 0.10;

  /// Added-sugar (limit) component weight.
  static const double scoreWeightSugar = 0.10;

  /// Logging-completeness component weight.
  static const double scoreWeightLogged = 0.10;

  /// Half-width of the calorie adherence band (±10% of goal).
  static const double calorieBandPct = 0.10;

  // Input validation bounds (docs/06 §10; mirror the DB CHECKs, docs/04 §11).

  /// Exclusive lower bound for body weight (kg).
  static const double minWeightKg = 0;

  /// Exclusive upper bound for body weight (kg).
  static const double maxWeightKg = 700;

  /// Exclusive lower bound for height (cm).
  static const double minHeightCm = 0;

  /// Exclusive upper bound for height (cm).
  static const double maxHeightCm = 300;

  /// Below this age the equations carry reduced confidence (adult-validated).
  static const int minAdultAge = 18;

  /// Above this age the equations carry reduced confidence.
  static const int maxValidatedAge = 100;
}
