import 'package:equatable/equatable.dart';
import 'package:life_ledger/core/ai/ai_constants.dart';

/// The transparent exposed-vs-unexposed comparison used by all correlation
/// rules (docs/07 §5) — simple, explainable statistics, never opaque ML.
class CorrelationFinding extends Equatable {
  /// Creates a finding.
  const CorrelationFinding({
    required this.exposedMean,
    required this.unexposedMean,
    required this.exposedCount,
    required this.unexposedCount,
  });

  /// Mean of the target metric on exposed days.
  final double exposedMean;

  /// Mean of the target metric on unexposed days.
  final double unexposedMean;

  /// Number of exposed observations.
  final int exposedCount;

  /// Number of unexposed observations.
  final int unexposedCount;

  /// Exposed minus unexposed mean.
  double get difference => exposedMean - unexposedMean;

  /// Whether both groups meet the minimum sample thresholds (docs/07 §4).
  bool get sufficientSample =>
      exposedCount >= AiConstants.minExposedDays &&
      unexposedCount >= AiConstants.minUnexposedDays;

  /// Whether both groups reach the medium-confidence sample size.
  bool get mediumSample =>
      exposedCount >= AiConstants.mediumConfidenceSample &&
      unexposedCount >= AiConstants.mediumConfidenceSample;

  @override
  List<Object?> get props => [
    exposedMean,
    unexposedMean,
    exposedCount,
    unexposedCount,
  ];
}

/// Compares the target metric between exposed and unexposed observations.
/// Returns null when either group is empty (no comparison possible).
CorrelationFinding? compareExposure({
  required List<double> exposed,
  required List<double> unexposed,
}) {
  if (exposed.isEmpty || unexposed.isEmpty) return null;
  double mean(List<double> xs) => xs.reduce((a, b) => a + b) / xs.length;
  return CorrelationFinding(
    exposedMean: mean(exposed),
    unexposedMean: mean(unexposed),
    exposedCount: exposed.length,
    unexposedCount: unexposed.length,
  );
}
