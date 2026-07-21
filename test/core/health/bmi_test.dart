import 'package:flutter_test/flutter_test.dart';
import 'package:life_ledger/core/error/failure.dart';
import 'package:life_ledger/core/health/bmi.dart';
import 'package:life_ledger/core/health/health_types.dart';

void main() {
  group('bodyMassIndex (docs/06 Rule 7)', () {
    test('worked example: 71 kg / 1.65 m ≈ 26.1 → overweight', () {
      final result = bodyMassIndex(weightKg: 71, heightCm: 165).valueOrNull!;
      expect(result.value, closeTo(26.08, 0.01));
      expect(result.category, BmiCategory.overweight);
    });

    test('WHO category boundaries (1 m height makes BMI == weight)', () {
      BmiCategory cat(double w) =>
          bodyMassIndex(weightKg: w, heightCm: 100).valueOrNull!.category;
      expect(cat(18.4), BmiCategory.underweight);
      expect(cat(18.5), BmiCategory.normal);
      expect(cat(24.9), BmiCategory.normal);
      expect(cat(25.0), BmiCategory.overweight);
      expect(cat(29.9), BmiCategory.overweight);
      expect(cat(30.0), BmiCategory.obese);
    });

    test('invalid inputs return ValidationFailure', () {
      expect(
        bodyMassIndex(weightKg: 0, heightCm: 170).failureOrNull,
        isA<ValidationFailure>(),
      );
      expect(
        bodyMassIndex(weightKg: 70, heightCm: 0).failureOrNull,
        isA<ValidationFailure>(),
      );
      expect(
        bodyMassIndex(weightKg: 70, heightCm: 300).failureOrNull,
        isA<ValidationFailure>(),
      );
    });
  });
}
