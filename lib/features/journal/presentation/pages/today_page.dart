import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:life_ledger/core/di/injector.dart';
import 'package:life_ledger/core/theme/tokens.dart';
import 'package:life_ledger/core/time/clock.dart';
import 'package:life_ledger/features/food/application/food_use_cases.dart';
import 'package:life_ledger/features/food/domain/entities/food_entry.dart';
import 'package:life_ledger/features/food/domain/repositories/food_repository.dart';
import 'package:life_ledger/features/food/presentation/cubit/quick_add_cubit.dart';
import 'package:life_ledger/features/food/presentation/pages/quick_add_page.dart';
import 'package:life_ledger/features/journal/presentation/cubit/journal_cubit.dart';
import 'package:life_ledger/features/water/domain/repositories/water_repository.dart';
import 'package:life_ledger/features/water/presentation/cubit/water_cubit.dart';

/// Interim "Today" home for M3 (docs/12): the core logging loop — meal
/// timeline, one-tap water, and Quick-Add. The full at-a-glance dashboard
/// (rings, health score, insights) arrives in M4.
class TodayPage extends StatelessWidget {
  /// Creates the page for [userId].
  const TodayPage({required this.userId, super.key});

  /// The current user's id.
  final String userId;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
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
          )..load(),
        ),
      ],
      child: _TodayView(userId: userId),
    );
  }
}

class _TodayView extends StatelessWidget {
  const _TodayView({required this.userId});

  final String userId;

  Future<void> _openQuickAdd(BuildContext context) async {
    final journal = context.read<JournalCubit>();
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
    await journal.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Today')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openQuickAdd(context),
        icon: const Icon(Icons.add),
        label: const Text('Add food'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTokens.space4),
        children: const [
          _WaterCard(),
          SizedBox(height: AppTokens.space4),
          _Timeline(),
        ],
      ),
    );
  }
}

class _WaterCard extends StatelessWidget {
  const _WaterCard();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WaterCubit, WaterState>(
      builder: (context, state) {
        final litres = (state.totalMl / 1000).toStringAsFixed(1);
        return Card(
          child: ListTile(
            leading: const Icon(Icons.water_drop_outlined),
            title: const Text('Water'),
            subtitle: Text('$litres L today'),
            trailing: FilledButton.tonal(
              onPressed: () => context.read<WaterCubit>().add(),
              child: const Text('+250 ml'),
            ),
          ),
        );
      },
    );
  }
}

class _Timeline extends StatelessWidget {
  const _Timeline();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<JournalCubit, JournalState>(
      builder: (context, state) {
        return switch (state) {
          JournalLoading() => const Center(child: CircularProgressIndicator()),
          JournalError() => const Text('Could not load your day.'),
          JournalLoaded(:final timeline) when timeline.isEmpty => const Padding(
            padding: EdgeInsets.all(AppTokens.space6),
            child: Text(
              'Nothing logged yet. Tap “Add food” to start your day.',
              textAlign: TextAlign.center,
            ),
          ),
          JournalLoaded(:final timeline) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${timeline.total.calories.round()} kcal · '
                '${timeline.total.proteinG.round()} g protein today',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppTokens.space2),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: AppTokens.space3),
          child: Text(
            '${slot.name[0].toUpperCase()}${slot.name.substring(1)} · '
            '${kcal.round()} kcal',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        for (final entry in entries)
          Dismissible(
            key: ValueKey(entry.id),
            direction: DismissDirection.endToStart,
            onDismissed: (_) {
              final journal = context.read<JournalCubit>();
              journal.delete(entry);
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text('Removed ${entry.item.name}'),
                    action: SnackBarAction(
                      label: 'Undo',
                      onPressed: () => journal.undoDelete(entry),
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
