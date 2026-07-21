import 'package:flutter/material.dart';
import 'package:life_ledger/core/di/injector.dart';
import 'package:life_ledger/core/time/clock.dart';
import 'package:life_ledger/features/food/application/food_use_cases.dart';
import 'package:life_ledger/features/food/domain/repositories/food_repository.dart';
import 'package:life_ledger/features/journal/presentation/pages/today_page.dart';
import 'package:life_ledger/features/water/domain/repositories/water_repository.dart';

/// Registers the given fakes into [getIt] and returns a MaterialApp hosting
/// [TodayPage], so the page's `getIt<…>()` lookups resolve to the fakes.
/// The caller resets [getIt] in `tearDown` for isolation.
Widget todayPageHarness({
  required FoodRepository food,
  required WaterRepository water,
  required Clock clock,
  required LogFoodEntry logFoodEntry,
  required GetDayTimeline getDayTimeline,
  String userId = 'u1',
}) {
  getIt
    ..registerSingleton<Clock>(clock)
    ..registerSingleton<FoodRepository>(food)
    ..registerSingleton<WaterRepository>(water)
    ..registerSingleton<LogFoodEntry>(logFoodEntry)
    ..registerSingleton<GetDayTimeline>(getDayTimeline);

  return MaterialApp(home: TodayPage(userId: userId));
}
