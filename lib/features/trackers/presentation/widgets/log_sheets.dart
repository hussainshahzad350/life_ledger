import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:life_ledger/core/theme/tokens.dart';
import 'package:life_ledger/features/exercise/domain/exercise_entry.dart';
import 'package:life_ledger/features/symptoms/domain/symptom.dart';

/// Sleep captured by [showSleepSheet].
class SleepInput {
  /// Creates a sleep input.
  const SleepInput({required this.durationMin, this.quality});

  /// Total sleep in minutes.
  final int durationMin;

  /// Optional quality 1–5.
  final int? quality;
}

/// Mood captured by [showMoodSheet].
class MoodInput {
  /// Creates a mood input.
  const MoodInput({required this.mood, this.note});

  /// Rating 1–5.
  final int mood;

  /// Optional note.
  final String? note;
}

/// Symptom captured by [showSymptomSheet].
class SymptomInput {
  /// Creates a symptom input.
  const SymptomInput({required this.typeId, required this.severity, this.note});

  /// Chosen symptom type id.
  final String typeId;

  /// Severity 1–5.
  final int severity;

  /// Optional note.
  final String? note;
}

/// Exercise captured by [showExerciseSheet].
class ExerciseInput {
  /// Creates an exercise input.
  const ExerciseInput({
    required this.activity,
    required this.durationMin,
    this.intensity,
    this.energyKcal,
  });

  /// Activity label.
  final String activity;

  /// Duration in minutes.
  final int durationMin;

  /// Optional perceived intensity.
  final ExerciseIntensity? intensity;

  /// Optional energy burned (kcal).
  final double? energyKcal;
}

Future<T?> _showSheet<T>(BuildContext context, WidgetBuilder builder) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        left: AppTokens.space4,
        right: AppTokens.space4,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppTokens.space4,
      ),
      child: builder(context),
    ),
  );
}

/// Prompts for a body-weight reading in kg. Returns null on cancel.
Future<double?> showWeightSheet(BuildContext context, {double? initial}) {
  return _showSheet<double>(
    context,
    (context) => _WeightSheet(initial: initial),
  );
}

/// Prompts for last night's sleep. Returns null on cancel.
Future<SleepInput?> showSleepSheet(BuildContext context) {
  return _showSheet<SleepInput>(context, (_) => const _SleepSheet());
}

/// Prompts for a mood check-in. Returns null on cancel.
Future<MoodInput?> showMoodSheet(BuildContext context) {
  return _showSheet<MoodInput>(context, (_) => const _MoodSheet());
}

/// Prompts for a symptom from [types]. Returns null on cancel.
Future<SymptomInput?> showSymptomSheet(
  BuildContext context,
  List<SymptomType> types,
) {
  return _showSheet<SymptomInput>(context, (_) => _SymptomSheet(types: types));
}

/// Prompts for an exercise session. Returns null on cancel.
Future<ExerciseInput?> showExerciseSheet(BuildContext context) {
  return _showSheet<ExerciseInput>(context, (_) => const _ExerciseSheet());
}

class _SheetTitle extends StatelessWidget {
  const _SheetTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.space3),
      child: Text(text, style: Theme.of(context).textTheme.titleLarge),
    );
  }
}

/// A 1–5 selector shared by mood, quality and severity inputs.
class _Rating extends StatelessWidget {
  const _Rating({required this.value, required this.onChanged});

  final int? value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 1; i <= 5; i++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: value == i
                  ? FilledButton(
                      onPressed: () => onChanged(i),
                      child: Text('$i'),
                    )
                  : OutlinedButton(
                      onPressed: () => onChanged(i),
                      child: Text('$i'),
                    ),
            ),
          ),
      ],
    );
  }
}

class _WeightSheet extends StatefulWidget {
  const _WeightSheet({this.initial});

  final double? initial;

  @override
  State<_WeightSheet> createState() => _WeightSheetState();
}

class _WeightSheetState extends State<_WeightSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial?.toStringAsFixed(1) ?? '',
  );
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final kg = double.tryParse(_controller.text.trim());
    if (kg == null || kg <= 0 || kg > 500) {
      setState(() => _error = 'Enter a weight in kg (1–500).');
      return;
    }
    Navigator.of(context).pop(kg);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SheetTitle('Log weight'),
        TextField(
          controller: _controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          decoration: InputDecoration(
            labelText: 'Weight',
            suffixText: 'kg',
            errorText: _error,
          ),
          onSubmitted: (_) => _save(),
        ),
        const SizedBox(height: AppTokens.space4),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

class _SleepSheet extends StatefulWidget {
  const _SleepSheet();

  @override
  State<_SleepSheet> createState() => _SleepSheetState();
}

class _SleepSheetState extends State<_SleepSheet> {
  double _hours = 8;
  int? _quality;

  @override
  Widget build(BuildContext context) {
    final h = _hours.floor();
    final m = ((_hours - h) * 60).round();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SheetTitle('Log sleep'),
        Text('Duration: ${h}h ${m}m'),
        Slider(
          value: _hours,
          max: 14,
          divisions: 28,
          label: '${h}h ${m}m',
          onChanged: (v) => setState(() => _hours = v),
        ),
        const SizedBox(height: AppTokens.space2),
        Text(
          'Quality (optional)',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppTokens.space2),
        _Rating(
          value: _quality,
          onChanged: (v) => setState(() => _quality = v),
        ),
        const SizedBox(height: AppTokens.space4),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            SleepInput(durationMin: (_hours * 60).round(), quality: _quality),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _MoodSheet extends StatefulWidget {
  const _MoodSheet();

  @override
  State<_MoodSheet> createState() => _MoodSheetState();
}

class _MoodSheetState extends State<_MoodSheet> {
  int _mood = 3;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SheetTitle('Log mood'),
        _Rating(value: _mood, onChanged: (v) => setState(() => _mood = v)),
        const SizedBox(height: AppTokens.space3),
        TextField(
          controller: _note,
          decoration: const InputDecoration(labelText: 'Note (optional)'),
          maxLines: 2,
        ),
        const SizedBox(height: AppTokens.space4),
        FilledButton(
          onPressed: () => Navigator.of(
            context,
          ).pop(MoodInput(mood: _mood, note: _trimmedOrNull(_note.text))),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _SymptomSheet extends StatefulWidget {
  const _SymptomSheet({required this.types});

  final List<SymptomType> types;

  @override
  State<_SymptomSheet> createState() => _SymptomSheetState();
}

class _SymptomSheetState extends State<_SymptomSheet> {
  late String _typeId = widget.types.first.id;
  int _severity = 3;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SheetTitle('Log symptom'),
        DropdownButtonFormField<String>(
          initialValue: _typeId,
          decoration: const InputDecoration(labelText: 'Symptom'),
          items: [
            for (final t in widget.types)
              DropdownMenuItem(value: t.id, child: Text(t.name)),
          ],
          onChanged: (v) => setState(() => _typeId = v ?? _typeId),
        ),
        const SizedBox(height: AppTokens.space3),
        Text('Severity', style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: AppTokens.space2),
        _Rating(
          value: _severity,
          onChanged: (v) => setState(() => _severity = v),
        ),
        const SizedBox(height: AppTokens.space3),
        TextField(
          controller: _note,
          decoration: const InputDecoration(labelText: 'Note (optional)'),
          maxLines: 2,
        ),
        const SizedBox(height: AppTokens.space4),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(
            SymptomInput(
              typeId: _typeId,
              severity: _severity,
              note: _trimmedOrNull(_note.text),
            ),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _ExerciseSheet extends StatefulWidget {
  const _ExerciseSheet();

  @override
  State<_ExerciseSheet> createState() => _ExerciseSheetState();
}

class _ExerciseSheetState extends State<_ExerciseSheet> {
  final _activity = TextEditingController();
  final _energy = TextEditingController();
  double _minutes = 30;
  ExerciseIntensity? _intensity;
  String? _error;

  @override
  void dispose() {
    _activity.dispose();
    _energy.dispose();
    super.dispose();
  }

  void _save() {
    final activity = _activity.text.trim();
    if (activity.isEmpty) {
      setState(() => _error = 'Name the activity.');
      return;
    }
    final energy = double.tryParse(_energy.text.trim());
    Navigator.of(context).pop(
      ExerciseInput(
        activity: activity,
        durationMin: _minutes.round(),
        intensity: _intensity,
        energyKcal: energy != null && energy > 0 ? energy : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SheetTitle('Log exercise'),
        TextField(
          controller: _activity,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: 'Activity',
            hintText: 'e.g. Running',
            errorText: _error,
          ),
        ),
        const SizedBox(height: AppTokens.space3),
        Text(
          'Duration: ${_minutes.round()} min',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Slider(
          value: _minutes,
          min: 5,
          max: 180,
          divisions: 35,
          label: '${_minutes.round()} min',
          onChanged: (v) => setState(() => _minutes = v),
        ),
        const SizedBox(height: AppTokens.space2),
        Text(
          'Intensity (optional)',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: AppTokens.space2),
        SegmentedButton<ExerciseIntensity?>(
          emptySelectionAllowed: true,
          segments: const [
            ButtonSegment(value: ExerciseIntensity.light, label: Text('Light')),
            ButtonSegment(
              value: ExerciseIntensity.moderate,
              label: Text('Moderate'),
            ),
            ButtonSegment(
              value: ExerciseIntensity.vigorous,
              label: Text('Vigorous'),
            ),
          ],
          selected: {_intensity},
          onSelectionChanged: (s) => setState(() => _intensity = s.first),
        ),
        const SizedBox(height: AppTokens.space3),
        TextField(
          controller: _energy,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          decoration: const InputDecoration(
            labelText: 'Energy (optional)',
            suffixText: 'kcal',
          ),
        ),
        const SizedBox(height: AppTokens.space4),
        FilledButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

String? _trimmedOrNull(String text) {
  final t = text.trim();
  return t.isEmpty ? null : t;
}
