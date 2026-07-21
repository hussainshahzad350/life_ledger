import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_ledger/core/di/injector.dart';
import 'package:life_ledger/core/error/result.dart';
import 'package:life_ledger/core/time/clock.dart';
import 'package:life_ledger/features/dashboard/application/get_daily_summary.dart';
import 'package:life_ledger/features/dashboard/domain/daily_summary.dart';
import 'package:life_ledger/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:life_ledger/features/food/application/food_use_cases.dart';
import 'package:life_ledger/features/food/domain/entities/food_entry.dart';
import 'package:life_ledger/features/food/domain/entities/food_item.dart';
import 'package:life_ledger/features/food/domain/repositories/food_repository.dart';
import 'package:life_ledger/features/goals/domain/entities/goal.dart';
import 'package:life_ledger/features/water/domain/repositories/water_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetDailySummary extends Mock implements GetDailySummary {}

/// Widget-level dashboard test (docs/08 F10): the five-question summary
/// renders. Backed by a mocked summary + in-memory fakes so `pumpAndSettle`
/// is deterministic (the real-DB assembly is covered in
/// get_daily_summary_test.dart).
void main() {
  late _MockGetDailySummary summary;
  const userId = 'u1';

  setUp(() {
    summary = _MockGetDailySummary();
    when(
      () => summary(userId: any(named: 'userId')),
    ).thenAnswer((_) async => const Result.success(_sample));

    final food = _FakeFoodRepository();
    getIt
      ..registerSingleton<Clock>(FixedClock(DateTime(2026, 7, 21, 8)))
      ..registerSingleton<FoodRepository>(food)
      ..registerSingleton<WaterRepository>(_FakeWaterRepository())
      ..registerSingleton<LogFoodEntry>(LogFoodEntry(food))
      ..registerSingleton<GetDayTimeline>(GetDayTimeline(food))
      ..registerSingleton<GetDailySummary>(summary);
  });

  tearDown(getIt.reset);

  testWidgets('renders the five-question summary', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: DashboardPage(userId: userId)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Health score'), findsOneWidget);
    expect(find.text('42 / 100'), findsOneWidget);
    expect(find.text('Calories'), findsOneWidget);
    expect(find.text('Protein'), findsOneWidget);
    expect(find.text('Weight'), findsOneWidget);
    expect(find.text('Add food'), findsOneWidget);
  });
}

const _sample = DailySummary(
  localDate: '2026-07-21',
  nutrition: Nutrition.zero,
  calories: MetricProgress(type: GoalType.calories, actual: 144, target: 2000),
  protein: MetricProgress(type: GoalType.protein, actual: 12, target: 100),
  water: MetricProgress(type: GoalType.water, actual: 500, target: 2000),
  latestWeightKg: 71.5,
  previousWeightKg: 72,
  healthScore: 42,
  hasGoals: true,
);

class _FakeFoodRepository implements FoodRepository {
  @override
  Future<Result<List<FoodEntry>>> entriesForDate(String u, String d) async =>
      const Result.success([]);

  @override
  Future<Result<Nutrition>> totalsForDate(String u, String d) async =>
      const Result.success(Nutrition.zero);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _FakeWaterRepository implements WaterRepository {
  @override
  Future<Result<double>> totalForDate(String u, String d) async =>
      const Result.success(0);

  @override
  Future<Result<double>> addWater({
    required String userId,
    required double amountMl,
  }) async => const Result.success(0);
}
