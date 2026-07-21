import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:life_ledger/core/di/injector.dart';
import 'package:life_ledger/core/theme/tokens.dart';
import 'package:life_ledger/core/time/clock.dart';
import 'package:life_ledger/features/dashboard/application/get_daily_summary.dart';
import 'package:life_ledger/features/dashboard/domain/daily_summary.dart';
import 'package:life_ledger/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:life_ledger/features/dashboard/presentation/widgets/metric_bar.dart';
import 'package:life_ledger/features/food/application/food_use_cases.dart';
import 'package:life_ledger/features/food/domain/entities/food_entry.dart';
import 'package:life_ledger/features/food/domain/repositories/food_repository.dart';
import 'package:life_ledger/features/food/presentation/cubit/quick_add_cubit.dart';
import 'package:life_ledger/features/food/presentation/pages/quick_add_page.dart';
import 'package:life_ledger/features/insights/presentation/pages/insights_page.dart';
import 'package:life_ledger/features/journal/presentation/cubit/journal_cubit.dart';
import 'package:life_ledger/features/reports/presentation/pages/reports_page.dart';
import 'package:life_ledger/features/trackers/presentation/pages/trackers_page.dart';
import 'package:life_ledger/features/water/domain/repositories/water_repository.dart';
import 'package:life_ledger/features/water/presentation/cubit/water_cubit.dart';

/// The at-a-glance dashboard (docs/08 F10, docs/05 §5.1): answers the five
/// questions — calories, protein, water, weight trend, health score — above
/// the fold, with one-tap logging and the day's meal timeline below.
class DashboardPage extends StatelessWidget {
  /// Creates the dashboard for [userId].
  const DashboardPage({required this.userId, super.key});

  /// The current user's id.
  final String userId;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => DashboardCubit(
            getDailySummary: getIt<GetDailySummary>(),
            userId: userId,
          )..load(),
        ),
        BlocProvider(
          create: (_) => JournalCubit(
            repository: getIt<FoodRepository>(),
            getDayTimeline: getIt<GetDayTimeline>(),
            clock: getIt<Clock>(),
            userId: userId,
          )..load(),
        ),
        BlocProvider(
          create: (_) => WaterCubit(
            repository: getIt<WaterRepository>(),
            clock: getIt<Clock>(),
            userId: userId,
          ),
        ),
      ],
      child: _DashboardView(userId: userId),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView({required this.userId});

  final String userId;

  Future<void> _refreshAll(BuildContext context) async {
    await context.read<DashboardCubit>().refresh();
    if (context.mounted) await context.read<JournalCubit>().load();
  }

  Future<void> _openTrackers(BuildContext context) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => TrackersPage(userId: userId)),
    );
    if (context.mounted) await _refreshAll(context);
  }

  void _openReports(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => ReportsPage(userId: userId)),
    );
  }

  void _openInsights(BuildContext context) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => InsightsPage(userId: userId)),
    );
  }

  Future<void> _openQuickAdd(BuildContext context) async {
    await Navigator.of(context).push<FoodEntry>(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => QuickAddCubit(
            repository: getIt<FoodRepository>(),
            logFoodEntry: getIt<LogFoodEntry>(),
            clock: getIt<Clock>(),
            userId: userId,
          )..load(),
          child: const QuickAddPage(),
        ),
      ),
    );
    if (context.mounted) await _refreshAll(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Today'),
        actions: [
          IconButton(
            icon: const Icon(Icons.timeline_outlined),
            tooltip: 'Trackers',
            onPressed: () => _openTrackers(context),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart_outlined),
            tooltip: 'Reports',
            onPressed: () => _openReports(context),
          ),
          IconButton(
            icon: const Icon(Icons.lightbulb_outline),
            tooltip: 'Insights',
            onPressed: () => _openInsights(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openQuickAdd(context),
        icon: const Icon(Icons.add),
        label: const Text('Add food'),
      ),
      body: RefreshIndicator(
        onRefresh: () => _refreshAll(context),
        child: ListView(
          padding: const EdgeInsets.all(AppTokens.space4),
          children: [
            const _SummarySection(),
            const SizedBox(height: AppTokens.space4),
            _WaterCard(onLogged: () => _refreshAll(context)),
            const SizedBox(height: AppTokens.space4),
            const _TimelineSection(),
          ],
        ),
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        return switch (state) {
          DashboardLoading() => const Padding(
            padding: EdgeInsets.all(AppTokens.space6),
            child: Center(child: CircularProgressIndicator()),
          ),
          DashboardError() => Card(
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.space4),
              child: Row(
                children: [
                  const Expanded(child: Text('Could not load your summary.')),
                  TextButton(
                    onPressed: () => context.read<DashboardCubit>().load(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          DashboardLoaded(:final summary) => _Summary(summary: summary),
        };
      },
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.summary});

  final DailySummary summary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ScoreAndWeightRow(summary: summary),
        const SizedBox(height: AppTokens.space3),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.space4),
            child: Column(
              children: [
                MetricBar(
                  label: 'Calories',
                  metric: summary.calories,
                  unit: 'kcal',
                ),
                MetricBar(label: 'Protein', metric: summary.protein, unit: 'g'),
                MetricBar(label: 'Water', metric: summary.water, unit: 'ml'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ScoreAndWeightRow extends StatelessWidget {
  const _ScoreAndWeightRow({required this.summary});

  final DailySummary summary;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTokens.space4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Health score',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: AppTokens.space1),
                    Text(
                      summary.hasGoals
                          ? '${summary.healthScore.round()} / 100'
                          : 'Set goals to see this',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Text(
                      'goal adherence today',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTokens.space3),
          Expanded(child: _WeightCard(summary: summary)),
        ],
      ),
    );
  }
}

class _WeightCard extends StatelessWidget {
  const _WeightCard({required this.summary});

  final DailySummary summary;

  @override
  Widget build(BuildContext context) {
    final latest = summary.latestWeightKg;
    final delta = summary.weightDeltaKg;
    final (icon, trend) = switch (delta) {
      null => (Icons.remove, ''),
      final d when d < 0 => (Icons.south, ' ${d.abs().toStringAsFixed(1)} kg'),
      final d when d > 0 => (Icons.north, ' ${d.toStringAsFixed(1)} kg'),
      _ => (Icons.remove, ' steady'),
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Weight', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: AppTokens.space1),
            Text(
              latest == null ? '—' : '${latest.toStringAsFixed(1)} kg',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Row(
              children: [
                Icon(icon, size: 16),
                Text(
                  delta == null ? 'log to see trend' : trend,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WaterCard extends StatelessWidget {
  const _WaterCard({required this.onLogged});

  final Future<void> Function() onLogged;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardCubit, DashboardState>(
      builder: (context, state) {
        final ml = state is DashboardLoaded ? state.summary.water.actual : 0.0;
        final litres = (ml / 1000).toStringAsFixed(1);
        return Card(
          child: ListTile(
            leading: const Icon(Icons.water_drop_outlined),
            title: const Text('Water'),
            subtitle: Text('$litres L today'),
            trailing: FilledButton.tonal(
              onPressed: () async {
                await context.read<WaterCubit>().add();
                await onLogged();
              },
              child: const Text('+250 ml'),
            ),
          ),
        );
      },
    );
  }
}

class _TimelineSection extends StatelessWidget {
  const _TimelineSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<JournalCubit, JournalState>(
      builder: (context, state) {
        return switch (state) {
          JournalLoading() => const SizedBox.shrink(),
          JournalError() => const Text('Could not load your meals.'),
          JournalLoaded(:final timeline) when timeline.isEmpty => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppTokens.space6),
            child: Text(
              'No meals logged yet. Tap “Add food” to start.',
              textAlign: TextAlign.center,
            ),
          ),
          JournalLoaded(:final timeline) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Meals', style: Theme.of(context).textTheme.titleMedium),
              for (final slot in MealSlot.values)
                if (timeline.byMeal[slot]!.isNotEmpty)
                  _MealGroup(slot: slot, entries: timeline.byMeal[slot]!),
            ],
          ),
        };
      },
    );
  }
}

class _MealGroup extends StatelessWidget {
  const _MealGroup({required this.slot, required this.entries});

  final MealSlot slot;
  final List<FoodEntry> entries;

  @override
  Widget build(BuildContext context) {
    final kcal = entries.fold<double>(0, (s, e) => s + e.nutrition.calories);
    final name = '${slot.name[0].toUpperCase()}${slot.name.substring(1)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: AppTokens.space3),
          child: Text(
            '$name · ${kcal.round()} kcal',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        for (final entry in entries)
          Dismissible(
            key: ValueKey(entry.id),
            direction: DismissDirection.endToStart,
            onDismissed: (_) {
              final journal = context.read<JournalCubit>();
              final dashboard = context.read<DashboardCubit>();
              journal.delete(entry).then((_) => dashboard.refresh());
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text('Removed ${entry.item.name}'),
                    action: SnackBarAction(
                      label: 'Undo',
                      onPressed: () => journal
                          .undoDelete(entry)
                          .then((_) => dashboard.refresh()),
                    ),
                  ),
                );
            },
            background: ColoredBox(
              color: Theme.of(context).colorScheme.errorContainer,
              child: const Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.only(right: AppTokens.space4),
                  child: Icon(Icons.delete_outline),
                ),
              ),
            ),
            child: ListTile(
              dense: true,
              title: Text(entry.item.name),
              trailing: Text('${entry.nutrition.calories.round()} kcal'),
            ),
          ),
      ],
    );
  }
}
