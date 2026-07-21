import 'package:flutter_test/flutter_test.dart';
import 'package:life_ledger/core/error/failure.dart';
import 'package:life_ledger/core/health/goals.dart';
import 'package:life_ledger/core/health/health_types.dart';

void main() {
  group('calorieGoal (docs/06 Rule 3)', () {
    const tdee = Estimate(2225);

    test('maintain = TDEE, lose = −500, gain = +300', () {
      expect(
        calorieGoal(tdee: tdee, objective: WeightObjective.maintain).value,
        2225,
      );
      expect(
        calorieGoal(tdee: tdee, objective: WeightObjective.lose).value,
        1725,
      );
      expect(
        calorieGoal(tdee: tdee, objective: WeightObjective.gain).value,
        2525,
      );
    });

    test('custom deficit/surplus are honored', () {
      expect(
        calorieGoal(
          tdee: tdee,
          objective: WeightObjective.lose,
          deficitKcal: 300,
        ).value,
        1925,
      );
      expect(
        calorieGoal(
          tdee: tdee,
          objective: WeightObjective.gain,
          surplusKcal: 500,
        ).value,
        2725,
      );
    });

    test('clamps to the 1200 kcal safety floor with a warning note', () {
      final goal = calorieGoal(
        tdee: const Estimate(1500),
        objective: WeightObjective.lose,
      );
      expect(goal.value, 1200);
      expect(goal.notes.single, contains('safety floor'));
    });

    test('passes reduced-confidence metadata through', () {
      final goal = calorieGoal(
        tdee: const Estimate(2000, reducedConfidence: true, notes: ['n']),
        objective: WeightObjective.maintain,
      );
      expect(goal.reducedConfidence, isTrue);
      expect(goal.notes, contains('n'));
    });
  });

  group('proteinFactorFor (docs/06 Rule 4)', () {
    test('documented default per activity level', () {
      double f(ActivityLevel l) => proteinFactorFor(
        activityLevel: l,
        objective: WeightObjective.maintain,
      );
      expect(f(ActivityLevel.sedentary), 1.2);
      expect(f(ActivityLevel.light), 1.3);
      expect(f(ActivityLevel.moderate), 1.4);
      expect(f(ActivityLevel.active), 1.6);
      expect(f(ActivityLevel.veryActive), 2.0);
    });

    test('gain objective raises the factor to the muscle-sparing minimum', () {
      expect(
        proteinFactorFor(
          activityLevel: ActivityLevel.sedentary,
          objective: WeightObjective.gain,
        ),
        1.6,
      );
      // Already above the gain minimum: unchanged.
      expect(
        proteinFactorFor(
          activityLevel: ActivityLevel.veryActive,
          objective: WeightObjective.gain,
        ),
        2.0,
      );
    });
  });

  group('proteinGoal (docs/06 Rule 4)', () {
    test('worked example: 71 kg × 1.4 ≈ 99 g/day', () {
      final result = proteinGoal(
        weightKg: 71,
        activityLevel: ActivityLevel.moderate,
        objective: WeightObjective.maintain,
      );
      expect(result.valueOrNull!.value, closeTo(99.4, 0.001));
      expect(result.valueOrNull!.notes, isEmpty);
    });

    test('user override is honored inside the band', () {
      final result = proteinGoal(
        weightKg: 70,
        activityLevel: ActivityLevel.sedentary,
        objective: WeightObjective.maintain,
        overrideFactorGPerKg: 1.8,
      );
      expect(result.valueOrNull!.value, closeTo(126, 0.001));
    });

    test('override is clamped to [0.8, 2.2] g/kg with a note', () {
      final high = proteinGoal(
        weightKg: 70,
        activityLevel: ActivityLevel.moderate,
        objective: WeightObjective.maintain,
        overrideFactorGPerKg: 3.0,
      ).valueOrNull!;
      expect(high.value, closeTo(70 * 2.2, 0.001));
      expect(high.notes.single, contains('clamped'));

      final low = proteinGoal(
        weightKg: 70,
        activityLevel: ActivityLevel.moderate,
        objective: WeightObjective.maintain,
        overrideFactorGPerKg: 0.5,
      ).valueOrNull!;
      expect(low.value, closeTo(70 * 0.8, 0.001));
    });

    test('missing/invalid weight is a ValidationFailure (docs/06 §10)', () {
      final result = proteinGoal(
        weightKg: 0,
        activityLevel: ActivityLevel.moderate,
        objective: WeightObjective.maintain,
      );
      expect(result.failureOrNull, isA<ValidationFailure>());
    });
  });

  group('macroGoals (docs/06 Rules 5/5b)', () {
    test('splits the post-protein remainder 60/40 with Atwater densities', () {
      final result = macroGoals(
        calorieGoalKcal: 2050,
        proteinGoalG: 110,
      ).valueOrNull!;
      // proteinKcal 440 → remaining 1610.
      expect(result.proteinG, 110);
      expect(result.carbsG, closeTo(1610 * 0.60 / 4, 0.001)); // 241.5 g
      expect(result.fatG, closeTo(1610 * 0.40 / 9, 0.001)); // 71.56 g
      expect(result.fiberG, closeTo(2050 / 1000 * 14, 0.001)); // 28.7 g
      expect(result.sugarCeilingG, closeTo(2050 * 0.10 / 4, 0.001)); // 51.25 g
    });

    test('energy identity: protein+carb+fat kcal equals the calorie goal', () {
      final m = macroGoals(
        calorieGoalKcal: 2000,
        proteinGoalG: 100,
      ).valueOrNull!;
      final total = m.proteinG * 4 + m.carbsG * 4 + m.fatG * 9;
      expect(total, closeTo(2000, 0.001));
    });

    test('rejects inconsistent inputs with ValidationFailure', () {
      expect(
        macroGoals(calorieGoalKcal: 0, proteinGoalG: 50).failureOrNull,
        isA<ValidationFailure>(),
      );
      expect(
        macroGoals(calorieGoalKcal: 2000, proteinGoalG: -1).failureOrNull,
        isA<ValidationFailure>(),
      );
      // Protein energy exceeding the calorie goal is inconsistent, not
      // silently negative.
      expect(
        macroGoals(calorieGoalKcal: 300, proteinGoalG: 100).failureOrNull,
        isA<ValidationFailure>(),
      );
    });
  });

  group('waterGoalMl (docs/06 Rule 6)', () {
    test('worked example: 71 kg × 33 ≈ 2343 ml', () {
      final result = waterGoalMl(weightKg: 71).valueOrNull!;
      expect(result.value, closeTo(2343, 0.001));
      expect(result.notes, isEmpty);
    });

    test('clamps to the [1500, 4000] ml safety band with a note', () {
      final low = waterGoalMl(weightKg: 40).valueOrNull!; // raw 1320
      expect(low.value, 1500);
      expect(low.notes.single, contains('safety band'));

      final high = waterGoalMl(weightKg: 130).valueOrNull!; // raw 4290
      expect(high.value, 4000);
      expect(high.notes.single, contains('safety band'));
    });

    test('invalid weight is a ValidationFailure', () {
      expect(waterGoalMl(weightKg: 0).failureOrNull, isA<ValidationFailure>());
      expect(
        waterGoalMl(weightKg: 700).failureOrNull,
        isA<ValidationFailure>(),
      );
    });
  });
}
