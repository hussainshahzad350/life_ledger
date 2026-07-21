import 'package:flutter_test/flutter_test.dart';
import 'package:life_ledger/core/database/app_database.dart';
import 'package:life_ledger/core/time/clock.dart';
import 'package:life_ledger/features/dashboard/application/get_daily_summary.dart';
import 'package:life_ledger/features/food/domain/entities/food_entry.dart';
import 'package:life_ledger/features/food/infrastructure/food_seeder.dart';
import 'package:life_ledger/features/food/infrastructure/repositories/food_repository_impl.dart';
import 'package:life_ledger/features/goals/domain/entities/goal.dart';
import 'package:life_ledger/features/goals/infrastructure/repositories/goal_repository_impl.dart';
import 'package:life_ledger/features/water/infrastructure/repositories/water_repository_impl.dart';
import 'package:life_ledger/features/weight/infrastructure/repositories/weight_repository_impl.dart';

import '../../support/fakes.dart';

/// End-to-end read-model test over real SQLite (docs/08 F10): log food + water
/// + weight + goals, then assert the assembled summary and Health Score.
void main() {
  late AppDatabase db;
  late GetDailySummary useCase;
  late FoodRepositoryImpl food;
  late WaterRepositoryImpl water;
  late WeightRepositoryImpl weight;
  late GoalRepositoryImpl goals;
  const userId = 'u1';
  final clock = FixedClock(DateTime(2026, 7, 21, 8));

  setUp(() async {
    db = await openTestDatabase();
    final ids = SequentialIds();
    await seedUser(db, userId);
    await FoodSeeder(db).seed();
    food = FoodRepositoryImpl(db: db, clock: clock, ids: ids);
    water = WaterRepositoryImpl(db: db, clock: clock, ids: ids);
    weight = WeightRepositoryImpl(db: db, clock: clock, ids: ids);
    goals = GoalRepositoryImpl(db: db, clock: clock, ids: ids);
    useCase = GetDailySummary(
      food: food,
      water: water,
      weight: weight,
      goals: goals,
      clock: clock,
    );
  });

  tearDown(() => db.close());

  group('GetDailySummary (docs/08 F10)', () {
    test('with no data and no goals: zeros, no goals, score 0', () async {
      final summary = (await useCase(userId: userId)).valueOrNull!;
      expect(summary.nutrition.calories, 0);
      expect(summary.calories.target, isNull);
      expect(summary.hasGoals, isFalse);
      expect(summary.healthScore, 0);
      expect(summary.latestWeightKg, isNull);
    });

    test(
      'aggregates food/water/weight and computes progress + score',
      () async {
        // Goals.
        await goals.setGoal(
          userId: userId,
          type: GoalType.calories,
          targetValue: 2000,
          source: GoalSource.system,
        );
        await goals.setGoal(
          userId: userId,
          type: GoalType.protein,
          targetValue: 100,
          source: GoalSource.system,
        );
        await goals.setGoal(
          userId: userId,
          type: GoalType.water,
          targetValue: 2000,
          source: GoalSource.system,
        );

        // Log: 2 eggs (144 kcal, 12.6 g protein) + water + two weigh-ins.
        await food.logEntry(
          userId: userId,
          foodItemId: 'sf-egg',
          quantity: 2,
          mealSlot: MealSlot.breakfast,
        );
        await water.addWater(userId: userId, amountMl: 500);
        await weight.addEntry(userId: userId, weightKg: 72);
        await weight.addEntry(userId: userId, weightKg: 71.5);

        final summary = (await useCase(userId: userId)).valueOrNull!;

        expect(summary.nutrition.calories, closeTo(144, 0.01));
        expect(summary.protein.actual, closeTo(12.6, 0.01));
        expect(summary.protein.target, 100);
        expect(summary.protein.remaining, closeTo(87.4, 0.01));
        expect(summary.protein.ratio, closeTo(0.126, 0.001));
        expect(summary.water.actual, 500);

        // Latest weight is the most recent; delta vs the previous reading.
        expect(summary.latestWeightKg, 71.5);
        expect(summary.previousWeightKg, 72);
        expect(summary.weightDeltaKg, closeTo(-0.5, 0.001));

        expect(summary.hasGoals, isTrue);
        // Score is a positive goal-adherence number, not a medical verdict.
        expect(summary.healthScore, greaterThan(0));
        expect(summary.healthScore, lessThanOrEqualTo(100));
      },
    );

    test('calories band metric hits full adherence within ±10%', () async {
      await goals.setGoal(
        userId: userId,
        type: GoalType.calories,
        targetValue: 144,
        source: GoalSource.system,
      );
      await food.logEntry(
        userId: userId,
        foodItemId: 'sf-egg',
        quantity: 2,
        mealSlot: MealSlot.breakfast,
      );
      final summary = (await useCase(userId: userId)).valueOrNull!;
      // Only the calories goal exists and it's exactly met → score 100.
      expect(summary.healthScore, closeTo(100, 0.001));
    });
  });
}
