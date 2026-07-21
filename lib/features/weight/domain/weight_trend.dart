import 'package:equatable/equatable.dart';
import 'package:life_ledger/features/weight/domain/entities/weight_entry.dart';

/// Direction of a smoothed weight trend (docs/08 F5/F10).
enum TrendDirection {
  /// Smoothed weight is falling.
  down,

  /// Smoothed weight is flat within the noise band.
  steady,

  /// Smoothed weight is rising.
  up,
}

/// A smoothed weight trend derived from a moving average (docs/06 §weight).
///
/// Body weight swings day to day on water and gut contents, so a single
/// reading is noise. We average the readings to see the real direction.
class WeightTrend extends Equatable {
  /// Creates a trend result.
  const WeightTrend({
    required this.direction,
    required this.averageKg,
    required this.deltaKg,
    required this.sampleCount,
  });

  /// The direction after smoothing.
  final TrendDirection direction;

  /// The moving average across the sampled window, in kg.
  final double averageKg;

  /// Newest-average minus oldest-average across the window, in kg.
  /// Negative means losing, positive means gaining.
  final double deltaKg;

  /// How many readings fed the trend.
  final int sampleCount;

  @override
  List<Object?> get props => [direction, averageKg, deltaKg, sampleCount];
}

/// Computes a smoothed weight trend from [readings] (any order).
///
/// Readings are sorted oldest→newest, then split into two halves whose means
/// are compared. A change smaller than [noiseBandKg] counts as steady so
/// day-to-day water weight does not read as a real gain or loss. Returns null
/// when there are too few readings to smooth.
WeightTrend? computeWeightTrend(
  List<WeightEntry> readings, {
  double noiseBandKg = 0.3,
}) {
  if (readings.length < 2) return null;

  final sorted = [...readings]
    ..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
  final weights = sorted.map((e) => e.weightKg).toList();

  final average = weights.reduce((a, b) => a + b) / weights.length;

  final mid = weights.length ~/ 2;
  final older = weights.sublist(0, mid);
  // Odd counts drop the middle reading so the halves stay balanced.
  final newer = weights.sublist(weights.length - mid);
  final olderMean = older.reduce((a, b) => a + b) / older.length;
  final newerMean = newer.reduce((a, b) => a + b) / newer.length;
  final delta = newerMean - olderMean;

  final TrendDirection direction;
  if (delta.abs() < noiseBandKg) {
    direction = TrendDirection.steady;
  } else if (delta < 0) {
    direction = TrendDirection.down;
  } else {
    direction = TrendDirection.up;
  }

  return WeightTrend(
    direction: direction,
    averageKg: average,
    deltaKg: delta,
    sampleCount: weights.length,
  );
}
