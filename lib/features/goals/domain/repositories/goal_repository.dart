import 'package:life_ledger/core/error/result.dart';
import 'package:life_ledger/core/health/health_types.dart';
import 'package:life_ledger/features/goals/domain/entities/goal.dart';

/// Persistence contract for versioned goals (docs/04 §4.2, docs/08 F2).
abstract interface class GoalRepository {
  /// All goals currently in force for [userId] (one per type at most).
  Future<Result<List<Goal>>> getActiveGoals(String userId);

  /// Sets a goal following the versioning rule: closes any active goal of
  /// the same [type] (`effectiveTo = now`) and inserts the new version, in
  /// one transaction. Returns the new active goal.
  Future<Result<Goal>> setGoal({
    required String userId,
    required GoalType type,
    required double targetValue,
    required GoalSource source,
    WeightObjective? objective,
  });
}
