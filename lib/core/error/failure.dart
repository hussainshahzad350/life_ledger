import 'package:equatable/equatable.dart';

/// Base class for all domain-level failures.
///
/// LifeLedger uses functional error handling: infrastructure catches low-level
/// exceptions and maps them to a typed [Failure]; repositories and use cases
/// return `Result<T>` instead of throwing across layer boundaries.
/// See docs/03-architecture.md §4 (ADR-0004).
sealed class Failure extends Equatable {
  /// Creates a failure with a human-oriented [message].
  ///
  /// The [message] is developer-facing; user-facing text is localized in the
  /// presentation layer from the failure *type*, never from this string.
  const Failure(this.message, {this.cause});

  /// Developer-facing description of what went wrong.
  final String message;

  /// The underlying exception/error, when one exists. Never shown to users.
  final Object? cause;

  @override
  List<Object?> get props => [message, cause];
}

/// A database read/write/migration error (docs/03 §4.1).
final class DatabaseFailure extends Failure {
  /// Creates a database failure.
  const DatabaseFailure(super.message, {super.cause});
}

/// A domain-rule violation for a specific [field] (docs/03 §4.1).
final class ValidationFailure extends Failure {
  /// Creates a validation failure for [field] with a [reason].
  const ValidationFailure({required this.field, required this.reason})
    : super('Validation failed for "$field": $reason');

  /// The domain field that failed validation (e.g. `height_cm`).
  final String field;

  /// Why the value was rejected.
  final String reason;

  @override
  List<Object?> get props => [field, reason];
}

/// The requested entity does not exist (docs/03 §4.1).
final class NotFoundFailure extends Failure {
  /// Creates a not-found failure for [entity] with identifier [id].
  const NotFoundFailure({required this.entity, required this.id})
    : super('$entity not found: $id');

  /// The entity kind that was looked up (e.g. `FoodEntry`).
  final String entity;

  /// The identifier that produced no match.
  final String id;

  @override
  List<Object?> get props => [entity, id];
}

/// A uniqueness/consistency conflict (docs/03 §4.1).
final class ConflictFailure extends Failure {
  /// Creates a conflict failure whose [message] states the conflict.
  const ConflictFailure(super.message);
}

/// An OS permission was denied (docs/03 §4.1).
final class PermissionFailure extends Failure {
  /// Creates a permission failure for the named OS [permission].
  const PermissionFailure(this.permission)
    : super('Permission denied: $permission');

  /// The OS permission that was denied (e.g. `notifications`).
  final String permission;

  @override
  List<Object?> get props => [permission];
}

/// A backup/restore/export/import error, tagged with the failing [stage]
/// (docs/03 §4.1, docs/04 §8).
final class BackupFailure extends Failure {
  /// Creates a backup failure at [stage] (e.g. `encrypt`, `restore-validate`).
  const BackupFailure({required this.stage, super.cause})
    : super('Backup operation failed at stage: $stage');

  /// The pipeline stage that failed.
  final String stage;

  @override
  List<Object?> get props => [stage, cause];
}

/// Last-resort failure for unanticipated errors. Always logged locally
/// (docs/03 §4.1); never silently swallowed.
final class UnexpectedFailure extends Failure {
  /// Creates an unexpected failure.
  const UnexpectedFailure(super.message, {super.cause});
}
