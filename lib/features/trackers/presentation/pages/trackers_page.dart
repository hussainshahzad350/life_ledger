import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:life_ledger/core/di/injector.dart';
import 'package:life_ledger/core/theme/tokens.dart';
import 'package:life_ledger/core/time/clock.dart';
import 'package:life_ledger/features/exercise/domain/exercise_entry.dart';
import 'package:life_ledger/features/mood/domain/mood_entry.dart';
import 'package:life_ledger/features/sleep/domain/sleep_entry.dart';
import 'package:life_ledger/features/symptoms/domain/symptom.dart';
import 'package:life_ledger/features/trackers/presentation/cubit/trackers_cubit.dart';
import 'package:life_ledger/features/trackers/presentation/widgets/log_sheets.dart';
import 'package:life_ledger/features/weight/domain/repositories/weight_repository.dart';

/// The Trackers hub (docs/08 F5–F9): body weight, sleep, mood, exercise and
/// symptoms for today, each with a one-tap quick-log sheet.
class TrackersPage extends StatelessWidget {
  /// Creates the Trackers page for [userId].
  const TrackersPage({required this.userId, super.key});

  /// The current user's id.
  final String userId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TrackersCubit(
        weight: getIt<WeightRepository>(),
        sleep: getIt<SleepRepository>(),
        mood: getIt<MoodRepository>(),
        symptoms: getIt<SymptomRepository>(),
        exercise: getIt<ExerciseRepository>(),
        clock: getIt<Clock>(),
        userId: userId,
      )..load(),
      child: const _TrackersView(),
    );
  }
}

class _TrackersView extends StatelessWidget {
  const _TrackersView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trackers')),
      body: BlocBuilder<TrackersCubit, TrackersState>(
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.error) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Could not load your trackers.'),
                  const SizedBox(height: AppTokens.space2),
                  TextButton(
                    onPressed: () => context.read<TrackersCubit>().load(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => context.read<TrackersCubit>().load(),
            child: ListView(
              padding: const EdgeInsets.all(AppTokens.space4),
              children: [
                _WeightCard(state: state),
                const SizedBox(height: AppTokens.space3),
                _SleepCard(state: state),
                const SizedBox(height: AppTokens.space3),
                _MoodCard(state: state),
                const SizedBox(height: AppTokens.space3),
                _ExerciseCard(state: state),
                const SizedBox(height: AppTokens.space3),
                _SymptomsCard(state: state),
              ],
            ),
          );
        },
      ),
    );
  }
}

Future<void> _notify(BuildContext context, bool ok) async {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(content: Text(ok ? 'Logged' : 'Could not save that.')),
    );
}

class _TrackerCard extends StatelessWidget {
  const _TrackerCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.onLog,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onLog;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(value),
        trailing: FilledButton.tonal(
          onPressed: onLog,
          child: const Text('Log'),
        ),
      ),
    );
  }
}

class _WeightCard extends StatelessWidget {
  const _WeightCard({required this.state});

  final TrackersState state;

  @override
  Widget build(BuildContext context) {
    final w = state.latestWeight;
    return _TrackerCard(
      icon: Icons.monitor_weight_outlined,
      title: 'Weight',
      value: w == null ? 'Not logged' : '${w.weightKg.toStringAsFixed(1)} kg',
      onLog: () async {
        final cubit = context.read<TrackersCubit>();
        final kg = await showWeightSheet(context, initial: w?.weightKg);
        if (kg == null) return;
        final ok = await cubit.logWeight(kg);
        if (context.mounted) await _notify(context, ok);
      },
    );
  }
}

class _SleepCard extends StatelessWidget {
  const _SleepCard({required this.state});

  final TrackersState state;

  @override
  Widget build(BuildContext context) {
    final s = state.sleep;
    final String value;
    if (s == null) {
      value = 'Not logged';
    } else {
      final (h, m) = s.hm;
      final quality = s.quality == null ? '' : ' · quality ${s.quality}/5';
      value = '${h}h ${m}m$quality';
    }
    return _TrackerCard(
      icon: Icons.bedtime_outlined,
      title: 'Sleep',
      value: value,
      onLog: () async {
        final cubit = context.read<TrackersCubit>();
        final result = await showSleepSheet(context);
        if (result == null) return;
        final ok = await cubit.logSleep(
          durationMin: result.durationMin,
          quality: result.quality,
        );
        if (context.mounted) await _notify(context, ok);
      },
    );
  }
}

class _MoodCard extends StatelessWidget {
  const _MoodCard({required this.state});

  final TrackersState state;

  @override
  Widget build(BuildContext context) {
    final m = state.mood;
    return _TrackerCard(
      icon: Icons.mood_outlined,
      title: 'Mood',
      value: m == null ? 'Not logged' : '${moodLabel(m.mood)} (${m.mood}/5)',
      onLog: () async {
        final cubit = context.read<TrackersCubit>();
        final result = await showMoodSheet(context);
        if (result == null) return;
        final ok = await cubit.logMood(mood: result.mood, note: result.note);
        if (context.mounted) await _notify(context, ok);
      },
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({required this.state});

  final TrackersState state;

  @override
  Widget build(BuildContext context) {
    final entries = state.exercises;
    final total = entries.fold<int>(0, (s, e) => s + e.durationMin);
    final value = entries.isEmpty
        ? 'Not logged'
        : '${entries.length} session${entries.length == 1 ? '' : 's'} · '
              '$total min';
    return Column(
      children: [
        _TrackerCard(
          icon: Icons.directions_run_outlined,
          title: 'Exercise',
          value: value,
          onLog: () async {
            final cubit = context.read<TrackersCubit>();
            final result = await showExerciseSheet(context);
            if (result == null) return;
            final ok = await cubit.logExercise(
              activity: result.activity,
              durationMin: result.durationMin,
              intensity: result.intensity,
              energyKcal: result.energyKcal,
            );
            if (context.mounted) await _notify(context, ok);
          },
        ),
        for (final e in entries)
          Padding(
            padding: const EdgeInsets.only(left: AppTokens.space4),
            child: ListTile(
              dense: true,
              leading: const Icon(Icons.circle, size: 8),
              title: Text(e.activity),
              trailing: Text('${e.durationMin} min'),
            ),
          ),
      ],
    );
  }
}

class _SymptomsCard extends StatelessWidget {
  const _SymptomsCard({required this.state});

  final TrackersState state;

  @override
  Widget build(BuildContext context) {
    final entries = state.symptoms;
    final value = entries.isEmpty
        ? 'None logged'
        : '${entries.length} logged today';
    return Column(
      children: [
        _TrackerCard(
          icon: Icons.healing_outlined,
          title: 'Symptoms',
          value: value,
          onLog: () async {
            final cubit = context.read<TrackersCubit>();
            if (state.symptomTypes.isEmpty) {
              await _notify(context, false);
              return;
            }
            final result = await showSymptomSheet(context, state.symptomTypes);
            if (result == null) return;
            final ok = await cubit.logSymptom(
              symptomTypeId: result.typeId,
              severity: result.severity,
              note: result.note,
            );
            if (context.mounted) await _notify(context, ok);
          },
        ),
        for (final e in entries)
          Padding(
            padding: const EdgeInsets.only(left: AppTokens.space4),
            child: ListTile(
              dense: true,
              leading: const Icon(Icons.circle, size: 8),
              title: Text(e.type.name),
              trailing: Text('severity ${e.severity}/5'),
            ),
          ),
      ],
    );
  }
}

/// A human label for a 1–5 mood rating.
String moodLabel(int mood) => switch (mood) {
  1 => 'Very low',
  2 => 'Low',
  3 => 'Okay',
  4 => 'Good',
  _ => 'Great',
};
