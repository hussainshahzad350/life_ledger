import 'package:flutter_test/flutter_test.dart';
import 'package:life_ledger/core/database/app_database.dart';
import 'package:life_ledger/core/time/clock.dart';
import 'package:life_ledger/features/food/domain/entities/food_entry.dart';
import 'package:life_ledger/features/food/domain/entities/food_item.dart';
import 'package:life_ledger/features/food/infrastructure/food_seeder.dart';
import 'package:life_ledger/features/food/infrastructure/repositories/food_repository_impl.dart';
import 'package:life_ledger/features/food/infrastructure/starter_foods.dart';

import '../../../support/fakes.dart';

void main() {
  late AppDatabase db;
  late SequentialIds ids;
  const userId = 'u1';

  FoodRepositoryImpl repo(DateTime now) =>
      FoodRepositoryImpl(db: db, clock: FixedClock(now), ids: ids);

  setUp(() async {
    db = await openTestDatabase();
    ids = SequentialIds();
    await seedUser(db, userId);
    await FoodSeeder(db).seed();
  });

  tearDown(() => db.close());

  group('FoodSeeder (docs/17 §5)', () {
    test('seeds the starter catalog and is idempotent', () async {
      final first = await FoodSeeder(db).seed(); // already seeded in setUp
      expect(first.valueOrNull, 0, reason: 'no duplicates on re-seed');
      final rows = await db.database.query('food_item');
      expect(rows.length, StarterFoods.all.length);
      expect(rows.every((r) => r['source_ref'] == 'starter-set'), isTrue);
    });
  });

  group('FoodRepositoryImpl search (docs/17 §4)', () {
    test('prefix-matches by name', () async {
      final results = (await repo(
        DateTime.utc(2026, 7, 21),
      ).search('egg')).valueOrNull!;
      expect(results.map((f) => f.name), contains('Egg'));
    });

    test('empty query prefix returns the catalog (bounded)', () async {
      final results = (await repo(
        DateTime.utc(2026, 7, 21),
      ).search('')).valueOrNull!;
      expect(results, isNotEmpty);
    });
  });

  group('FoodRepositoryImpl logging (docs/08 F3)', () {
    test(
      'logEntry derives nutrition from item × quantity (docs/04 §9)',
      () async {
        final r = repo(DateTime.utc(2026, 7, 21, 8));
        final entry = (await r.logEntry(
          userId: userId,
          foodItemId: 'sf-egg',
          quantity: 2,
          mealSlot: MealSlot.breakfast,
        )).valueOrNull!;

        expect(entry.item.name, 'Egg');
        expect(entry.quantity, 2);
        expect(entry.localDate, '2026-07-21');
        // 2 eggs × 72 kcal = 144.
        expect(entry.nutrition.calories, closeTo(144, 0.001));
        expect(entry.nutrition.proteinG, closeTo(12.6, 0.001));
      },
    );

    test('rejects non-positive quantity', () async {
      final r = repo(DateTime.utc(2026, 7, 21));
      expect(
        (await r.logEntry(
          userId: userId,
          foodItemId: 'sf-egg',
          quantity: 0,
          mealSlot: MealSlot.snack,
        )).isFailure,
        isTrue,
      );
    });

    test(
      'entriesForDate groups the timeline with correct day totals',
      () async {
        final r = repo(DateTime.utc(2026, 7, 21, 8));
        await r.logEntry(
          userId: userId,
          foodItemId: 'sf-egg',
          quantity: 2,
          mealSlot: MealSlot.breakfast,
        );
        await r.logEntry(
          userId: userId,
          foodItemId: 'sf-banana',
          quantity: 1,
          mealSlot: MealSlot.breakfast,
        );

        final entries = (await r.entriesForDate(
          userId,
          '2026-07-21',
        )).valueOrNull!;
        expect(entries, hasLength(2));
        final totalKcal = entries.fold<double>(
          0,
          (s, e) => s + e.nutrition.calories,
        );
        // 144 (eggs) + 105 (banana).
        expect(totalKcal, closeTo(249, 0.001));
      },
    );

    test('soft-delete hides an entry; restore brings it back (Undo)', () async {
      final r = repo(DateTime.utc(2026, 7, 21, 8));
      final entry = (await r.logEntry(
        userId: userId,
        foodItemId: 'sf-egg',
        quantity: 1,
        mealSlot: MealSlot.breakfast,
      )).valueOrNull!;

      await r.deleteEntry(entry.id);
      expect(
        (await r.entriesForDate(userId, '2026-07-21')).valueOrNull,
        isEmpty,
      );

      await r.restoreEntry(entry.id);
      expect(
        (await r.entriesForDate(userId, '2026-07-21')).valueOrNull,
        hasLength(1),
      );
    });

    test('edit changes quantity and re-derives nutrition', () async {
      final r = repo(DateTime.utc(2026, 7, 21, 8));
      final entry = (await r.logEntry(
        userId: userId,
        foodItemId: 'sf-egg',
        quantity: 1,
        mealSlot: MealSlot.breakfast,
      )).valueOrNull!;

      final edited = (await r.editEntry(
        entryId: entry.id,
        quantity: 3,
      )).valueOrNull!;
      expect(edited.quantity, 3);
      expect(edited.nutrition.calories, closeTo(216, 0.001));
    });

    test('recents lists distinct foods, most-recent first', () async {
      await repo(DateTime.utc(2026, 7, 21, 8)).logEntry(
        userId: userId,
        foodItemId: 'sf-egg',
        quantity: 1,
        mealSlot: MealSlot.breakfast,
      );
      await repo(DateTime.utc(2026, 7, 21, 12)).logEntry(
        userId: userId,
        foodItemId: 'sf-banana',
        quantity: 1,
        mealSlot: MealSlot.lunch,
      );
      await repo(DateTime.utc(2026, 7, 21, 13)).logEntry(
        userId: userId,
        foodItemId: 'sf-egg',
        quantity: 1,
        mealSlot: MealSlot.lunch,
      );

      final recents = (await repo(
        DateTime.utc(2026, 7, 21, 14),
      ).recents(userId)).valueOrNull!;
      expect(recents.map((f) => f.name).toList(), ['Egg', 'Banana']);
    });
  });

  group('FoodRepositoryImpl favorites', () {
    test('setFavorite surfaces the item in favorites', () async {
      final r = repo(DateTime.utc(2026, 7, 21));
      await r.setFavorite('sf-oatmeal', value: true);
      final favorites = (await r.favorites(userId)).valueOrNull!;
      expect(favorites.map((f) => f.name), contains('Oatmeal'));
    });

    test('createCustomFood stores a user food', () async {
      final r = repo(DateTime.utc(2026, 7, 21));
      final created = (await r.createCustomFood(
        const FoodItem(
          id: 'ignored',
          name: 'My Smoothie',
          servingSize: 1,
          servingUnit: 'glass',
          nutrition: Nutrition(
            calories: 180,
            proteinG: 5,
            carbsG: 35,
            fatG: 2,
            fiberG: 4,
            sugarG: 20,
          ),
        ),
      )).valueOrNull!;
      expect(created.isCustom, isTrue);
      final search = (await r.search('My Smoothie')).valueOrNull!;
      expect(search.single.name, 'My Smoothie');
    });
  });
}
