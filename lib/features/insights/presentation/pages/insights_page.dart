import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:life_ledger/core/ai/insight.dart';
import 'package:life_ledger/core/di/injector.dart';
import 'package:life_ledger/core/theme/tokens.dart';
import 'package:life_ledger/features/insights/application/generate_insights.dart';
import 'package:life_ledger/features/insights/domain/insight_record.dart';
import 'package:life_ledger/features/insights/presentation/cubit/insights_cubit.dart';

/// The Insights tab (docs/08 F11): the "understanding" payoff — plain-language
/// observations from the on-device rule engine, each with honest confidence,
/// an evidence view, and a standing "not medical advice" disclaimer.
class InsightsPage extends StatelessWidget {
  /// Creates the Insights page for [userId].
  const InsightsPage({required this.userId, super.key});

  /// The current user's id.
  final String userId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => InsightsCubit(
        generate: getIt<GenerateInsights>(),
        repository: getIt<InsightRepository>(),
        userId: userId,
      )..load(),
      child: const _InsightsView(),
    );
  }
}

class _InsightsView extends StatelessWidget {
  const _InsightsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: BlocBuilder<InsightsCubit, InsightsState>(
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: () => context.read<InsightsCubit>().load(),
            child: ListView(
              padding: const EdgeInsets.all(AppTokens.space4),
              children: [
                const _Disclaimer(),
                const SizedBox(height: AppTokens.space3),
                if (state.error)
                  const _Message('Could not load your insights.')
                else if (state.insights.isEmpty)
                  const _Message(
                    'No insights yet. Keep logging — patterns need a couple '
                    'of weeks of data to show up here.',
                  )
                else
                  for (final insight in state.insights)
                    _InsightCard(insight: insight),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space4),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: scheme.onSurfaceVariant),
            const SizedBox(width: AppTokens.space3),
            Expanded(
              child: Text(
                'These are patterns in your own data, not medical advice. '
                'For health concerns, talk to a professional.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.space8),
      child: Text(text, textAlign: TextAlign.center),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});

  final InsightRecord insight;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(insight.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        final cubit = context.read<InsightsCubit>();
        cubit.dismiss(insight.id);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Insight dismissed')));
      },
      background: ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: EdgeInsets.only(right: AppTokens.space4),
            child: Icon(Icons.close),
          ),
        ),
      ),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      insight.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  _ConfidenceBadge(confidence: insight.confidence),
                ],
              ),
              const SizedBox(height: AppTokens.space2),
              Text(insight.body),
              if (insight.isCorrelation) ...[
                const SizedBox(height: AppTokens.space2),
                Text(
                  'Association, not cause.',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ],
              _WhyTile(insight: insight),
              _FeedbackRow(insight: insight),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfidenceBadge extends StatelessWidget {
  const _ConfidenceBadge({required this.confidence});

  final Confidence confidence;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (label, color) = switch (confidence) {
      Confidence.high => ('High confidence', AppTokens.dataViz[4]),
      Confidence.medium => ('Medium confidence', AppTokens.dataViz[2]),
      Confidence.low => ('Low confidence', scheme.outline),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.space2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppTokens.radiusSm),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

class _WhyTile extends StatelessWidget {
  const _WhyTile({required this.insight});

  final InsightRecord insight;

  @override
  Widget build(BuildContext context) {
    final entries = insight.evidence.entries.toList();
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: AppTokens.space2),
        title: Text('Why?', style: Theme.of(context).textTheme.labelLarge),
        subtitle: Text(
          'Based on ${insight.periodStart} → ${insight.periodEnd}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        children: [
          for (final e in entries)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _humanize(e.key),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    _formatValue(e.value),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static String _humanize(String key) {
    final spaced = key.replaceAllMapped(
      RegExp('[A-Z]'),
      (m) => ' ${m[0]!.toLowerCase()}',
    );
    return spaced.isEmpty
        ? key
        : '${spaced[0].toUpperCase()}${spaced.substring(1)}';
  }

  static String _formatValue(Object? value) {
    if (value is double) return value.toStringAsFixed(2);
    return '$value';
  }
}

class _FeedbackRow extends StatelessWidget {
  const _FeedbackRow({required this.insight});

  final InsightRecord insight;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<InsightsCubit>();
    final scheme = Theme.of(context).colorScheme;
    Color colorFor(InsightFeedback f) =>
        insight.feedback == f ? scheme.primary : scheme.onSurfaceVariant;
    return Row(
      children: [
        Text('Helpful?', style: Theme.of(context).textTheme.bodySmall),
        IconButton(
          icon: const Icon(Icons.thumb_up_outlined),
          color: colorFor(InsightFeedback.helpful),
          tooltip: 'Helpful',
          onPressed: () =>
              cubit.giveFeedback(insight.id, InsightFeedback.helpful),
        ),
        IconButton(
          icon: const Icon(Icons.thumb_down_outlined),
          color: colorFor(InsightFeedback.unhelpful),
          tooltip: 'Not helpful',
          onPressed: () =>
              cubit.giveFeedback(insight.id, InsightFeedback.unhelpful),
        ),
      ],
    );
  }
}
