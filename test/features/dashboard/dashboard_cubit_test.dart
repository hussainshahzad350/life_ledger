import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_ledger/core/error/failure.dart';
import 'package:life_ledger/core/error/result.dart';
import 'package:life_ledger/features/dashboard/application/get_daily_summary.dart';
import 'package:life_ledger/features/dashboard/domain/daily_summary.dart';
import 'package:life_ledger/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:life_ledger/features/food/domain/entities/food_item.dart';
import 'package:life_ledger/features/goals/domain/entities/goal.dart';
import 'package:mocktail/mocktail.dart';

class MockGetDailySummary extends Mock implements GetDailySummary {}

DailySummary _summary() => const DailySummary(
  localDate: '2026-07-21',
  nutrition: Nutrition.zero,
  calories: MetricProgress(type: GoalType.calories, actual: 144, target: 2000),
  protein: MetricProgress(type: GoalType.protein, actual: 12, target: 100),
  water: MetricProgress(type: GoalType.water, actual: 500, target: 2000),
  latestWeightKg: 71.5,
  previousWeightKg: 72,
  healthScore: 40,
  hasGoals: true,
);

void main() {
  late MockGetDailySummary getSummary;

  setUp(() => getSummary = MockGetDailySummary());

  DashboardCubit build() =>
      DashboardCubit(getDailySummary: getSummary, userId: 'u1');

  group('DashboardCubit (docs/08 F10)', () {
    blocTest<DashboardCubit, DashboardState>(
      'load emits loading → loaded',
      build: () {
        when(
          () => getSummary(userId: 'u1'),
        ).thenAnswer((_) async => Result.success(_summary()));
        return build();
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<DashboardLoading>(),
        isA<DashboardLoaded>().having(
          (s) => s.summary.healthScore,
          'score',
          40,
        ),
      ],
    );

    blocTest<DashboardCubit, DashboardState>(
      'load failure emits an error state (retry chip)',
      build: () {
        when(() => getSummary(userId: 'u1')).thenAnswer(
          (_) async => const Result.failure(DatabaseFailure('boom')),
        );
        return build();
      },
      act: (cubit) => cubit.load(),
      expect: () => [isA<DashboardLoading>(), isA<DashboardError>()],
    );

    blocTest<DashboardCubit, DashboardState>(
      'refresh updates without a leading loading flash',
      build: () {
        when(
          () => getSummary(userId: 'u1'),
        ).thenAnswer((_) async => Result.success(_summary()));
        return build();
      },
      act: (cubit) => cubit.refresh(),
      expect: () => [isA<DashboardLoaded>()],
    );
  });
}
