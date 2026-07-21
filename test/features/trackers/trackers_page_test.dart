import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_ledger/core/di/injector.dart';
import 'package:life_ledger/core/error/result.dart';
import 'package:life_ledger/core/time/clock.dart';
import 'package:life_ledger/features/exercise/domain/exercise_entry.dart';
import 'package:life_ledger/features/mood/domain/mood_entry.dart';
import 'package:life_ledger/features/sleep/domain/sleep_entry.dart';
import 'package:life_ledger/features/symptoms/domain/symptom.dart';
import 'package:life_ledger/features/trackers/presentation/pages/trackers_page.dart';
import 'package:life_ledger/features/weight/domain/entities/weight_entry.dart';
import 'package:life_ledger/features/weight/domain/repositories/weight_repository.dart';

/// In-memory weight repo — the widget tests avoid real-DB async (docs/11 §6).
class FakeWeightRepository implements WeightRepository {
  final List<WeightEntry> _entries = [];
  var _seq = 0;

  @override
  Future<Result<WeightEntry>> addEntry({
    required String userId,
    required double weightKg,
  }) async {
    final entry = WeightEntry(
      id: 'w${_seq++}',
      userId: userId,
      weightKg: weightKg,
      loggedAt: DateTime.utc(2026, 7, 21),
      localDate: '2026-07-21',
    );
    _entries.insert(0, entry);
    return Result.success(entry);
  }

  @override
  Future<Result<WeightEntry?>> getLatest(String userId) async =>
      Result.success(_entries.isEmpty ? null : _entries.first);

  @override
  Future<Result<List<WeightEntry>>> getRecent(
    String userId, {
    int limit = 2,
  }) async => Result.success(_entries.take(limit).toList());
}

class FakeSleepRepository implements SleepRepository {
  SleepEntry? _entry;

  @override
  Future<Result<SleepEntry>> add({
    required String userId,
    required int durationMin,
    int? quality,
  }) async {
    _entry = SleepEntry(
      id: 's1',
      userId: userId,
      durationMin: durationMin,
      quality: quality,
      loggedAt: DateTime.utc(2026, 7, 21),
      localDate: '2026-07-21',
    );
    return Result.success(_entry!);
  }

  @override
  Future<Result<SleepEntry?>> forDate(String userId, String localDate) async =>
      Result.success(_entry);
}

class FakeMoodRepository implements MoodRepository {
  MoodEntry? _entry;

  @override
  Future<Result<MoodEntry>> add({
    required String userId,
    required int mood,
    String? note,
  }) async {
    _entry = MoodEntry(
      id: 'm1',
      userId: userId,
      mood: mood,
      note: note,
      loggedAt: DateTime.utc(2026, 7, 21),
      localDate: '2026-07-21',
    );
    return Result.success(_entry!);
  }

  @override
  Future<Result<MoodEntry?>> forDate(String userId, String localDate) async =>
      Result.success(_entry);
}

class FakeSymptomRepository implements SymptomRepository {
  static const _type = SymptomType(id: 'st-bloating', name: 'Bloating');
  final List<SymptomEntry> _entries = [];

  @override
  Future<Result<List<SymptomType>>> types() async =>
      const Result.success([_type]);

  @override
  Future<Result<SymptomEntry>> add({
    required String userId,
    required String symptomTypeId,
    required int severity,
    String? note,
  }) async {
    final entry = SymptomEntry(
      id: 'sy${_entries.length}',
      userId: userId,
      type: _type,
      severity: severity,
      note: note,
      loggedAt: DateTime.utc(2026, 7, 21),
      localDate: '2026-07-21',
    );
    _entries.insert(0, entry);
    return Result.success(entry);
  }

  @override
  Future<Result<List<SymptomEntry>>> forDate(
    String userId,
    String localDate,
  ) async => Result.success(List.of(_entries));
}

class FakeExerciseRepository implements ExerciseRepository {
  final List<ExerciseEntry> _entries = [];

  @override
  Future<Result<ExerciseEntry>> add({
    required String userId,
    required String activity,
    required int durationMin,
    ExerciseIntensity? intensity,
    double? energyKcal,
  }) async {
    final entry = ExerciseEntry(
      id: 'e${_entries.length}',
      userId: userId,
      activity: activity,
      durationMin: durationMin,
      intensity: intensity,
      energyKcal: energyKcal,
      loggedAt: DateTime.utc(2026, 7, 21),
      localDate: '2026-07-21',
    );
    _entries.insert(0, entry);
    return Result.success(entry);
  }

  @override
  Future<Result<List<ExerciseEntry>>> forDate(
    String userId,
    String localDate,
  ) async => Result.success(List.of(_entries));
}

void main() {
  setUp(() {
    getIt
      ..registerSingleton<Clock>(FixedClock(DateTime(2026, 7, 21)))
      ..registerSingleton<WeightRepository>(FakeWeightRepository())
      ..registerSingleton<SleepRepository>(FakeSleepRepository())
      ..registerSingleton<MoodRepository>(FakeMoodRepository())
      ..registerSingleton<SymptomRepository>(FakeSymptomRepository())
      ..registerSingleton<ExerciseRepository>(FakeExerciseRepository());
  });

  tearDown(getIt.reset);

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: TrackersPage(userId: 'u1')),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders a card per tracker', (tester) async {
    await pumpPage(tester);
    expect(find.text('Weight'), findsOneWidget);
    expect(find.text('Sleep'), findsOneWidget);
    expect(find.text('Mood'), findsOneWidget);
    expect(find.text('Exercise'), findsOneWidget);
    expect(find.text('Symptoms'), findsOneWidget);
    expect(find.text('Log'), findsNWidgets(5));
  });

  testWidgets('logging mood updates the card', (tester) async {
    await pumpPage(tester);

    // Open the Mood sheet (third Log button).
    await tester.tap(find.text('Log').at(2));
    await tester.pumpAndSettle();
    expect(find.text('Log mood'), findsOneWidget);

    // Pick rating 4, then save.
    await tester.tap(find.text('4'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Good (4/5)'), findsOneWidget);
  });

  testWidgets('weight sheet rejects a bad value then saves a good one', (
    tester,
  ) async {
    await pumpPage(tester);
    await tester.tap(find.text('Log').first);
    await tester.pumpAndSettle();
    expect(find.text('Log weight'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '0');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a weight in kg (1–500).'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '70.5');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('70.5 kg'), findsOneWidget);
  });

  testWidgets('sleep sheet saves the default duration', (tester) async {
    await pumpPage(tester);
    await tester.tap(find.text('Log').at(1));
    await tester.pumpAndSettle();
    expect(find.text('Log sleep'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('8h 0m'), findsOneWidget);
  });

  testWidgets('exercise sheet requires an activity then logs it', (
    tester,
  ) async {
    await pumpPage(tester);
    await tester.tap(find.text('Log').at(3));
    await tester.pumpAndSettle();
    expect(find.text('Log exercise'), findsOneWidget);

    // Save with no activity → validation error.
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Name the activity.'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Running');
    await tester.tap(find.text('Vigorous'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Running'), findsOneWidget);
  });

  testWidgets('symptom sheet logs the selected type', (tester) async {
    await pumpPage(tester);
    await tester.tap(find.text('Log').at(4));
    await tester.pumpAndSettle();
    expect(find.text('Log symptom'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('1 logged today'), findsOneWidget);
  });
}
