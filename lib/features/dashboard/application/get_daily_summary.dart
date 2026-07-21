import 'package:life_ledger/core/error/result.dart';
import 'package:life_ledger/core/health/health_constants.dart';
import 'package:life_ledger/core/health/health_score.dart';
import 'package:life_ledger/core/time/clock.dart';
import 'package:life_ledger/features/dashboard/domain/daily_summary.dart';
import 'package:life_ledger/features/food/domain/entities/food_item.dart';
import 'package:life_ledger/features/food/domain/repositories/food_repository.dart';
import 'package:life_ledger/features/goals/domain/entities/goal.dart';
import 'package:life_ledger/features/goals/domain/repositories/goal_repository.dart';
import 'package:life_ledger/features/water/domain/repositories/water_repository.dart';
import 'package:life_ledger/features/weight/domain/repositories/weight_repository.dart';

/// Assembles the dashboard [DailySummary] (docs/08 F10): reads today's food
/// totals, water, latest weight, and active goals, then computes the Health
/// Score via the pure engine (docs/06 Rule 8). Read-only; no writes.
class GetDailySummary {
  /// Creates the use case.
  GetDailySummary({
    required FoodRepository food,
    required WaterRepository water,
    required WeightRepository weight,
    required GoalRepository goals,
    required Clock clock,
  }) : _food = food,
       _water = water,
       _weight = weight,
       _goals = goals,
       _clock = clock;

  final FoodRepository _food;
  final WaterRepository _water;
  final WeightRepository _weight;
  final GoalRepository _goals;
  final Clock _clock;

  /// Builds the summary for [userId] on [localDate] (defaults to today). Any
  /// component failure surfaces as a [Result] failure.
  Future<Result<DailySummary>> call({
    required String userId,
    String? localDate,
  }) async {
    final date = localDate ?? _clock.localDate();

    final totalsResult = await _food.totalsForDate(userId, date);
    if (totalsResult.failureOrNull case final f?) return Result.failure(f);
    final nutrition = totalsResult.valueOrNull!;

    final waterResult = await _water.totalForDate(userId, date);
    if (waterResult.failureOrNull case final f?) return Result.failure(f);
    final waterMl = waterResult.valueOrNull!;

    final weightResult = await _weight.getRecent(userId);
    if (weightResult.failureOrNull case final f?) return Result.failure(f);
    final recentWeights = weightResult.valueOrNull!;

    final goalsResult = await _goals.getActiveGoals(userId);
    if (goalsResult.failureOrNull case final f?) return Result.failure(f);
    final goals = <GoalType, double>{
      for (final g in goalsResult.valueOrNull!) g.type: g.targetValue,
    };

    MetricProgress metric(GoalType type, double actual) =>
        MetricProgress(type: type, actual: actual, target: goals[type]);

    final calories = metric(GoalType.calories, nutrition.calories);
    final protein = metric(GoalType.protein, nutrition.proteinG);
    final water = metric(GoalType.water, waterMl);

    return Result.success(
      DailySummary(
        localDate: date,
        nutrition: nutrition,
        calories: calories,
        protein: protein,
        water: water,
        latestWeightKg: recentWeights.isNotEmpty
            ? recentWeights.first.weightKg
            : null,
        previousWeightKg: recentWeights.length > 1
            ? recentWeights[1].weightKg
            : null,
        healthScore: _score(nutrition, waterMl, goals),
        hasGoals: goals.isNotEmpty,
      ),
    );
  }

  /// Composes the Health Score from the day's data and active goals
  /// (docs/06 Rule 8). Only components with a goal contribute; the engine
  /// renormalizes the rest.
  double _score(
    Nutrition nutrition,
    double waterMl,
    Map<GoalType, double> goals,
  ) {
    final components = <ScoreComponent>[
      if (goals[GoalType.calories] case final target?)
        ScoreComponent(
          kind: ScoreComponentKind.band,
          actual: nutrition.calories,
          target: target,
          weight: HealthConstants.scoreWeightCalories,
        ),
      if (goals[GoalType.protein] case final target?)
        ScoreComponent(
          kind: ScoreComponentKind.reach,
          actual: nutrition.proteinG,
          target: target,
          weight: HealthConstants.scoreWeightProtein,
        ),
      if (goals[GoalType.water] case final target?)
        ScoreComponent(
          kind: ScoreComponentKind.reach,
          actual: waterMl,
          target: target,
          weight: HealthConstants.scoreWeightWater,
        ),
      if (goals[GoalType.fiber] case final target?)
        ScoreComponent(
          kind: ScoreComponentKind.reach,
          actual: nutrition.fiberG,
          target: target,
          weight: HealthConstants.scoreWeightFiber,
        ),
      if (goals[GoalType.sugar] case final target?)
        ScoreComponent(
          kind: ScoreComponentKind.limit,
          actual: nutrition.sugarG,
          target: target,
          weight: HealthConstants.scoreWeightSugar,
        ),
    ];
    return healthScore(components);
  }
}
