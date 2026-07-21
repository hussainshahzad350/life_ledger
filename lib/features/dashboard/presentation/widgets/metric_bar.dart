import 'package:flutter/material.dart';
import 'package:life_ledger/core/theme/tokens.dart';
import 'package:life_ledger/features/dashboard/domain/daily_summary.dart';

/// A single dashboard metric row: label, value/target, remaining, and a
/// progress bar (docs/05 §5.1). Shows "no goal set" gracefully when the
/// metric has no target.
class MetricBar extends StatelessWidget {
  /// Creates a metric bar.
  const MetricBar({
    required this.label,
    required this.metric,
    required this.unit,
    super.key,
  });

  /// Human label (e.g. "Protein").
  final String label;

  /// The metric progress.
  final MetricProgress metric;

  /// Display unit (e.g. "g", "kcal", "ml").
  final String unit;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final target = metric.target;
    final valueLine = target == null
        ? '${metric.actual.round()} $unit · no goal set'
        : '${metric.actual.round()} / ${target.round()} $unit'
              ' · ${metric.remaining!.round()} $unit left';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.space2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: textTheme.titleSmall),
              Text(valueLine, style: textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: AppTokens.space1),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTokens.radiusSm),
            child: LinearProgressIndicator(
              value: metric.ratio ?? 0,
              minHeight: 8,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }
}
