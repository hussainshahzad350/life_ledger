import 'package:flutter_test/flutter_test.dart';
import 'package:life_ledger/features/dashboard/domain/daily_summary.dart';
import 'package:life_ledger/features/food/domain/entities/food_item.dart';
import 'package:life_ledger/features/goals/domain/entities/goal.dart';

void main() {
  group('MetricProgress (docs/08 F10)', () {
    test('with a goal: ratio clamps to [0,1] and remaining never negative', () {
      const half = MetricProgress(
        type: GoalType.protein,
        actual: 50,
        target: 100,
      );
      expect(half.ratio, closeTo(0.5, 0.0001));
      expect(half.remaining, closeTo(50, 0.0001));

      const over = MetricProgress(
        type: GoalType.protein,
        actual: 130,
        target: 100,
      );
      expect(over.ratio, 1);
      expect(over.remaining, 0);
    });

    test('without a goal: ratio and remaining are null', () {
      const none = MetricProgress(type: GoalType.protein, actual: 50);
      expect(none.target, isNull);
      expect(none.ratio, isNull);
      expect(none.remaining, isNull);
    });

    test('zero/negative target yields a null ratio (no division by zero)', () {
      const zero = MetricProgress(
        type: GoalType.protein,
        actual: 50,
        target: 0,
      );
      expect(zero.ratio, isNull);
    });
  });

  group('DailySummary.weightDeltaKg', () {
    DailySummary summary({double? latest, double? prev}) => DailySummary(
      localDate: '2026-07-21',
      nutrition: Nutrition.zero,
      calories: const MetricProgress(type: GoalType.calories, actual: 0),
      protein: const MetricProgress(type: GoalType.protein, actual: 0),
      water: const MetricProgress(type: GoalType.water, actual: 0),
      latestWeightKg: latest,
      previousWeightKg: prev,
      healthScore: 0,
      hasGoals: false,
    );

    test('delta is signed latest − previous, or null when either missing', () {
      expect(
        summary(latest: 71.5, prev: 72).weightDeltaKg,
        closeTo(-0.5, 1e-9),
      );
      expect(summary(latest: 72).weightDeltaKg, isNull);
      expect(summary(prev: 72).weightDeltaKg, isNull);
    });
  });
}
