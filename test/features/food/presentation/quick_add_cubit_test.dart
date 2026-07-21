import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_ledger/core/error/result.dart';
import 'package:life_ledger/core/time/clock.dart';
import 'package:life_ledger/features/food/application/food_use_cases.dart';
import 'package:life_ledger/features/food/domain/entities/food_entry.dart';
import 'package:life_ledger/features/food/domain/entities/food_item.dart';
import 'package:life_ledger/features/food/domain/repositories/food_repository.dart';
import 'package:life_ledger/features/food/presentation/cubit/quick_add_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockFoodRepository extends Mock implements FoodRepository {}

const _egg = FoodItem(
  id: 'sf-egg',
  name: 'Egg',
  servingSize: 1,
  servingUnit: 'piece',
  nutrition: Nutrition(
    calories: 72,
    proteinG: 6.3,
    carbsG: 0.4,
    fatG: 4.8,
    fiberG: 0,
    sugarG: 0.2,
  ),
);

FoodEntry _entry(MealSlot slot) => FoodEntry(
  id: 'e1',
  userId: 'u1',
  item: _egg,
  quantity: 1,
  mealSlot: slot,
  loggedAt: DateTime.utc(2026, 7, 21, 8),
  localDate: '2026-07-21',
);

void main() {
  late MockFoodRepository repository;
  late LogFoodEntry logFood;

  setUp(() {
    repository = MockFoodRepository();
    logFood = LogFoodEntry(repository);
    when(
      () => repository.recents(any(), limit: any(named: 'limit')),
    ).thenAnswer((_) async => const Result.success([_egg]));
    when(
      () => repository.favorites(any()),
    ).thenAnswer((_) async => const Result.success([]));
  });

  QuickAddCubit build({int hour = 8}) => QuickAddCubit(
    repository: repository,
    logFoodEntry: logFood,
    clock: FixedClock(DateTime(2026, 7, 21, hour)),
    userId: 'u1',
  );

  group('QuickAddCubit (docs/08 F3, FR-10)', () {
    test('suggestedMeal follows time of day', () {
      expect(build().suggestedMeal, MealSlot.breakfast);
      expect(build(hour: 19).suggestedMeal, MealSlot.dinner);
    });

    blocTest<QuickAddCubit, QuickAddState>(
      'load populates recents and favorites',
      build: build,
      act: (cubit) => cubit.load(),
      expect: () => [
        // leading loading state (first emit always fires), then loaded.
        isA<QuickAddState>().having((s) => s.loading, 'loading', true),
        isA<QuickAddState>().having((s) => s.loading, 'loading', false).having(
          (s) => s.recents,
          'recents',
          [_egg],
        ),
      ],
    );

    blocTest<QuickAddCubit, QuickAddState>(
      'logFood logs with the suggested meal and emits justLogged',
      build: () {
        when(
          () => repository.logEntry(
            userId: 'u1',
            foodItemId: 'sf-egg',
            quantity: 1,
            mealSlot: MealSlot.breakfast,
          ),
        ).thenAnswer((_) async => Result.success(_entry(MealSlot.breakfast)));
        return build();
      },
      act: (cubit) => cubit.logFood(_egg),
      expect: () => [
        isA<QuickAddState>().having(
          (s) => s.justLogged?.item.name,
          'justLogged',
          'Egg',
        ),
        // followed by a reload (recents refresh).
        isA<QuickAddState>().having((s) => s.loading, 'loading', false),
      ],
      verify: (_) {
        verify(
          () => repository.logEntry(
            userId: 'u1',
            foodItemId: 'sf-egg',
            quantity: 1,
            mealSlot: MealSlot.breakfast,
          ),
        ).called(1);
      },
    );

    blocTest<QuickAddCubit, QuickAddState>(
      'search with empty query clears results',
      build: build,
      act: (cubit) => cubit.search('   '),
      expect: () => [
        isA<QuickAddState>()
            .having((s) => s.query, 'query', '')
            .having((s) => s.searchResults, 'results', isEmpty),
      ],
    );

    blocTest<QuickAddCubit, QuickAddState>(
      'search delegates to the repository',
      build: () {
        when(
          () => repository.search('egg', limit: any(named: 'limit')),
        ).thenAnswer((_) async => const Result.success([_egg]));
        return build();
      },
      act: (cubit) => cubit.search('egg'),
      expect: () => [
        isA<QuickAddState>().having((s) => s.searchResults, 'results', [_egg]),
      ],
    );
  });
}
