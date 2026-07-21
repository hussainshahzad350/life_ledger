import 'package:life_ledger/core/error/failure.dart';
import 'package:life_ledger/core/error/result.dart';
import 'package:life_ledger/core/health/bmr_tdee.dart';
import 'package:life_ledger/core/health/goals.dart' as engine;
import 'package:life_ledger/core/health/health_types.dart';
import 'package:life_ledger/core/time/clock.dart';
import 'package:life_ledger/features/goals/domain/entities/goal.dart';
import 'package:life_ledger/features/goals/domain/repositories/goal_repository.dart';
import 'package:life_ledger/features/profile/domain/entities/user_profile.dart';

/// Computes system-default goals from the profile via the M1 health engine
/// (docs/06) and persists them as versioned `system` goals (docs/08 F2,
/// FR-5).
///
/// Requires weight, height, and birth date (sex/age/height feed BMR).
/// Missing inputs surface as [ValidationFailure] — the engine never guesses
/// (docs/06 §10).
class GenerateDefaultGoals {
  /// Creates the use case.
  GenerateDefaultGoals({required GoalRepository goals, required Clock clock})
    : _goals = goals,
      _clock = clock;

  final GoalRepository _goals;
  final Clock _clock;

  /// Generates and persists calorie/protein/carb/fat/fiber/sugar/water
  /// goals. Returns the newly active goals.
  Future<Result<List<Goal>>> call({
    required UserProfile profile,
    required double weightKg,
    required WeightObjective objective,
  }) async {
    final heightCm = profile.heightCm;
    if (heightCm == null) {
      return const Result.failure(
        ValidationFailure(field: 'heightCm', reason: 'required for goals'),
      );
    }
    final age = profile.ageYearsAt(_clock.nowUtc());
    if (age == null) {
      return const Result.failure(
        ValidationFailure(field: 'birthDate', reason: 'required for goals'),
      );
    }

    // Pure engine pipeline (docs/06 Rules 1-6); any failure short-circuits.
    final bmrResult = basalMetabolicRate(
      sex: profile.sex,
      weightKg: weightKg,
      heightCm: heightCm,
      ageYears: age,
    );
    if (bmrResult.failureOrNull case final failure?) {
      return Result.failure(failure);
    }
    final tdee = totalDailyEnergyExpenditure(
      bmr: bmrResult.valueOrNull!,
      activityLevel: profile.activityLevel,
    );
    final calories = engine.calorieGoal(tdee: tdee, objective: objective);

    final proteinResult = engine.proteinGoal(
      weightKg: weightKg,
      activityLevel: profile.activityLevel,
      objective: objective,
    );
    if (proteinResult.failureOrNull case final failure?) {
      return Result.failure(failure);
    }
    final proteinG = proteinResult.valueOrNull!.value;

    final macrosResult = engine.macroGoals(
      calorieGoalKcal: calories.value,
      proteinGoalG: proteinG,
    );
    if (macrosResult.failureOrNull case final failure?) {
      return Result.failure(failure);
    }
    final macros = macrosResult.valueOrNull!;

    final waterResult = engine.waterGoalMl(weightKg: weightKg);
    if (waterResult.failureOrNull case final failure?) {
      return Result.failure(failure);
    }

    final targets = <(GoalType, double, WeightObjective?)>[
      (GoalType.calories, calories.value, objective),
      (GoalType.protein, proteinG, null),
      (GoalType.carbs, macros.carbsG, null),
      (GoalType.fat, macros.fatG, null),
      (GoalType.fiber, macros.fiberG, null),
      (GoalType.sugar, macros.sugarCeilingG, null),
      (GoalType.water, waterResult.valueOrNull!.value, null),
    ];

    final saved = <Goal>[];
    for (final (type, value, obj) in targets) {
      final result = await _goals.setGoal(
        userId: profile.id,
        type: type,
        targetValue: value,
        source: GoalSource.system,
        objective: obj,
      );
      if (result.failureOrNull case final failure?) {
        return Result.failure(failure);
      }
      saved.add(result.valueOrNull!);
    }
    return Result.success(saved);
  }
}
