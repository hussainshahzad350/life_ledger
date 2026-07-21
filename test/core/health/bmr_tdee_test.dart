import 'package:flutter_test/flutter_test.dart';
import 'package:life_ledger/core/error/failure.dart';
import 'package:life_ledger/core/health/bmr_tdee.dart';
import 'package:life_ledger/core/health/health_types.dart';

void main() {
  group('basalMetabolicRate (docs/06 Rule 1)', () {
    test('worked example: female, 29y, 165cm, 71kg = 1435.25 kcal/day', () {
      final result = basalMetabolicRate(
        sex: Sex.female,
        weightKg: 71,
        heightCm: 165,
        ageYears: 29,
      );
      final estimate = result.valueOrNull!;
      expect(estimate.value, closeTo(1435.25, 0.001));
      expect(estimate.reducedConfidence, isFalse);
      expect(estimate.notes, isEmpty);
    });

    test('male constant is +5', () {
      final result = basalMetabolicRate(
        sex: Sex.male,
        weightKg: 80,
        heightCm: 180,
        ageYears: 40,
      );
      // 800 + 1125 − 200 + 5
      expect(result.valueOrNull!.value, closeTo(1730, 0.001));
    });

    test('unspecified sex averages constants and flags reduced confidence', () {
      final result = basalMetabolicRate(
        sex: Sex.unspecified,
        weightKg: 71,
        heightCm: 165,
        ageYears: 29,
      );
      final estimate = result.valueOrNull!;
      // 710 + 1031.25 − 145 − 78
      expect(estimate.value, closeTo(1518.25, 0.001));
      expect(estimate.reducedConfidence, isTrue);
      expect(estimate.notes.single, contains('averaged sex constants'));
    });

    test(
      'non-adult ages compute but flag reduced confidence (docs/06 §10)',
      () {
        for (final age in [17, 101]) {
          final estimate = basalMetabolicRate(
            sex: Sex.male,
            weightKg: 70,
            heightCm: 170,
            ageYears: age,
          ).valueOrNull!;
          expect(estimate.reducedConfidence, isTrue, reason: 'age $age');
          expect(estimate.notes.single, contains('validated for adults'));
        }
      },
    );

    test('out-of-domain inputs return ValidationFailure, never a guess', () {
      final cases = <({double w, double h, int a, String field})>[
        (w: 0, h: 170, a: 30, field: 'weightKg'),
        (w: 700, h: 170, a: 30, field: 'weightKg'),
        (w: 70, h: 0, a: 30, field: 'heightCm'),
        (w: 70, h: 300, a: 30, field: 'heightCm'),
        (w: 70, h: 170, a: -1, field: 'ageYears'),
        (w: 70, h: 170, a: 131, field: 'ageYears'),
      ];
      for (final c in cases) {
        final result = basalMetabolicRate(
          sex: Sex.female,
          weightKg: c.w,
          heightCm: c.h,
          ageYears: c.a,
        );
        final failure = result.failureOrNull;
        expect(failure, isA<ValidationFailure>(), reason: c.field);
        expect((failure! as ValidationFailure).field, c.field);
      }
    });
  });

  group('palMultiplier (docs/06 Rule 2)', () {
    test('maps every activity level to its documented PAL', () {
      expect(palMultiplier(ActivityLevel.sedentary), 1.2);
      expect(palMultiplier(ActivityLevel.light), 1.375);
      expect(palMultiplier(ActivityLevel.moderate), 1.55);
      expect(palMultiplier(ActivityLevel.active), 1.725);
      expect(palMultiplier(ActivityLevel.veryActive), 1.9);
    });
  });

  group('totalDailyEnergyExpenditure (docs/06 Rule 2)', () {
    test('worked example: 1435.25 × 1.55 ≈ 2225 kcal/day', () {
      final tdee = totalDailyEnergyExpenditure(
        bmr: const Estimate(1435.25),
        activityLevel: ActivityLevel.moderate,
      );
      expect(tdee.value, closeTo(2224.64, 0.01));
      expect(tdee.reducedConfidence, isFalse);
    });

    test('passes reduced-confidence metadata through unchanged', () {
      final tdee = totalDailyEnergyExpenditure(
        bmr: const Estimate(1500, reducedConfidence: true, notes: ['n']),
        activityLevel: ActivityLevel.sedentary,
      );
      expect(tdee.value, closeTo(1800, 0.001));
      expect(tdee.reducedConfidence, isTrue);
      expect(tdee.notes, ['n']);
    });
  });
}
