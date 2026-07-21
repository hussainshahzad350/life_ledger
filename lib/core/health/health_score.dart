import 'package:equatable/equatable.dart';
import 'package:life_ledger/core/health/health_constants.dart';

/// How a score component's adherence is computed (docs/06 Rule 8).
enum ScoreComponentKind {
  /// "Reach the target": `clamp(actual / target, 0, 1)`.
  reach,

  /// "Stay under the limit": `clamp(1 − overshoot/limit, 0, 1)`.
  limit,

  /// "Land inside ±band of the target" (calories):
  /// 1.0 inside the band, then linearly decreasing with excess deviation.
  band,
}

/// One input to the daily Health Score.
class ScoreComponent extends Equatable {
  /// Creates a component. [target] must be > 0 for the component to count;
  /// zero/negative targets are skipped and weights renormalize
  /// (docs/06 §10 division-by-zero rule).
  const ScoreComponent({
    required this.kind,
    required this.actual,
    required this.target,
    required this.weight,
  });

  /// Adherence semantics for this metric.
  final ScoreComponentKind kind;

  /// Today's actual value.
  final double actual;

  /// The goal (reach/band) or ceiling (limit) in force.
  final double target;

  /// Relative weight (defaults in [HealthConstants.scoreWeightCalories] etc.).
  final double weight;

  @override
  List<Object?> get props => [kind, actual, target, weight];
}

/// Adherence of a single component in `[0, 1]` (docs/06 Rule 8 formulas).
double componentAdherence(ScoreComponent component) {
  final ScoreComponent(:kind, :actual, :target) = component;
  return switch (kind) {
    ScoreComponentKind.reach => (actual / target).clamp(0, 1).toDouble(),
    ScoreComponentKind.limit =>
      (1 - (actual - target).clamp(0, double.infinity) / target)
          .clamp(0, 1)
          .toDouble(),
    ScoreComponentKind.band => _bandAdherence(actual, target),
  };
}

/// Band adherence: full credit within ±[HealthConstants.calorieBandPct] of
/// the target, then decreasing linearly with the deviation beyond the band.
/// A documented product definition (docs/06 Rule 8), not a clinical measure.
double _bandAdherence(double actual, double target) {
  final deviation = (actual - target).abs() / target;
  if (deviation <= HealthConstants.calorieBandPct) return 1;
  return (1 - (deviation - HealthConstants.calorieBandPct)).clamp(0, 1);
}

/// The daily Health Score 0–100 — a **goal-adherence indicator, not a
/// medical verdict** (docs/06 Rule 8, decisions/why-health-score-exists.md).
///
/// Components with a non-positive target or weight are skipped and the
/// remaining weights renormalize; an empty effective set yields 0
/// (nothing to adhere to — the UI shows an empty state instead of a number).
double healthScore(List<ScoreComponent> components) {
  var weightedSum = 0.0;
  var totalWeight = 0.0;
  for (final component in components) {
    if (component.target <= 0 || component.weight <= 0) continue;
    weightedSum += component.weight * componentAdherence(component);
    totalWeight += component.weight;
  }
  if (totalWeight == 0) return 0;
  return 100 * weightedSum / totalWeight;
}
