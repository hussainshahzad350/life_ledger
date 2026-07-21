import 'package:life_ledger/core/error/failure.dart';
import 'package:life_ledger/core/error/result.dart';
import 'package:life_ledger/core/health/health_constants.dart';
import 'package:life_ledger/core/health/health_types.dart';

/// Basal Metabolic Rate via **Mifflin–St Jeor** (docs/06 Rule 1).
///
/// `BMR = 10·kg + 6.25·cm − 5·age + C(sex)` where `C` is +5 (male),
/// −161 (female), or their average (unspecified — reduced confidence).
/// Returns a [ValidationFailure] for out-of-domain inputs rather than
/// guessing (docs/06 §10).
Result<Estimate> basalMetabolicRate({
  required Sex sex,
  required double weightKg,
  required double heightCm,
  required int ageYears,
}) {
  if (weightKg <= HealthConstants.minWeightKg ||
      weightKg >= HealthConstants.maxWeightKg) {
    return const Result.failure(
      ValidationFailure(field: 'weightKg', reason: 'must be in (0, 700) kg'),
    );
  }
  if (heightCm <= HealthConstants.minHeightCm ||
      heightCm >= HealthConstants.maxHeightCm) {
    return const Result.failure(
      ValidationFailure(field: 'heightCm', reason: 'must be in (0, 300) cm'),
    );
  }
  if (ageYears < 0 || ageYears > 130) {
    return const Result.failure(
      ValidationFailure(field: 'ageYears', reason: 'must be in [0, 130]'),
    );
  }

  final sexConstant = switch (sex) {
    Sex.male => HealthConstants.msjConstMale,
    Sex.female => HealthConstants.msjConstFemale,
    Sex.unspecified => HealthConstants.msjConstUnspecified,
  };

  final value =
      HealthConstants.msjWeight * weightKg +
      HealthConstants.msjHeight * heightCm -
      HealthConstants.msjAge * ageYears +
      sexConstant;

  final notes = <String>[
    if (sex == Sex.unspecified)
      'Computed with averaged sex constants — specify sex for a more '
          'accurate estimate.',
    if (ageYears < HealthConstants.minAdultAge ||
        ageYears > HealthConstants.maxValidatedAge)
      'The equation is validated for adults aged '
          '${HealthConstants.minAdultAge}–${HealthConstants.maxValidatedAge}.',
  ];

  return Result.success(
    Estimate(value, reducedConfidence: notes.isNotEmpty, notes: notes),
  );
}

/// The PAL multiplier for an [ActivityLevel] (docs/06 Rule 2).
double palMultiplier(ActivityLevel level) => switch (level) {
  ActivityLevel.sedentary => HealthConstants.palSedentary,
  ActivityLevel.light => HealthConstants.palLight,
  ActivityLevel.moderate => HealthConstants.palModerate,
  ActivityLevel.active => HealthConstants.palActive,
  ActivityLevel.veryActive => HealthConstants.palVeryActive,
};

/// Total Daily Energy Expenditure: `TDEE = BMR × PAL` (docs/06 Rule 2).
///
/// Carries the BMR estimate's confidence metadata through unchanged; logged
/// exercise is deliberately **not** added on top (double-counting guard,
/// docs/06 Rule 2 Assumptions).
Estimate totalDailyEnergyExpenditure({
  required Estimate bmr,
  required ActivityLevel activityLevel,
}) {
  return Estimate(
    bmr.value * palMultiplier(activityLevel),
    reducedConfidence: bmr.reducedConfidence,
    notes: bmr.notes,
  );
}
