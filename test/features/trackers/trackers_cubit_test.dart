import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_ledger/core/error/failure.dart';
import 'package:life_ledger/core/error/result.dart';
import 'package:life_ledger/core/time/clock.dart';
import 'package:life_ledger/features/exercise/domain/exercise_entry.dart';
import 'package:life_ledger/features/mood/domain/mood_entry.dart';
import 'package:life_ledger/features/sleep/domain/sleep_entry.dart';
import 'package:life_ledger/features/symptoms/domain/symptom.dart';
import 'package:life_ledger/features/trackers/presentation/cubit/trackers_cubit.dart';
import 'package:life_ledger/features/weight/domain/entities/weight_entry.dart';
import 'package:life_ledger/features/weight/domain/repositories/weight_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockWeightRepository extends Mock implements WeightRepository {}

class MockSleepRepository extends Mock implements SleepRepository {}

class MockMoodRepository extends Mock implements MoodRepository {}

class MockSymptomRepository extends Mock implements SymptomRepository {}

class MockExerciseRepository extends Mock implements ExerciseRepository {}

void main() {
  late MockWeightRepository weight;
  late MockSleepRepository sleep;
  late MockMoodRepository mood;
  late MockSymptomRepository symptoms;
  late MockExerciseRepository exercise;

  const userId = 'u1';
  const today = '2026-07-21';

  final weightEntry = WeightEntry(
    id: 'w1',
    userId: userId,
    weightKg: 70,
    loggedAt: DateTime.utc(2026, 7, 21),
    localDate: today,
  );
  const bloating = SymptomType(id: 'st-bloating', name: 'Bloating');

  TrackersCubit build() => TrackersCubit(
    weight: weight,
    sleep: sleep,
    mood: mood,
    symptoms: symptoms,
    exercise: exercise,
    clock: FixedClock(DateTime(2026, 7, 21)),
    userId: userId,
  );

  /// Wires every read to succeed with empty/absent data.
  void stubEmptyLoad() {
    when(
      () => weight.getLatest(userId),
    ).thenAnswer((_) async => const Result.success(null));
    when(
      () => sleep.forDate(userId, today),
    ).thenAnswer((_) async => const Result.success(null));
    when(
      () => mood.forDate(userId, today),
    ).thenAnswer((_) async => const Result.success(null));
    when(
      () => symptoms.forDate(userId, today),
    ).thenAnswer((_) async => const Result.success([]));
    when(
      () => exercise.forDate(userId, today),
    ).thenAnswer((_) async => const Result.success([]));
    when(
      symptoms.types,
    ).thenAnswer((_) async => const Result.success([bloating]));
  }

  setUp(() {
    weight = MockWeightRepository();
    sleep = MockSleepRepository();
    mood = MockMoodRepository();
    symptoms = MockSymptomRepository();
    exercise = MockExerciseRepository();
  });

  group('TrackersCubit (docs/08 F5–F9)', () {
    blocTest<TrackersCubit, TrackersState>(
      'load gathers every tracker for today',
      build: () {
        when(
          () => weight.getLatest(userId),
        ).thenAnswer((_) async => Result.success(weightEntry));
        when(
          () => sleep.forDate(userId, today),
        ).thenAnswer((_) async => const Result.success(null));
        when(
          () => mood.forDate(userId, today),
        ).thenAnswer((_) async => const Result.success(null));
        when(
          () => symptoms.forDate(userId, today),
        ).thenAnswer((_) async => const Result.success([]));
        when(
          () => exercise.forDate(userId, today),
        ).thenAnswer((_) async => const Result.success([]));
        when(
          symptoms.types,
        ).thenAnswer((_) async => const Result.success([bloating]));
        return build();
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        const TrackersState(),
        TrackersState(
          loading: false,
          latestWeight: weightEntry,
          symptomTypes: const [bloating],
        ),
      ],
    );

    blocTest<TrackersCubit, TrackersState>(
      'load flags an error when a read fails',
      build: () {
        stubEmptyLoad();
        when(() => weight.getLatest(userId)).thenAnswer(
          (_) async => const Result.failure(DatabaseFailure('boom')),
        );
        return build();
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        const TrackersState(),
        const TrackersState(
          loading: false,
          symptomTypes: [bloating],
          error: true,
        ),
      ],
    );

    blocTest<TrackersCubit, TrackersState>(
      'logWeight writes then reloads',
      build: () {
        stubEmptyLoad();
        when(
          () => weight.addEntry(userId: userId, weightKg: 71),
        ).thenAnswer((_) async => Result.success(weightEntry));
        return build();
      },
      act: (cubit) => cubit.logWeight(71),
      verify: (_) {
        verify(() => weight.addEntry(userId: userId, weightKg: 71)).called(1);
        verify(() => weight.getLatest(userId)).called(1);
      },
    );

    test('logWeight returns false and skips reload on failure', () async {
      when(
        () => weight.addEntry(userId: userId, weightKg: 71),
      ).thenAnswer((_) async => const Result.failure(DatabaseFailure('boom')));
      final ok = await build().logWeight(71);
      expect(ok, isFalse);
      verifyNever(() => weight.getLatest(userId));
    });

    test('logSleep forwards duration and quality', () async {
      stubEmptyLoad();
      when(
        () => sleep.add(userId: userId, durationMin: 450, quality: 4),
      ).thenAnswer(
        (_) async => Result.success(
          SleepEntry(
            id: 's1',
            userId: userId,
            durationMin: 450,
            quality: 4,
            loggedAt: DateTime.utc(2026, 7, 21),
            localDate: today,
          ),
        ),
      );
      final ok = await build().logSleep(durationMin: 450, quality: 4);
      expect(ok, isTrue);
      verify(
        () => sleep.add(userId: userId, durationMin: 450, quality: 4),
      ).called(1);
    });

    test('logMood forwards mood and note', () async {
      stubEmptyLoad();
      when(() => mood.add(userId: userId, mood: 5, note: 'great')).thenAnswer(
        (_) async => Result.success(
          MoodEntry(
            id: 'm1',
            userId: userId,
            mood: 5,
            note: 'great',
            loggedAt: DateTime.utc(2026, 7, 21),
            localDate: today,
          ),
        ),
      );
      final ok = await build().logMood(mood: 5, note: 'great');
      expect(ok, isTrue);
      verify(() => mood.add(userId: userId, mood: 5, note: 'great')).called(1);
    });

    test('logSymptom forwards type, severity and note', () async {
      stubEmptyLoad();
      when(
        () => symptoms.add(
          userId: userId,
          symptomTypeId: 'st-bloating',
          severity: 3,
        ),
      ).thenAnswer(
        (_) async => Result.success(
          SymptomEntry(
            id: 'sy1',
            userId: userId,
            type: bloating,
            severity: 3,
            loggedAt: DateTime.utc(2026, 7, 21),
            localDate: today,
          ),
        ),
      );
      final ok = await build().logSymptom(
        symptomTypeId: 'st-bloating',
        severity: 3,
      );
      expect(ok, isTrue);
    });

    test('logExercise forwards activity and options', () async {
      stubEmptyLoad();
      when(
        () => exercise.add(
          userId: userId,
          activity: 'Run',
          durationMin: 30,
          intensity: ExerciseIntensity.vigorous,
          energyKcal: 300,
        ),
      ).thenAnswer(
        (_) async => Result.success(
          ExerciseEntry(
            id: 'e1',
            userId: userId,
            activity: 'Run',
            durationMin: 30,
            intensity: ExerciseIntensity.vigorous,
            energyKcal: 300,
            loggedAt: DateTime.utc(2026, 7, 21),
            localDate: today,
          ),
        ),
      );
      final ok = await build().logExercise(
        activity: 'Run',
        durationMin: 30,
        intensity: ExerciseIntensity.vigorous,
        energyKcal: 300,
      );
      expect(ok, isTrue);
    });
  });
}
