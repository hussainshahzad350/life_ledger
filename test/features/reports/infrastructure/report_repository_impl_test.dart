import 'package:flutter_test/flutter_test.dart';
import 'package:life_ledger/core/database/app_database.dart';
import 'package:life_ledger/core/time/clock.dart';
import 'package:life_ledger/features/goals/domain/entities/goal.dart';
import 'package:life_ledger/features/reports/domain/report_models.dart';
import 'package:life_ledger/features/reports/infrastructure/report_repository_impl.dart';

import '../../../support/fakes.dart';

void main() {
  late AppDatabase db;
  const userId = 'u1';
  final anchor = DateTime(2026, 7, 21); // a Tuesday

  setUp(() async {
    db = await openTestDatabase();
    await seedUser(db, userId);
  });

  tearDown(() => db.close());

  ReportRepositoryImpl repo() =>
      ReportRepositoryImpl(db: db, clock: FixedClock(anchor));

  Future<void> insertFoodItem(String id, double cal, double protein) {
    return db.database.insert('food_item', <String, Object?>{
      'id': id,
      'name': 'Item $id',
      'serving_size': 100.0,
      'serving_unit': 'g',
      'calories': cal,
      'protein_g': protein,
      'carbs_g': 0.0,
      'fat_g': 0.0,
      'fiber_g': 0.0,
      'sugar_g': 0.0,
      'created_at': 0,
      'updated_at': 0,
    });
  }

  Future<void> insertFoodEntry(String date, String itemId, double qty) {
    return db.database.insert('food_entry', <String, Object?>{
      'id': 'fe-$date-$itemId',
      'user_id': userId,
      'food_item_id': itemId,
      'logged_at': DateTime.parse('${date}T12:00:00Z').millisecondsSinceEpoch,
      'local_date': date,
      'meal_slot': 'lunch',
      'quantity': qty,
      'created_at': 0,
      'updated_at': 0,
    });
  }

  Future<void> insertWater(String date, double ml) {
    return db.database.insert('water_entry', <String, Object?>{
      'id': 'we-$date',
      'user_id': userId,
      'logged_at': DateTime.parse('${date}T09:00:00Z').millisecondsSinceEpoch,
      'local_date': date,
      'amount_ml': ml,
      'created_at': 0,
      'updated_at': 0,
    });
  }

  group('ReportRepositoryImpl (docs/08 F12)', () {
    test('day range yields a single point with correct aggregation', () async {
      await insertFoodItem('rice', 130, 2.7);
      await insertFoodEntry('2026-07-21', 'rice', 2); // 260 kcal, 5.4 g
      await insertWater('2026-07-21', 500);

      final summary = (await repo().summary(
        userId: userId,
        range: ReportRange.day,
      )).valueOrNull!;

      expect(summary.points, hasLength(1));
      final p = summary.points.single;
      expect(p.localDate, '2026-07-21');
      expect(p.calories, closeTo(260, 0.001));
      expect(p.proteinG, closeTo(5.4, 0.001));
      expect(p.waterMl, 500);
      expect(summary.daysLogged, 1);
    });

    test('week range spans seven days, filling gaps with zero', () async {
      await insertFoodItem('egg', 78, 6);
      await insertFoodEntry('2026-07-21', 'egg', 1);
      await insertFoodEntry('2026-07-19', 'egg', 2);

      final summary = (await repo().summary(
        userId: userId,
        range: ReportRange.week,
      )).valueOrNull!;

      expect(summary.points, hasLength(7));
      expect(summary.window.startDate, '2026-07-15');
      expect(summary.window.endDate, '2026-07-21');
      final byDate = {for (final p in summary.points) p.localDate: p};
      expect(byDate['2026-07-19']!.calories, closeTo(156, 0.001));
      expect(byDate['2026-07-20']!.calories, 0);
      expect(byDate['2026-07-21']!.calories, closeTo(78, 0.001));
      expect(summary.daysLogged, 2);
    });

    test('aggregates weight, sleep, mood, exercise and symptoms', () async {
      await db.database.insert('weight_entry', <String, Object?>{
        'id': 'w1',
        'user_id': userId,
        'logged_at': 0,
        'local_date': '2026-07-21',
        'weight_kg': 70.0,
        'created_at': 0,
        'updated_at': 0,
      });
      await db.database.insert('sleep_entry', <String, Object?>{
        'id': 's1',
        'user_id': userId,
        'logged_at': 0,
        'local_date': '2026-07-21',
        'duration_min': 420,
        'created_at': 0,
        'updated_at': 0,
      });
      await db.database.insert('mood_entry', <String, Object?>{
        'id': 'm1',
        'user_id': userId,
        'logged_at': 0,
        'local_date': '2026-07-21',
        'mood': 4,
        'created_at': 0,
        'updated_at': 0,
      });
      await db.database.insert('exercise_entry', <String, Object?>{
        'id': 'e1',
        'user_id': userId,
        'logged_at': 0,
        'local_date': '2026-07-21',
        'activity': 'Run',
        'duration_min': 30,
        'created_at': 0,
        'updated_at': 0,
      });
      await db.database.insert('symptom_entry', <String, Object?>{
        'id': 'sy1',
        'user_id': userId,
        'symptom_type_id': 'st-bloating',
        'logged_at': 0,
        'local_date': '2026-07-21',
        'severity': 2,
        'created_at': 0,
        'updated_at': 0,
      });

      final p = (await repo().summary(
        userId: userId,
        range: ReportRange.day,
      )).valueOrNull!.points.single;
      expect(p.weightKg, 70);
      expect(p.sleepMin, 420);
      expect(p.moodAvg, 4);
      expect(p.exerciseMin, 30);
      expect(p.symptomCount, 1);
    });

    test('targetFor honors the goal in force at the time (FR-8)', () async {
      // Old goal closed on the 18th; new goal active from the 18th.
      await db.database.insert('goal', <String, Object?>{
        'id': 'g-old',
        'user_id': userId,
        'type': 'calories',
        'target_value': 2000.0,
        'source': 'system',
        'effective_from': DateTime(2026, 6, 15).millisecondsSinceEpoch,
        'effective_to': DateTime(2026, 7, 18).millisecondsSinceEpoch,
        'created_at': 0,
        'updated_at': 0,
      });
      await db.database.insert('goal', <String, Object?>{
        'id': 'g-new',
        'user_id': userId,
        'type': 'calories',
        'target_value': 2200.0,
        'source': 'user',
        'effective_from': DateTime(2026, 7, 18).millisecondsSinceEpoch,
        'effective_to': null,
        'created_at': 0,
        'updated_at': 0,
      });

      final summary = (await repo().summary(
        userId: userId,
        range: ReportRange.week,
      )).valueOrNull!;

      expect(summary.targetFor(GoalType.calories, '2026-07-16'), 2000);
      expect(summary.targetFor(GoalType.calories, '2026-07-21'), 2200);
      expect(summary.targetFor(GoalType.protein, '2026-07-21'), isNull);
    });

    test('soft-deleted rows are excluded', () async {
      await insertFoodItem('cake', 400, 4);
      await insertFoodEntry('2026-07-21', 'cake', 1);
      await db.database.update(
        'food_entry',
        {'is_deleted': 1},
        where: 'id = ?',
        whereArgs: ['fe-2026-07-21-cake'],
      );

      final p = (await repo().summary(
        userId: userId,
        range: ReportRange.day,
      )).valueOrNull!.points.single;
      expect(p.calories, 0);
    });
  });
}
