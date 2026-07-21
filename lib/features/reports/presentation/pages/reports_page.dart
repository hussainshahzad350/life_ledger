import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:life_ledger/core/di/injector.dart';
import 'package:life_ledger/core/theme/tokens.dart';
import 'package:life_ledger/features/goals/domain/entities/goal.dart';
import 'package:life_ledger/features/reports/domain/report_models.dart';
import 'package:life_ledger/features/reports/presentation/cubit/reports_cubit.dart';
import 'package:life_ledger/features/reports/presentation/widgets/series_chart.dart';

/// The Reports tab (docs/08 F12): day/week/month/year views of nutrition,
/// hydration, weight and habits, with the goal in force drawn on top.
class ReportsPage extends StatelessWidget {
  /// Creates the Reports page for [userId].
  const ReportsPage({required this.userId, super.key});

  /// The current user's id.
  final String userId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          ReportsCubit(repository: getIt<ReportRepository>(), userId: userId)
            ..load(),
      child: const _ReportsView(),
    );
  }
}

class _ReportsView extends StatelessWidget {
  const _ReportsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: BlocBuilder<ReportsCubit, ReportsState>(
        builder: (context, state) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppTokens.space4),
                child: SegmentedButton<ReportRange>(
                  segments: [
                    for (final r in ReportRange.values)
                      ButtonSegment(value: r, label: Text(r.label)),
                  ],
                  selected: {state.range},
                  onSelectionChanged: (s) =>
                      context.read<ReportsCubit>().setRange(s.first),
                ),
              ),
              Expanded(child: _Body(state: state)),
            ],
          );
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state});

  final ReportsState state;

  @override
  Widget build(BuildContext context) {
    if (state.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error || state.summary == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Could not load your report.'),
            const SizedBox(height: AppTokens.space2),
            TextButton(
              onPressed: () => context.read<ReportsCubit>().load(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    final summary = state.summary!;
    if (summary.daysLogged == 0) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppTokens.space6),
          child: Text(
            'Nothing logged in this range yet.\n'
            'Log meals and trackers to see your patterns here.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final points = summary.points;
    final endDate = summary.window.endDate;
    final caloriesTarget = summary.targetFor(GoalType.calories, endDate);
    final waterTarget = summary.targetFor(GoalType.water, endDate);
    final sleepTarget = summary.targetFor(GoalType.sleep, endDate);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.space4,
        0,
        AppTokens.space4,
        AppTokens.space6,
      ),
      children: [
        _SummaryStats(summary: summary),
        const SizedBox(height: AppTokens.space4),
        _ChartCard(
          title: 'Calories',
          caption: caloriesTarget == null
              ? 'kcal per day'
              : 'kcal per day · goal ${caloriesTarget.round()}',
          child: SeriesChart(
            values: [
              for (final p in points) p.calories == 0 ? null : p.calories,
            ],
            color: AppTokens.dataViz[0],
            targetValue: caloriesTarget,
          ),
        ),
        _ChartCard(
          title: 'Water',
          caption: waterTarget == null
              ? 'ml per day'
              : 'ml per day · goal ${waterTarget.round()}',
          child: SeriesChart(
            values: [for (final p in points) p.waterMl == 0 ? null : p.waterMl],
            color: AppTokens.dataViz[1],
            targetValue: waterTarget,
          ),
        ),
        _ChartCard(
          title: 'Weight',
          caption: 'kg',
          child: SeriesChart(
            values: [for (final p in points) p.weightKg],
            color: AppTokens.dataViz[2],
            mode: ChartMode.line,
          ),
        ),
        _ChartCard(
          title: 'Sleep',
          caption: sleepTarget == null
              ? 'minutes per night'
              : 'minutes per night · goal ${sleepTarget.round()}',
          child: SeriesChart(
            values: [for (final p in points) p.sleepMin?.toDouble()],
            color: AppTokens.dataViz[3],
            targetValue: sleepTarget,
          ),
        ),
        _ChartCard(
          title: 'Mood',
          caption: '1–5 average',
          child: SeriesChart(
            values: [for (final p in points) p.moodAvg],
            color: AppTokens.dataViz[4],
            mode: ChartMode.line,
          ),
        ),
      ],
    );
  }
}

class _SummaryStats extends StatelessWidget {
  const _SummaryStats({required this.summary});

  final ReportSummary summary;

  @override
  Widget build(BuildContext context) {
    String kcal(double? v) => v == null ? '—' : '${v.round()} kcal';
    String grams(double? v) => v == null ? '—' : '${v.round()} g';
    String litres(double? v) =>
        v == null ? '—' : '${(v / 1000).toStringAsFixed(1)} L';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space4),
        child: Wrap(
          spacing: AppTokens.space6,
          runSpacing: AppTokens.space3,
          children: [
            _Stat(label: 'Days logged', value: '${summary.daysLogged}'),
            _Stat(label: 'Avg calories', value: kcal(summary.avgCalories)),
            _Stat(label: 'Avg protein', value: grams(summary.avgProteinG)),
            _Stat(label: 'Avg water', value: litres(summary.avgWaterMl)),
            _Stat(label: 'Exercise', value: '${summary.totalExerciseMin} min'),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.caption,
    required this.child,
  });

  final String title;
  final String caption;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            Text(caption, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: AppTokens.space3),
            child,
          ],
        ),
      ),
    );
  }
}
