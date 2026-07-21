import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:life_ledger/core/time/clock.dart';
import 'package:life_ledger/features/exercise/domain/exercise_entry.dart';
import 'package:life_ledger/features/mood/domain/mood_entry.dart';
import 'package:life_ledger/features/sleep/domain/sleep_entry.dart';
import 'package:life_ledger/features/symptoms/domain/symptom.dart';
import 'package:life_ledger/features/weight/domain/entities/weight_entry.dart';
import 'package:life_ledger/features/weight/domain/repositories/weight_repository.dart';

/// Today's tracker snapshot for the Trackers page (docs/08 F5–F9).
class TrackersState extends Equatable {
  /// Creates a state.
  const TrackersState({
    this.loading = true,
    this.latestWeight,
    this.sleep,
    this.mood,
    this.symptoms = const [],
    this.exercises = const [],
    this.symptomTypes = const [],
    this.error = false,
  });

  /// Whether today's data is loading.
  final bool loading;

  /// Most recent weight reading, or null.
  final WeightEntry? latestWeight;

  /// Today's sleep entry, or null.
  final SleepEntry? sleep;

  /// Today's latest mood, or null.
  final MoodEntry? mood;

  /// Today's symptom entries, newest first.
  final List<SymptomEntry> symptoms;

  /// Today's exercise entries, newest first.
  final List<ExerciseEntry> exercises;

  /// Available symptom types (seeded + custom).
  final List<SymptomType> symptomTypes;

  /// Whether the last load failed.
  final bool error;

  /// Copy with updates.
  TrackersState copyWith({
    bool? loading,
    WeightEntry? latestWeight,
    SleepEntry? sleep,
    MoodEntry? mood,
    List<SymptomEntry>? symptoms,
    List<ExerciseEntry>? exercises,
    List<SymptomType>? symptomTypes,
    bool? error,
  }) {
    return TrackersState(
      loading: loading ?? this.loading,
      latestWeight: latestWeight ?? this.latestWeight,
      sleep: sleep ?? this.sleep,
      mood: mood ?? this.mood,
      symptoms: symptoms ?? this.symptoms,
      exercises: exercises ?? this.exercises,
      symptomTypes: symptomTypes ?? this.symptomTypes,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
    loading,
    latestWeight,
    sleep,
    mood,
    symptoms,
    exercises,
    symptomTypes,
    error,
  ];
}

/// Drives the Trackers page: loads today's weight, sleep, mood, symptoms and
/// exercise, and logs new entries (docs/08 F5–F9). Each log reloads so the
/// page always reflects persisted state.
class TrackersCubit extends Cubit<TrackersState> {
  /// Creates the cubit.
  TrackersCubit({
    required WeightRepository weight,
    required SleepRepository sleep,
    required MoodRepository mood,
    required SymptomRepository symptoms,
    required ExerciseRepository exercise,
    required Clock clock,
    required String userId,
  }) : _weight = weight,
       _sleep = sleep,
       _mood = mood,
       _symptoms = symptoms,
       _exercise = exercise,
       _clock = clock,
       _userId = userId,
       super(const TrackersState());

  final WeightRepository _weight;
  final SleepRepository _sleep;
  final MoodRepository _mood;
  final SymptomRepository _symptoms;
  final ExerciseRepository _exercise;
  final Clock _clock;
  final String _userId;

  /// Loads every tracker for today.
  Future<void> load() async {
    emit(state.copyWith(loading: true, error: false));
    final today = _clock.localDate();
    final weight = await _weight.getLatest(_userId);
    final sleep = await _sleep.forDate(_userId, today);
    final mood = await _mood.forDate(_userId, today);
    final symptoms = await _symptoms.forDate(_userId, today);
    final exercises = await _exercise.forDate(_userId, today);
    final types = await _symptoms.types();

    final anyFailed =
        weight.isFailure ||
        sleep.isFailure ||
        mood.isFailure ||
        symptoms.isFailure ||
        exercises.isFailure ||
        types.isFailure;

    emit(
      TrackersState(
        loading: false,
        latestWeight: weight.valueOrNull,
        sleep: sleep.valueOrNull,
        mood: mood.valueOrNull,
        symptoms: symptoms.valueOrNull ?? const [],
        exercises: exercises.valueOrNull ?? const [],
        symptomTypes: types.valueOrNull ?? const [],
        error: anyFailed,
      ),
    );
  }

  /// Logs a weight reading and reloads. Returns true on success.
  Future<bool> logWeight(double weightKg) async {
    final result = await _weight.addEntry(userId: _userId, weightKg: weightKg);
    if (result.isSuccess) await load();
    return result.isSuccess;
  }

  /// Logs sleep and reloads. Returns true on success.
  Future<bool> logSleep({required int durationMin, int? quality}) async {
    final result = await _sleep.add(
      userId: _userId,
      durationMin: durationMin,
      quality: quality,
    );
    if (result.isSuccess) await load();
    return result.isSuccess;
  }

  /// Logs a mood check-in and reloads. Returns true on success.
  Future<bool> logMood({required int mood, String? note}) async {
    final result = await _mood.add(userId: _userId, mood: mood, note: note);
    if (result.isSuccess) await load();
    return result.isSuccess;
  }

  /// Logs a symptom and reloads. Returns true on success.
  Future<bool> logSymptom({
    required String symptomTypeId,
    required int severity,
    String? note,
  }) async {
    final result = await _symptoms.add(
      userId: _userId,
      symptomTypeId: symptomTypeId,
      severity: severity,
      note: note,
    );
    if (result.isSuccess) await load();
    return result.isSuccess;
  }

  /// Logs an exercise session and reloads. Returns true on success.
  Future<bool> logExercise({
    required String activity,
    required int durationMin,
    ExerciseIntensity? intensity,
    double? energyKcal,
  }) async {
    final result = await _exercise.add(
      userId: _userId,
      activity: activity,
      durationMin: durationMin,
      intensity: intensity,
      energyKcal: energyKcal,
    );
    if (result.isSuccess) await load();
    return result.isSuccess;
  }
}
