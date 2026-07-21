import 'package:equatable/equatable.dart';

/// One body-weight reading (docs/04 §4.5, docs/08 F5).
class WeightEntry extends Equatable {
  /// Creates an entry.
  const WeightEntry({
    required this.id,
    required this.userId,
    required this.weightKg,
    required this.loggedAt,
    required this.localDate,
  });

  /// Row id (UUID).
  final String id;

  /// Owning profile id.
  final String userId;

  /// Weight in kg (canonical metric).
  final double weightKg;

  /// UTC instant of the reading.
  final DateTime loggedAt;

  /// The user's local calendar day (`YYYY-MM-DD`, docs/04 §4.4).
  final String localDate;

  @override
  List<Object?> get props => [id, userId, weightKg, loggedAt, localDate];
}
