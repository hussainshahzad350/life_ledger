import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_ledger/core/error/failure.dart';
import 'package:life_ledger/core/error/result.dart';
import 'package:life_ledger/features/goals/domain/entities/goal.dart';
import 'package:life_ledger/features/goals/domain/repositories/goal_repository.dart';
import 'package:life_ledger/features/goals/presentation/cubit/goals_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockGoalRepository extends Mock implements GoalRepository {}

void main() {
  late MockGoalRepository repository;

  final proteinGoal = Goal(
    id: 'g1',
    userId: 'u1',
    type: GoalType.protein,
    targetValue: 99.4,
    source: GoalSource.system,
    effectiveFrom: DateTime.utc(2026, 7, 21),
  );

  setUp(() => repository = MockGoalRepository());

  group('GoalsCubit (docs/08 F2)', () {
    blocTest<GoalsCubit, GoalsState>(
      'load emits loading → loaded',
      build: () {
        when(
          () => repository.getActiveGoals('u1'),
        ).thenAnswer((_) async => Result.success([proteinGoal]));
        return GoalsCubit(repository: repository);
      },
      act: (cubit) => cubit.load('u1'),
      expect: () => [
        const GoalsLoading(),
        GoalsLoaded([proteinGoal]),
      ],
    );

    blocTest<GoalsCubit, GoalsState>(
      'load failure emits a typed error state',
      build: () {
        when(() => repository.getActiveGoals('u1')).thenAnswer(
          (_) async => const Result.failure(DatabaseFailure('boom')),
        );
        return GoalsCubit(repository: repository);
      },
      act: (cubit) => cubit.load('u1'),
      expect: () => const [GoalsLoading(), GoalsError(DatabaseFailure('boom'))],
    );

    blocTest<GoalsCubit, GoalsState>(
      'override sets a user goal then reloads',
      build: () {
        when(
          () => repository.setGoal(
            userId: 'u1',
            type: GoalType.protein,
            targetValue: 120,
            source: GoalSource.user,
          ),
        ).thenAnswer((_) async => Result.success(proteinGoal));
        when(
          () => repository.getActiveGoals('u1'),
        ).thenAnswer((_) async => Result.success([proteinGoal]));
        return GoalsCubit(repository: repository);
      },
      act: (cubit) => cubit.override(
        userId: 'u1',
        type: GoalType.protein,
        targetValue: 120,
      ),
      expect: () => [
        const GoalsLoading(),
        GoalsLoaded([proteinGoal]),
      ],
      verify: (_) {
        verify(
          () => repository.setGoal(
            userId: 'u1',
            type: GoalType.protein,
            targetValue: 120,
            source: GoalSource.user,
          ),
        ).called(1);
      },
    );
  });
}
