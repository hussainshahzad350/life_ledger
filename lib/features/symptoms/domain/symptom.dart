import 'package:equatable/equatable.dart';
import 'package:life_ledger/core/error/result.dart';

/// A symptom category (seeded lookup + user-added, docs/04 §4.6).
class SymptomType extends Equatable {
  /// Creates a symptom type.
  const SymptomType({
    required this.id,
    required this.name,
    this.isCustom = false,
  });

  /// Row id.
  final String id;

  /// Display name (e.g. "Bloating").
  final String name;

  /// Whether the user created this type.
  final bool isCustom;

  @override
  List<Object?> get props => [id, name, isCustom];
}

/// One logged symptom with a severity 1–5 (docs/04 §4.5, docs/08 F8).
class SymptomEntry extends Equatable {
  /// Creates a symptom entry.
  const SymptomEntry({
    required this.id,
    required this.userId,
    required this.type,
    required this.severity,
    this.note,
    required this.loggedAt,
    required this.localDate,
  });

  /// Row id (UUID).
  final String id;

  /// Owning profile id.
  final String userId;

  /// The symptom category.
  final SymptomType type;

  /// Severity 1 (mild) – 5 (severe).
  final int severity;

  /// Optional note.
  final String? note;

  /// UTC instant.
  final DateTime loggedAt;

  /// Local calendar day (`YYYY-MM-DD`).
  final String localDate;

  @override
  List<Object?> get props => [
    id,
    userId,
    type,
    severity,
    note,
    loggedAt,
    localDate,
  ];
}

/// Persistence for symptoms and their types (docs/08 F8).
abstract interface class SymptomRepository {
  /// All symptom types (seeded + custom), alphabetical.
  Future<Result<List<SymptomType>>> types();

  /// Logs a symptom of [symptomTypeId] at [severity].
  Future<Result<SymptomEntry>> add({
    required String userId,
    required String symptomTypeId,
    required int severity,
    String? note,
  });

  /// Entries for [localDate], newest first.
  Future<Result<List<SymptomEntry>>> forDate(String userId, String localDate);
}
