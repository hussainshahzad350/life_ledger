import 'package:equatable/equatable.dart';
import 'package:life_ledger/features/food/domain/entities/food_item.dart';
import 'package:life_ledger/features/goals/domain/entities/goal.dart';

/// One metric on the dashboard: today's value against its goal (docs/08 F10).
class MetricProgress extends Equatable {
  /// Creates a metric. [target] is null when no goal is set for [type].
  const MetricProgress({required this.type, required this.actual, this.target});

  /// Which goal this tracks (null target when no goal is set).
  final GoalType type;

  /// Today's logged value (kcal, g, or ml per [type]).
  final double actual;

  /// The active goal target, or null when none is set.
  final double? target;

  /// Remaining to the target (never negative), or null without a goal.
  double? get remaining {
    final t = target;
    if (t == null) return null;
    final left = t - actual;
    return left < 0 ? 0 : left;
  }

  /// Progress ratio 0..1 (clamped), or null without a goal.
  double? get ratio {
    final t = target;
    if (t == null || t <= 0) return null;
    final r = actual / t;
    return r < 0 ? 0 : (r > 1 ? 1 : r);
  }

  @override
  List<Object?> get props => [type, actual, target];
}

/// The dashboard read-model — everything the at-a-glance view needs to answer
/// the five questions (docs/01 §6, docs/08 F10). Assembled by
/// `GetDailySummary` from logs + goals + the health engine.
class DailySummary extends Equatable {
  /// Creates a summary.
  const DailySummary({
    required this.localDate,
    required this.nutrition,
    required this.calories,
    required this.protein,
    required this.water,
    required this.latestWeightKg,
    required this.previousWeightKg,
    required this.healthScore,
    required this.hasGoals,
  });

  /// The local date this summarizes (`YYYY-MM-DD`).
  final String localDate;

  /// Today's total nutrition (derived from food logs).
  final Nutrition nutrition;

  /// Calories progress (band metric on the dashboard).
  final MetricProgress calories;

  /// Protein progress.
  final MetricProgress protein;

  /// Water progress.
  final MetricProgress water;

  /// Most recent weight reading (kg), or null if none.
  final double? latestWeightKg;

  /// The prior weight reading (kg) for a simple trend arrow, or null.
  final double? previousWeightKg;

  /// The daily Health Score 0–100 (goal-adherence; docs/06 Rule 8). 0 when no
  /// goals exist yet (the UI shows an empty state, not a fake number).
  final double healthScore;

  /// Whether any goals are set (drives goal-vs-no-goal UI).
  final bool hasGoals;

  /// Signed weight change from the previous reading (kg), or null.
  double? get weightDeltaKg {
    final latest = latestWeightKg;
    final prev = previousWeightKg;
    if (latest == null || prev == null) return null;
    return latest - prev;
  }

  @override
  List<Object?> get props => [
    localDate,
    nutrition,
    calories,
    protein,
    water,
    latestWeightKg,
    previousWeightKg,
    healthScore,
    hasGoals,
  ];
}
