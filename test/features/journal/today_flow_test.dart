import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_ledger/core/di/injector.dart';
import 'package:life_ledger/core/error/result.dart';
import 'package:life_ledger/core/time/clock.dart';
import 'package:life_ledger/features/food/application/food_use_cases.dart';
import 'package:life_ledger/features/food/domain/entities/food_entry.dart';
import 'package:life_ledger/features/food/domain/entities/food_item.dart';
import 'package:life_ledger/features/food/domain/repositories/food_repository.dart';
import 'package:life_ledger/features/food/infrastructure/starter_foods.dart';
import 'package:life_ledger/features/water/domain/repositories/water_repository.dart';

import '../../support/fakes.dart';
import 'today_page_harness.dart';

/// Widget-level version of the core-logging flow (docs/12 M3 DoD): open Today
/// → Quick-Add → tap a food → it appears in the timeline. Backed by in-memory
/// fakes so `pumpAndSettle` is deterministic; the on-device timed <10 s
/// variant lives in integration_test/ (nightly, docs/11 §6).
void main() {
  late _FakeFoodRepository food;
  late _FakeWaterRepository water;
  final clock = FixedClock(DateTime(2026, 7, 21, 8));

  setUp(() {
    food = _FakeFoodRepository();
    water = _FakeWaterRepository();
  });

  tearDown(getIt.reset);

  Widget harness() => todayPageHarness(
    food: food,
    water: water,
    clock: clock,
    logFoodEntry: LogFoodEntry(food),
    getDayTimeline: GetDayTimeline(food),
  );

  testWidgets('log a food from Quick-Add and see it in the timeline', (
    tester,
  ) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();
    expect(find.textContaining('Nothing logged yet'), findsOneWidget);

    await tester.tap(find.text('Add food'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Egg').first);
    await tester.pumpAndSettle();

    expect(find.text('Egg'), findsOneWidget);
    // The day-total header appears once logging happened.
    expect(find.textContaining('protein today'), findsOneWidget);
  });

  testWidgets('one-tap water increments the day total', (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.text('0.0 L today'), findsOneWidget);
    await tester.tap(find.text('+250 ml'));
    await tester.pumpAndSettle();
    // 250 ml logged: the total moved off zero.
    expect(find.text('0.0 L today'), findsNothing);
    expect(find.textContaining('L today'), findsOneWidget);
  });
}

/// A minimal in-memory [FoodRepository]: starter catalog + a growing entry
/// list. Only the methods the Today flow exercises are meaningful.
class _FakeFoodRepository implements FoodRepository {
  final List<FoodEntry> _entries = [];
  final _ids = SequentialIds();

  FoodItem _byId(String id) => StarterFoods.all.firstWhere((f) => f.id == id);

  @override
  Future<Result<List<FoodItem>>> search(String query, {int limit = 20}) async =>
      Result.success(
        StarterFoods.all
            .where((f) => f.name.toLowerCase().startsWith(query.toLowerCase()))
            .toList(),
      );

  @override
  Future<Result<List<FoodItem>>> recents(String userId, {int limit = 8}) async {
    final seen = <String>{};
    final result = <FoodItem>[];
    for (final e in _entries.reversed) {
      if (seen.add(e.item.id)) result.add(e.item);
    }
    // Fall back to the catalog so Quick-Add has something to tap first.
    if (result.isEmpty) {
      return Result.success(StarterFoods.all.take(4).toList());
    }
    return Result.success(result);
  }

  @override
  Future<Result<List<FoodItem>>> favorites(String userId) async =>
      const Result.success([]);

  @override
  Future<Result<FoodItem>> createCustomFood(FoodItem item) async =>
      Result.success(item);

  @override
  Future<Result<void>> setFavorite(
    String foodItemId, {
    required bool value,
  }) async => const Result.success(null);

  @override
  Future<Result<FoodEntry>> logEntry({
    required String userId,
    required String foodItemId,
    required double quantity,
    required MealSlot mealSlot,
    String? note,
  }) async {
    final entry = FoodEntry(
      id: _ids.newId(),
      userId: userId,
      item: _byId(foodItemId),
      quantity: quantity,
      mealSlot: mealSlot,
      loggedAt: DateTime.utc(2026, 7, 21, 8),
      localDate: '2026-07-21',
      note: note,
    );
    _entries.add(entry);
    return Result.success(entry);
  }

  @override
  Future<Result<FoodEntry>> editEntry({
    required String entryId,
    double? quantity,
    MealSlot? mealSlot,
    String? note,
  }) async => Result.success(_entries.firstWhere((e) => e.id == entryId));

  @override
  Future<Result<void>> deleteEntry(String entryId) async {
    _entries.removeWhere((e) => e.id == entryId);
    return const Result.success(null);
  }

  @override
  Future<Result<void>> restoreEntry(String entryId) async =>
      const Result.success(null);

  @override
  Future<Result<List<FoodEntry>>> entriesForDate(
    String userId,
    String localDate,
  ) async =>
      Result.success(_entries.where((e) => e.localDate == localDate).toList());

  @override
  Future<Result<Nutrition>> totalsForDate(
    String userId,
    String localDate,
  ) async {
    var total = Nutrition.zero;
    for (final e in _entries.where((e) => e.localDate == localDate)) {
      total = total + e.nutrition;
    }
    return Result.success(total);
  }
}

/// A minimal in-memory [WaterRepository].
class _FakeWaterRepository implements WaterRepository {
  double _total = 0;

  @override
  Future<Result<double>> addWater({
    required String userId,
    required double amountMl,
  }) async {
    _total += amountMl;
    return Result.success(_total);
  }

  @override
  Future<Result<double>> totalForDate(String userId, String localDate) async =>
      Result.success(_total);
}
