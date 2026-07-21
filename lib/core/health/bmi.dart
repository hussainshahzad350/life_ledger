import 'package:life_ledger/core/error/failure.dart';
import 'package:life_ledger/core/error/result.dart';
import 'package:life_ledger/core/health/health_constants.dart';
import 'package:life_ledger/core/health/health_types.dart';

/// Body Mass Index: `kg / m²`, categorized per WHO adult cutoffs
/// (docs/06 Rule 7, knowledge/bmi.md).
///
/// The UI must always pair the result with the "screening tool, not a
/// diagnosis" caveat — BMI cannot distinguish muscle from fat.
Result<BmiResult> bodyMassIndex({
  required double weightKg,
  required double heightCm,
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

  final heightM = heightCm / 100;
  final value = weightKg / (heightM * heightM);

  final category = switch (value) {
    < HealthConstants.bmiUnderweightMax => BmiCategory.underweight,
    < HealthConstants.bmiNormalMax => BmiCategory.normal,
    < HealthConstants.bmiOverweightMax => BmiCategory.overweight,
    _ => BmiCategory.obese,
  };

  return Result.success(BmiResult(value: value, category: category));
}
