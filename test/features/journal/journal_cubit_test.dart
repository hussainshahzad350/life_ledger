import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_ledger/core/error/failure.dart';
import 'package:life_ledger/core/error/result.dart';
import 'package:life_ledger/core/time/clock.dart';
import 'package:life_ledger/features/food/application/food_use_cases.dart';
import 'package:life_ledger/features/food/domain/entities/food_entry.dart';
import 'package:life_ledger/features/food/domain/entities/food_item.dart';
import 'package:life_ledger/features/food/domain/repositories/food_repository.dart';
import 'package:life_ledger/features/journal/presentation/cubit/journal_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockFoodRepository extends Mock implements FoodRepository {}

FoodEntry _entry() => FoodEntry(
  id: 'e1',
  userId: 'u1',
  quantity: 1,
  mealSlot: MealSlot.breakfast,
  loggedAt: DateTime.utc(2026, 7, 21, 8),
  localDate: '2026-07-21',
  item: const FoodItem(
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
  ),
);

void main() {
  late MockFoodRepository repository;
  late GetDayTimeline getDayTimeline;

  JournalCubit build() => JournalCubit(
    repository: repository,
    getDayTimeline: getDayTimeline,
    clock: FixedClock(DateTime(2026, 7, 21, 8)),
    userId: 'u1',
  );

  setUp(() {
    repository = MockFoodRepository();
    getDayTimeline = GetDayTimeline(repository);
  });

  group('JournalCubit (docs/08 F3)', () {
    blocTest<JournalCubit, JournalState>(
      'load emits loading → loaded with the grouped timeline',
      build: () {
        when(
          () => repository.entriesForDate('u1', '2026-07-21'),
        ).thenAnswer((_) async => Result.success([_entry()]));
        return build();
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<JournalLoading>(),
        isA<JournalLoaded>().having(
          (s) => s.timeline.total.calories,
          'total kcal',
          72,
        ),
      ],
    );

    blocTest<JournalCubit, JournalState>(
      'load failure emits a typed error state',
      build: () {
        when(() => repository.entriesForDate('u1', '2026-07-21')).thenAnswer(
          (_) async => const Result.failure(DatabaseFailure('boom')),
        );
        return build();
      },
      act: (cubit) => cubit.load(),
      expect: () => [isA<JournalLoading>(), isA<JournalError>()],
    );

    blocTest<JournalCubit, JournalState>(
      'delete soft-deletes then reloads (Undo path via restore)',
      build: () {
        when(
          () => repository.deleteEntry('e1'),
        ).thenAnswer((_) async => const Result.success(null));
        when(
          () => repository.entriesForDate('u1', '2026-07-21'),
        ).thenAnswer((_) async => const Result.success([]));
        return build();
      },
      act: (cubit) => cubit.delete(_entry()),
      expect: () => [
        isA<JournalLoading>(),
        isA<JournalLoaded>().having(
          (s) => s.timeline.isEmpty,
          'empty after delete',
          isTrue,
        ),
      ],
      verify: (_) => verify(() => repository.deleteEntry('e1')).called(1),
    );
  });
}
