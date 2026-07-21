import 'package:equatable/equatable.dart';
import 'package:life_ledger/core/error/result.dart';

/// One mood check-in on a 1–5 ordinal scale with an optional note
/// (docs/04 §4.5, docs/08 F7).
class MoodEntry extends Equatable {
  /// Creates a mood entry.
  const MoodEntry({
    required this.id,
    required this.userId,
    required this.mood,
    this.note,
    required this.loggedAt,
    required this.localDate,
  });

  /// Row id (UUID).
  final String id;

  /// Owning profile id.
  final String userId;

  /// Mood rating 1 (low) – 5 (great).
  final int mood;

  /// Optional free-text note.
  final String? note;

  /// UTC instant of the check-in.
  final DateTime loggedAt;

  /// Local calendar day (`YYYY-MM-DD`).
  final String localDate;

  @override
  List<Object?> get props => [id, userId, mood, note, loggedAt, localDate];
}

/// Persistence for mood entries (docs/08 F7).
abstract interface class MoodRepository {
  /// Records a mood check-in.
  Future<Result<MoodEntry>> add({
    required String userId,
    required int mood,
    String? note,
  });

  /// The latest entry for [localDate], or null.
  Future<Result<MoodEntry?>> forDate(String userId, String localDate);
}
