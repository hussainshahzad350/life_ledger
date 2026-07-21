import 'package:flutter_test/flutter_test.dart';
import 'package:life_ledger/core/error/failure.dart';
import 'package:life_ledger/core/error/result.dart';
import 'package:life_ledger/core/health/health_types.dart';
import 'package:life_ledger/core/time/clock.dart';
import 'package:life_ledger/features/goals/application/generate_default_goals.dart';
import 'package:life_ledger/features/goals/domain/entities/goal.dart';
import 'package:life_ledger/features/goals/domain/repositories/goal_repository.dart';
import 'package:life_ledger/features/profile/domain/entities/user_profile.dart';
import 'package:mocktail/mocktail.dart';

class MockGoalRepository extends Mock implements GoalRepository {}

void main() {
  late MockGoalRepository goals;
  late GenerateDefaultGoals useCase;

  // Fixed "now" makes the docs/06 worked-example profile exactly 29.
  final now = DateTime.utc(2026, 7, 21);
  final profile = UserProfile(
    id: 'u1',
    sex: Sex.female,
    birthDate: DateTime.utc(1997, 3, 2),
    heightCm: 165,
    activityLevel: ActivityLevel.moderate,
  );

  setUpAll(() {
    registerFallbackValue(GoalType.calories);
    registerFallbackValue(GoalSource.system);
    registerFallbackValue(WeightObjective.maintain);
  });

  setUp(() {
    goals = MockGoalRepository();
    useCase = GenerateDefaultGoals(goals: goals, clock: FixedClock(now));

    when(
      () => goals.setGoal(
        userId: any(named: 'userId'),
        type: any(named: 'type'),
        targetValue: any(named: 'targetValue'),
        source: any(named: 'source'),
        objective: any(named: 'objective'),
      ),
    ).thenAnswer((invocation) async {
      return Result.success(
        Goal(
          id: 'g',
          userId: invocation.namedArguments[#userId]! as String,
          type: invocation.namedArguments[#type]! as GoalType,
          targetValue: invocation.namedArguments[#targetValue]! as double,
          source: invocation.namedArguments[#source]! as GoalSource,
          objective: invocation.namedArguments[#objective] as WeightObjective?,
          effectiveFrom: now,
        ),
      );
    });
  });

  group('GenerateDefaultGoals (docs/08 F2, FR-5)', () {
    test(
      'persists the engine-computed defaults for the worked example',
      () async {
        final result = await useCase(
          profile: profile,
          weightKg: 71,
          objective: WeightObjective.maintain,
        );

        final saved = result.valueOrNull!;
        expect(saved, hasLength(7));

        double target(GoalType type) =>
            saved.singleWhere((g) => g.type == type).targetValue;

        // docs/06 worked examples: BMR 1435.25 × 1.55 = 2224.64 (maintain).
        expect(target(GoalType.calories), closeTo(2224.64, 0.01));
        // 71 kg × 1.4 (moderate) = 99.4 g.
        expect(target(GoalType.protein), closeTo(99.4, 0.01));
        // 71 kg × 33 = 2343 ml.
        expect(target(GoalType.water), closeTo(2343, 0.01));
        // Fiber: kcal/1000 × 14; sugar ceiling: kcal × 0.10 / 4.
        expect(target(GoalType.fiber), closeTo(2224.64 / 1000 * 14, 0.01));
        expect(target(GoalType.sugar), closeTo(2224.64 * 0.10 / 4, 0.01));

        // All seven are system goals; calories carries the objective.
        expect(saved.every((g) => g.source == GoalSource.system), isTrue);
        expect(
          saved.singleWhere((g) => g.type == GoalType.calories).objective,
          WeightObjective.maintain,
        );
      },
    );

    test(
      'missing height or birth date is a ValidationFailure, not a guess',
      () async {
        final noHeight = await useCase(
          profile: UserProfile(id: 'u1', birthDate: DateTime.utc(1997)),
          weightKg: 71,
          objective: WeightObjective.maintain,
        );
        expect(noHeight.failureOrNull, isA<ValidationFailure>());

        final noBirth = await useCase(
          profile: const UserProfile(id: 'u1', heightCm: 165),
          weightKg: 71,
          objective: WeightObjective.maintain,
        );
        expect(noBirth.failureOrNull, isA<ValidationFailure>());
        verifyNever(
          () => goals.setGoal(
            userId: any(named: 'userId'),
            type: any(named: 'type'),
            targetValue: any(named: 'targetValue'),
            source: any(named: 'source'),
            objective: any(named: 'objective'),
          ),
        );
      },
    );

    test('a repository failure short-circuits', () async {
      when(
        () => goals.setGoal(
          userId: any(named: 'userId'),
          type: any(named: 'type'),
          targetValue: any(named: 'targetValue'),
          source: any(named: 'source'),
          objective: any(named: 'objective'),
        ),
      ).thenAnswer(
        (_) async => const Result.failure(DatabaseFailure('disk full')),
      );

      final result = await useCase(
        profile: profile,
        weightKg: 71,
        objective: WeightObjective.maintain,
      );
      expect(result.failureOrNull, isA<DatabaseFailure>());
    });
  });
}
