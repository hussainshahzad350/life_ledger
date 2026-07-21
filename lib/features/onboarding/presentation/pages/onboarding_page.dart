import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:life_ledger/core/health/health_types.dart';
import 'package:life_ledger/core/theme/tokens.dart';
import 'package:life_ledger/features/onboarding/presentation/cubit/onboarding_cubit.dart';

/// The skippable onboarding wizard (docs/08 F1, docs/05 §5.6):
/// basics → body → objective, minimal typing (steppers and chips —
/// docs/16 decision-fatigue rules). Every step can be skipped entirely.
class OnboardingPage extends StatefulWidget {
  /// Creates the page. [onFinished] runs after completion or skip.
  const OnboardingPage({required this.onFinished, super.key});

  /// Called when onboarding finishes (either path).
  final VoidCallback onFinished;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  Sex _sex = Sex.unspecified;
  int _birthYear = 1995;
  double _heightCm = 170;
  double _weightKg = 70;
  ActivityLevel _activity = ActivityLevel.moderate;
  WeightObjective _objective = WeightObjective.maintain;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OnboardingCubit, OnboardingState>(
      listener: (context, state) {
        if (state is OnboardingDone) widget.onFinished();
        if (state is OnboardingError) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Couldn't save your setup — please try again."),
            ),
          );
        }
      },
      builder: (context, state) {
        final saving = state is OnboardingSaving;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Welcome to LifeLedger'),
            actions: [
              TextButton(
                onPressed: saving
                    ? null
                    : () => context.read<OnboardingCubit>().skip(),
                child: const Text('Skip'),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(AppTokens.space4),
            children: [
              Text(
                'A few basics personalize your goals. Everything stays on '
                'your device — and you can skip this entirely.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppTokens.space6),
              _section('About you'),
              SegmentedButton<Sex>(
                segments: const [
                  ButtonSegment(value: Sex.female, label: Text('Female')),
                  ButtonSegment(value: Sex.male, label: Text('Male')),
                  ButtonSegment(
                    value: Sex.unspecified,
                    label: Text('Prefer not to say'),
                  ),
                ],
                selected: {_sex},
                onSelectionChanged: (s) => setState(() => _sex = s.first),
              ),
              const SizedBox(height: AppTokens.space4),
              _slider(
                label: 'Birth year: $_birthYear',
                value: _birthYear.toDouble(),
                min: 1930,
                max: DateTime.now().year.toDouble(),
                onChanged: (v) => setState(() => _birthYear = v.round()),
              ),
              const SizedBox(height: AppTokens.space6),
              _section('Your body'),
              _slider(
                label: 'Height: ${_heightCm.round()} cm',
                value: _heightCm,
                min: 120,
                max: 220,
                onChanged: (v) => setState(() => _heightCm = v),
              ),
              _slider(
                label: 'Weight: ${_weightKg.round()} kg',
                value: _weightKg,
                min: 30,
                max: 200,
                onChanged: (v) => setState(() => _weightKg = v),
              ),
              const SizedBox(height: AppTokens.space6),
              _section('Activity & objective'),
              DropdownMenu<ActivityLevel>(
                initialSelection: _activity,
                label: const Text('Activity level'),
                onSelected: (v) => setState(() => _activity = v ?? _activity),
                dropdownMenuEntries: const [
                  DropdownMenuEntry(
                    value: ActivityLevel.sedentary,
                    label: 'Sedentary',
                  ),
                  DropdownMenuEntry(value: ActivityLevel.light, label: 'Light'),
                  DropdownMenuEntry(
                    value: ActivityLevel.moderate,
                    label: 'Moderate',
                  ),
                  DropdownMenuEntry(
                    value: ActivityLevel.active,
                    label: 'Active',
                  ),
                  DropdownMenuEntry(
                    value: ActivityLevel.veryActive,
                    label: 'Very active',
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.space4),
              SegmentedButton<WeightObjective>(
                segments: const [
                  ButtonSegment(
                    value: WeightObjective.lose,
                    label: Text('Lose'),
                  ),
                  ButtonSegment(
                    value: WeightObjective.maintain,
                    label: Text('Maintain'),
                  ),
                  ButtonSegment(
                    value: WeightObjective.gain,
                    label: Text('Gain'),
                  ),
                ],
                selected: {_objective},
                onSelectionChanged: (s) => setState(() => _objective = s.first),
              ),
              const SizedBox(height: AppTokens.space8),
              FilledButton(
                onPressed: saving
                    ? null
                    : () => context.read<OnboardingCubit>().complete(
                        sex: _sex,
                        birthDate: DateTime.utc(_birthYear, 6, 15),
                        heightCm: _heightCm,
                        weightKg: _weightKg,
                        activityLevel: _activity,
                        objective: _objective,
                      ),
                child: saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Set my goals'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(bottom: AppTokens.space2),
    child: Text(title, style: Theme.of(context).textTheme.titleMedium),
  );

  Widget _slider({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        Slider(value: value, min: min, max: max, onChanged: onChanged),
      ],
    );
  }
}
