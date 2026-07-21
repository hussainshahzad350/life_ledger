import 'package:equatable/equatable.dart';
import 'package:life_ledger/core/error/result.dart';

/// One night's sleep (docs/04 §4.5, docs/08 F6). Duration is stored in
/// minutes; quality is an optional 1–5 rating.
class SleepEntry extends Equatable {
  /// Creates a sleep entry.
  const SleepEntry({
    required this.id,
    required this.userId,
    required this.durationMin,
    this.quality,
    required this.loggedAt,
    required this.localDate,
  });

  /// Row id (UUID).
  final String id;

  /// Owning profile id.
  final String userId;

  /// Sleep duration in minutes.
  final int durationMin;

  /// Optional quality rating 1–5.
  final int? quality;

  /// UTC instant the entry was recorded.
  final DateTime loggedAt;

  /// Local calendar day of the wake date (`YYYY-MM-DD`, docs/08 F6).
  final String localDate;

  /// Duration as whole hours and minutes for display.
  (int hours, int minutes) get hm => (durationMin ~/ 60, durationMin % 60);

  @override
  List<Object?> get props => [
    id,
    userId,
    durationMin,
    quality,
    loggedAt,
    localDate,
  ];
}

/// Persistence for sleep entries (docs/08 F6).
abstract interface class SleepRepository {
  /// Records a night's sleep.
  Future<Result<SleepEntry>> add({
    required String userId,
    required int durationMin,
    int? quality,
  });

  /// The entry for [localDate], or null if none.
  Future<Result<SleepEntry?>> forDate(String userId, String localDate);
}
