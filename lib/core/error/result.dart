import 'package:life_ledger/core/error/failure.dart';

/// A minimal `Either`-style result type: success carrying [T] or a [Failure].
///
/// Repositories and use cases return `Future<Result<T>>` so error paths are
/// visible in signatures and exceptions never cross layer boundaries
/// (docs/03-architecture.md §4, ADR-0004). A minimal in-house type was chosen
/// over `dartz` to keep the dependency surface small (docs/10 §7).
sealed class Result<T> {
  const Result();

  /// Wraps a successful [value].
  const factory Result.success(T value) = Success<T>;

  /// Wraps a [failure].
  const factory Result.failure(Failure failure) = Err<T>;

  /// Whether this result is a [Success].
  bool get isSuccess => this is Success<T>;

  /// Whether this result is an [Err].
  bool get isFailure => this is Err<T>;

  /// Collapses the result into a single value: exactly one branch runs.
  R fold<R>(
    R Function(Failure failure) onFailure,
    R Function(T value) onSuccess,
  ) {
    return switch (this) {
      Success<T>(:final value) => onSuccess(value),
      Err<T>(:final failure) => onFailure(failure),
    };
  }

  /// Transforms the success value, passing failures through unchanged.
  Result<R> map<R>(R Function(T value) transform) {
    return switch (this) {
      Success<T>(:final value) => Result.success(transform(value)),
      Err<T>(:final failure) => Result.failure(failure),
    };
  }

  /// Chains another result-producing operation on success ("flatMap").
  Result<R> andThen<R>(Result<R> Function(T value) next) {
    return switch (this) {
      Success<T>(:final value) => next(value),
      Err<T>(:final failure) => Result.failure(failure),
    };
  }

  /// The success value, or `null` when this is a failure.
  T? get valueOrNull => switch (this) {
    Success<T>(:final value) => value,
    Err<T>() => null,
  };

  /// The failure, or `null` when this is a success.
  Failure? get failureOrNull => switch (this) {
    Success<T>() => null,
    Err<T>(:final failure) => failure,
  };
}

/// The success branch of [Result].
final class Success<T> extends Result<T> {
  /// Creates a success carrying [value].
  const Success(this.value);

  /// The successful value.
  final T value;
}

/// The failure branch of [Result].
final class Err<T> extends Result<T> {
  /// Creates a failure result carrying [failure].
  const Err(this.failure);

  /// The typed failure.
  final Failure failure;
}
