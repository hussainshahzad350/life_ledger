import 'package:flutter_test/flutter_test.dart';
import 'package:life_ledger/core/database/app_database.dart';
import 'package:life_ledger/core/error/result.dart';
import 'package:life_ledger/core/time/clock.dart';
import 'package:life_ledger/features/goals/domain/entities/goal.dart';
import 'package:life_ledger/features/goals/domain/repositories/goal_repository.dart';
import 'package:life_ledger/features/insights/infrastructure/insight_context_gateway_impl.dart';

import '../../../support/fakes.dart';

class FakeGoalRepository implements GoalRepository {
  FakeGoalRepository(this._active);
  final List<Goal> _active;

  @override
  Future<Result<List<Goal>>> getActiveGoals(String userId) async =>
      Result.success(_active);

  @override
  Future<Result<Goal>> setGoal({
    required String userId,
    required GoalType type,
    required double targetValue,
    required GoalSource source,
    Object? objective,
  }) async => throw UnimplementedError();
}

void main() {
  late AppDatabase db;
  const userId = 'u1';
  final clock = FixedClock(DateTime(2026, 7, 21));

  setUp(() async {
    db = await openTestDatabase();
    await seedUser(db, userId);
  });

  tearDown(() => db.close());

  Goal goal(GoalType type, double value) => Goal(
    id: 'g-${type.name}',
    userId: userId,
    type: type,
    targetValue: value,
    source: GoalSource.system,
    effectiveFrom: DateTime(2026),
  );

  InsightContextGatewayImpl gateway({List<Goal> goals = const []}) =>
      InsightContextGatewayImpl(
        db: db,
        goals: FakeGoalRepository(goals),
        clock: clock,
      );

  Future<void> insertWater(String date, int hourUtc, double ml) {
    return db.database.insert('water_entry', <String, Object?>{
      'id': 'we-$date-$hourUtc',
      'user_id': userId,
      'logged_at': DateTime.utc(
        int.parse(date.split('-')[0]),
        int.parse(date.split('-')[1]),
        int.parse(date.split('-')[2]),
        hourUtc,
      ).millisecondsSinceEpoch,
      'local_date': date,
      'amount_ml': ml,
      'created_at': 0,
      'updated_at': 0,
    });
  }

  group('InsightContextGatewayImpl (docs/07 §3)', () {
    test('anchors today and spans the analysis window', () async {
      final ctx = (await gateway().buildContext(userId)).valueOrNull!;
      expect(ctx.today, '2026-07-21');
    });

    test('carries active protein and water goals', () async {
      final ctx = (await gateway(
        goals: [goal(GoalType.protein, 120), goal(GoalType.water, 2500)],
      ).buildContext(userId)).valueOrNull!;
      expect(ctx.proteinGoalG, 120);
      expect(ctx.waterGoalMl, 2500);
    });

    test('aggregates mood, sleep and symptoms by date', () async {
      await db.database.insert('mood_entry', <String, Object?>{
        'id': 'm1',
        'user_id': userId,
        'logged_at': 0,
        'local_date': '2026-07-20',
        'mood': 4,
        'created_at': 0,
        'updated_at': 0,
      });
      await db.database.insert('sleep_entry', <String, Object?>{
        'id': 's1',
        'user_id': userId,
        'logged_at': 0,
        'local_date': '2026-07-20',
        'duration_min': 400,
        'created_at': 0,
        'updated_at': 0,
      });
      await db.database.insert('symptom_entry', <String, Object?>{
        'id': 'sy1',
        'user_id': userId,
        'symptom_type_id': 'st-bloating',
        'logged_at': 0,
        'local_date': '2026-07-20',
        'severity': 3,
        'created_at': 0,
        'updated_at': 0,
      });

      final ctx = (await gateway().buildContext(userId)).valueOrNull!;
      expect(ctx.moodByDate['2026-07-20'], 4);
      expect(ctx.sleepMinutesByDate['2026-07-20'], 400);
      expect(ctx.symptomDates['Bloating'], contains('2026-07-20'));
      expect(ctx.loggedDates, contains('2026-07-20'));
    });

    test('groups timed water events by date with local hour', () async {
      await insertWater('2026-07-21', 9, 300);
      await insertWater('2026-07-21', 20, 250);
      final ctx = (await gateway().buildContext(userId)).valueOrNull!;
      final events = ctx.waterEventsByDate['2026-07-21']!;
      expect(events, hasLength(2));
      expect(ctx.waterMlByDate['2026-07-21'], 550);
    });

    test('excludes days outside the window', () async {
      await insertWater('2026-01-01', 9, 300); // well before the 28-day window
      final ctx = (await gateway().buildContext(userId)).valueOrNull!;
      expect(ctx.waterMlByDate.containsKey('2026-01-01'), isFalse);
    });
  });
}
