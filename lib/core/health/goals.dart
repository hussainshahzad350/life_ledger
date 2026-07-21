import 'dart:math' as math;

import 'package:life_ledger/core/error/failure.dart';
import 'package:life_ledger/core/error/result.dart';
import 'package:life_ledger/core/health/health_constants.dart';
import 'package:life_ledger/core/health/health_types.dart';

/// Daily calorie goal: `TDEE + adjustment(objective)`, floored at the safety
/// minimum (docs/06 Rule 3).
///
/// The result notes the clamp when the floor engages; the estimated
/// rate-of-change behind the defaults uses the caveated 7,700 kcal/kg
/// approximation and is never presented as a promise.
Estimate calorieGoal({
  required Estimate tdee,
  required WeightObjective objective,
  double deficitKcal = HealthConstants.deficitKcal,
  double surplusKcal = HealthConstants.surplusKcal,
}) {
  final adjusted = switch (objective) {
    WeightObjective.maintain => tdee.value,
    WeightObjective.lose => tdee.value - deficitKcal,
    WeightObjective.gain => tdee.value + surplusKcal,
  };

  final clamped = adjusted < HealthConstants.minCalorieFloor;
  final value = clamped ? HealthConstants.minCalorieFloor : adjusted;

  return Estimate(
    value,
    reducedConfidence: tdee.reducedConfidence,
    notes: [
      ...tdee.notes,
      if (clamped)
        'Calorie goal raised to the safety floor of '
            '${HealthConstants.minCalorieFloor.toStringAsFixed(0)} kcal/day — '
            'aggressive restriction is not supported.',
    ],
  );
}

/// The default protein factor (g/kg) for a profile (docs/06 Rule 4).
///
/// Product defaults inside the sourced 1.2–2.0 g/kg guidance band; a `gain`
/// objective raises the factor to at least the muscle-sparing minimum.
/// Always clamped to `[proteinRda, proteinHardCap]`.
double proteinFactorFor({
  required ActivityLevel activityLevel,
  required WeightObjective objective,
}) {
  var factor = switch (activityLevel) {
    ActivityLevel.sedentary => HealthConstants.proteinFactorSedentary,
    ActivityLevel.light => HealthConstants.proteinFactorLight,
    ActivityLevel.moderate => HealthConstants.proteinFactorModerate,
    ActivityLevel.active => HealthConstants.proteinFactorActive,
    ActivityLevel.veryActive => HealthConstants.proteinFactorVeryActive,
  };
  if (objective == WeightObjective.gain) {
    factor = math.max(factor, HealthConstants.proteinFactorGainMin);
  }
  return factor.clamp(
    HealthConstants.proteinRda,
    HealthConstants.proteinHardCap,
  );
}

/// Daily protein goal in grams: `weight × factor` (docs/06 Rule 4).
///
/// [overrideFactorGPerKg] supports the user-set override (FR-6); it is
/// clamped to the same safety band, with a note when clamping engages.
Result<Estimate> proteinGoal({
  required double weightKg,
  required ActivityLevel activityLevel,
  required WeightObjective objective,
  double? overrideFactorGPerKg,
}) {
  if (weightKg <= HealthConstants.minWeightKg ||
      weightKg >= HealthConstants.maxWeightKg) {
    return const Result.failure(
      ValidationFailure(field: 'weightKg', reason: 'must be in (0, 700) kg'),
    );
  }

  final requested =
      overrideFactorGPerKg ??
      proteinFactorFor(activityLevel: activityLevel, objective: objective);
  final factor = requested.clamp(
    HealthConstants.proteinRda,
    HealthConstants.proteinHardCap,
  );
  final clamped = factor != requested;

  return Result.success(
    Estimate(
      weightKg * factor,
      notes: [
        if (clamped)
          'Protein factor clamped to the supported band of '
              '${HealthConstants.proteinRda}–${HealthConstants.proteinHardCap} '
              'g/kg.',
      ],
    ),
  );
}

/// Splits post-protein energy into carb and fat gram targets and derives the
/// fiber target and added-sugar ceiling (docs/06 Rules 5/5b).
///
/// Fails with [ValidationFailure] if the protein goal alone exceeds the
/// calorie goal (goals are inconsistent and must be revisited, not silently
/// negative).
Result<MacroGoals> macroGoals({
  required double calorieGoalKcal,
  required double proteinGoalG,
  double carbShare = HealthConstants.carbShare,
  double fatShare = HealthConstants.fatShare,
}) {
  if (calorieGoalKcal <= 0) {
    return const Result.failure(
      ValidationFailure(field: 'calorieGoalKcal', reason: 'must be > 0'),
    );
  }
  if (proteinGoalG < 0) {
    return const Result.failure(
      ValidationFailure(field: 'proteinGoalG', reason: 'must be >= 0'),
    );
  }

  final proteinKcal = proteinGoalG * HealthConstants.kcalPerGramProtein;
  final remaining = calorieGoalKcal - proteinKcal;
  if (remaining < 0) {
    return const Result.failure(
      ValidationFailure(
        field: 'proteinGoalG',
        reason: 'protein energy exceeds the calorie goal — adjust goals',
      ),
    );
  }

  return Result.success(
    MacroGoals(
      proteinG: proteinGoalG,
      carbsG: remaining * carbShare / HealthConstants.kcalPerGramCarb,
      fatG: remaining * fatShare / HealthConstants.kcalPerGramFat,
      fiberG: calorieGoalKcal / 1000 * HealthConstants.fiberPer1000Kcal,
      sugarCeilingG:
          calorieGoalKcal *
          HealthConstants.addedSugarMaxPct /
          HealthConstants.kcalPerGramCarb,
    ),
  );
}

/// Daily beverage-water goal in ml: `weight × 33 ml/kg`, clamped to the
/// `[1500, 4000]` safety band (docs/06 Rule 6).
Result<Estimate> waterGoalMl({required double weightKg}) {
  if (weightKg <= HealthConstants.minWeightKg ||
      weightKg >= HealthConstants.maxWeightKg) {
    return const Result.failure(
      ValidationFailure(field: 'weightKg', reason: 'must be in (0, 700) kg'),
    );
  }

  final raw = weightKg * HealthConstants.waterMlPerKg;
  final value = raw.clamp(
    HealthConstants.minWaterMl,
    HealthConstants.maxWaterMl,
  );

  return Result.success(
    Estimate(
      value,
      notes: [
        if (value != raw)
          'Water goal clamped to the safety band of '
              '${HealthConstants.minWaterMl.toStringAsFixed(0)}–'
              '${HealthConstants.maxWaterMl.toStringAsFixed(0)} ml/day.',
      ],
    ),
  );
}
