import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:life_ledger/core/error/failure.dart';
import 'package:life_ledger/core/health/health_types.dart';
import 'package:life_ledger/features/goals/domain/entities/goal.dart';
import 'package:life_ledger/features/goals/domain/repositories/goal_repository.dart';

/// Goals screen states (docs/08 F2).
sealed class GoalsState extends Equatable {
  const GoalsState();

  @override
  List<Object?> get props => [];
}

/// Loading active goals.
final class GoalsLoading extends GoalsState {
  /// Creates the loading state.
  const GoalsLoading();
}

/// Active goals loaded (possibly empty — the empty state teaches setup).
final class GoalsLoaded extends GoalsState {
  /// Creates the loaded state.
  const GoalsLoaded(this.goals);

  /// Goals currently in force, one per type.
  final List<Goal> goals;

  @override
  List<Object?> get props => [goals];
}

/// Loading or saving failed.
final class GoalsError extends GoalsState {
  /// Creates the error state.
  const GoalsError(this.failure);

  /// What went wrong.
  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

/// Loads active goals and applies user overrides via the versioning rule
/// (docs/04 §4.2 — overrides are new versions flagged `user`, FR-6).
class GoalsCubit extends Cubit<GoalsState> {
  /// Creates the cubit.
  GoalsCubit({required GoalRepository repository})
    : _repository = repository,
      super(const GoalsLoading());

  final GoalRepository _repository;

  /// Loads the goals in force for [userId].
  Future<void> load(String userId) async {
    emit(const GoalsLoading());
    final result = await _repository.getActiveGoals(userId);
    result.fold(
      (failure) => emit(GoalsError(failure)),
      (goals) => emit(GoalsLoaded(goals)),
    );
  }

  /// Applies a user override for [type] and reloads.
  Future<void> override({
    required String userId,
    required GoalType type,
    required double targetValue,
    WeightObjective? objective,
  }) async {
    final result = await _repository.setGoal(
      userId: userId,
      type: type,
      targetValue: targetValue,
      source: GoalSource.user,
      objective: objective,
    );
    if (result.failureOrNull case final failure?) {
      emit(GoalsError(failure));
      return;
    }
    await load(userId);
  }
}
