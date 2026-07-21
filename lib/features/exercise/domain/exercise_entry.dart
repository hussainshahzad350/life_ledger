import 'package:equatable/equatable.dart';
import 'package:life_ledger/core/error/result.dart';

/// Perceived effort of an exercise session (docs/04 §4.5).
enum ExerciseIntensity {
  /// Easy effort — a stroll, gentle stretching.
  light,

  /// Moderate effort — brisk walk, light cycling.
  moderate,

  /// Hard effort — running, HIIT.
  vigorous;

  /// Parses a stored token, or null when absent/unknown.
  static ExerciseIntensity? fromToken(String? token) {
    for (final value in ExerciseIntensity.values) {
      if (value.name == token) return value;
    }
    return null;
  }
}

/// One logged exercise session (docs/04 §4.5, docs/08 F9).
class ExerciseEntry extends Equatable {
  /// Creates an exercise entry.
  const ExerciseEntry({
    required this.id,
    required this.userId,
    required this.activity,
    required this.durationMin,
    this.intensity,
    this.energyKcal,
    required this.loggedAt,
    required this.localDate,
  });

  /// Row id (UUID).
  final String id;

  /// Owning profile id.
  final String userId;

  /// Free-text activity label (e.g. "Running", "Yoga").
  final String activity;

  /// Duration in minutes (>= 0).
  final int durationMin;

  /// Perceived intensity, when recorded.
  final ExerciseIntensity? intensity;

  /// Estimated energy burned in kilocalories, when recorded.
  final double? energyKcal;

  /// UTC instant of the session.
  final DateTime loggedAt;

  /// Local calendar day (`YYYY-MM-DD`).
  final String localDate;

  @override
  List<Object?> get props => [
    id,
    userId,
    activity,
    durationMin,
    intensity,
    energyKcal,
    loggedAt,
    localDate,
  ];
}

/// Persistence for exercise sessions (docs/08 F9).
abstract interface class ExerciseRepository {
  /// Records an exercise session.
  Future<Result<ExerciseEntry>> add({
    required String userId,
    required String activity,
    required int durationMin,
    ExerciseIntensity? intensity,
    double? energyKcal,
  });

  /// Entries for [localDate], newest first.
  Future<Result<List<ExerciseEntry>>> forDate(String userId, String localDate);
}
