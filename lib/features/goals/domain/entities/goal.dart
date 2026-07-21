import 'package:equatable/equatable.dart';
import 'package:life_ledger/core/health/health_types.dart';

/// The metric a goal targets (docs/04 §4.2 `goal.type`).
enum GoalType {
  /// Daily energy (kcal).
  calories,

  /// Daily protein (g).
  protein,

  /// Daily carbohydrate (g).
  carbs,

  /// Daily fat (g).
  fat,

  /// Daily fiber (g).
  fiber,

  /// Daily added-sugar ceiling (g) — a limit, not a target.
  sugar,

  /// Daily water (ml).
  water,

  /// Target body weight (kg).
  weight,

  /// Nightly sleep (minutes).
  sleep,
}

/// Who set the goal (docs/04 §4.2): engine defaults vs. user override (FR-6).
enum GoalSource {
  /// Proposed by the health engine.
  system,

  /// Manually overridden by the user.
  user,
}

/// One versioned goal row (docs/04 §4.2).
///
/// Goals are **versioned, never edited**: changing a goal closes the current
/// row (`effectiveTo = now`) and inserts a new one, so historical reports
/// stay accurate (FR-8).
class Goal extends Equatable {
  /// Creates a goal.
  const Goal({
    required this.id,
    required this.userId,
    required this.type,
    required this.targetValue,
    required this.source,
    this.objective,
    required this.effectiveFrom,
    this.effectiveTo,
  });

  /// Row id (UUID).
  final String id;

  /// Owning profile id.
  final String userId;

  /// The metric this goal targets.
  final GoalType type;

  /// The target (unit implied by [type], docs/04 §5).
  final double targetValue;

  /// System default or user override.
  final GoalSource source;

  /// Weight objective, for calorie/weight goals only.
  final WeightObjective? objective;

  /// Start of this version's validity window.
  final DateTime effectiveFrom;

  /// End of validity; null = currently active.
  final DateTime? effectiveTo;

  /// Whether this version is the one currently in force.
  bool get isActive => effectiveTo == null;

  @override
  List<Object?> get props => [
    id,
    userId,
    type,
    targetValue,
    source,
    objective,
    effectiveFrom,
    effectiveTo,
  ];
}
