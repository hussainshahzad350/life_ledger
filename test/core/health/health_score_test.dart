import 'package:flutter_test/flutter_test.dart';
import 'package:life_ledger/core/health/health_constants.dart';
import 'package:life_ledger/core/health/health_score.dart';

void main() {
  group('componentAdherence (docs/06 Rule 8)', () {
    test('reach: proportional, capped at 1.0 (no over-shoot inflation)', () {
      const half = ScoreComponent(
        kind: ScoreComponentKind.reach,
        actual: 55,
        target: 110,
        weight: 1,
      );
      expect(componentAdherence(half), closeTo(0.5, 0.0001));

      const over = ScoreComponent(
        kind: ScoreComponentKind.reach,
        actual: 200,
        target: 110,
        weight: 1,
      );
      expect(componentAdherence(over), 1);
    });

    test('limit: full credit under the ceiling, decreasing with overshoot', () {
      const under = ScoreComponent(
        kind: ScoreComponentKind.limit,
        actual: 30,
        target: 50,
        weight: 1,
      );
      expect(componentAdherence(under), 1);

      const overBy50pct = ScoreComponent(
        kind: ScoreComponentKind.limit,
        actual: 75,
        target: 50,
        weight: 1,
      );
      expect(componentAdherence(overBy50pct), closeTo(0.5, 0.0001));

      const wayOver = ScoreComponent(
        kind: ScoreComponentKind.limit,
        actual: 200,
        target: 50,
        weight: 1,
      );
      expect(componentAdherence(wayOver), 0);
    });

    test('band: full credit within ±10%, linear falloff beyond', () {
      const inside = ScoreComponent(
        kind: ScoreComponentKind.band,
        actual: 2100,
        target: 2050,
        weight: 1,
      );
      expect(componentAdherence(inside), 1);

      // 30% deviation → 1 − (0.30 − 0.10) = 0.8.
      const outside = ScoreComponent(
        kind: ScoreComponentKind.band,
        actual: 2050 * 1.30,
        target: 2050,
        weight: 1,
      );
      expect(componentAdherence(outside), closeTo(0.8, 0.0001));

      // Symmetric on the under side.
      const underEating = ScoreComponent(
        kind: ScoreComponentKind.band,
        actual: 2050 * 0.70,
        target: 2050,
        weight: 1,
      );
      expect(componentAdherence(underEating), closeTo(0.8, 0.0001));
    });
  });

  group('healthScore (docs/06 Rule 8)', () {
    test('perfect adherence over default weights = 100', () {
      final score = healthScore(const [
        ScoreComponent(
          kind: ScoreComponentKind.band,
          actual: 2050,
          target: 2050,
          weight: HealthConstants.scoreWeightCalories,
        ),
        ScoreComponent(
          kind: ScoreComponentKind.reach,
          actual: 110,
          target: 110,
          weight: HealthConstants.scoreWeightProtein,
        ),
        ScoreComponent(
          kind: ScoreComponentKind.reach,
          actual: 2343,
          target: 2343,
          weight: HealthConstants.scoreWeightWater,
        ),
        ScoreComponent(
          kind: ScoreComponentKind.reach,
          actual: 29,
          target: 29,
          weight: HealthConstants.scoreWeightFiber,
        ),
        ScoreComponent(
          kind: ScoreComponentKind.limit,
          actual: 20,
          target: 51,
          weight: HealthConstants.scoreWeightSugar,
        ),
        ScoreComponent(
          kind: ScoreComponentKind.reach,
          actual: 1,
          target: 1,
          weight: HealthConstants.scoreWeightLogged,
        ),
      ]);
      expect(score, closeTo(100, 0.0001));
    });

    test('weighted mixed day matches the documented formula', () {
      // protein 50% at weight .25 + water 100% at weight .20 →
      // (0.25×0.5 + 0.20×1.0) / 0.45 = 0.7222… → 72.22.
      final score = healthScore(const [
        ScoreComponent(
          kind: ScoreComponentKind.reach,
          actual: 55,
          target: 110,
          weight: 0.25,
        ),
        ScoreComponent(
          kind: ScoreComponentKind.reach,
          actual: 2400,
          target: 2400,
          weight: 0.20,
        ),
      ]);
      expect(score, closeTo(72.2222, 0.001));
    });

    test('zero-target components are skipped and weights renormalize '
        '(docs/06 §10)', () {
      final score = healthScore(const [
        ScoreComponent(
          kind: ScoreComponentKind.reach,
          actual: 100,
          target: 100,
          weight: 0.25,
        ),
        // No goal set — must not poison the score with a division by zero.
        ScoreComponent(
          kind: ScoreComponentKind.reach,
          actual: 10,
          target: 0,
          weight: 0.25,
        ),
      ]);
      expect(score, closeTo(100, 0.0001));
    });

    test('zero-weight components are skipped', () {
      final score = healthScore(const [
        ScoreComponent(
          kind: ScoreComponentKind.reach,
          actual: 0,
          target: 100,
          weight: 0,
        ),
        ScoreComponent(
          kind: ScoreComponentKind.reach,
          actual: 100,
          target: 100,
          weight: 0.5,
        ),
      ]);
      expect(score, closeTo(100, 0.0001));
    });

    test(
      'no effective components yields 0 (empty state, not a fake score)',
      () {
        expect(healthScore(const []), 0);
        expect(
          healthScore(const [
            ScoreComponent(
              kind: ScoreComponentKind.reach,
              actual: 5,
              target: 0,
              weight: 1,
            ),
          ]),
          0,
        );
      },
    );
  });
}
