import 'package:flutter_test/flutter_test.dart';
import 'package:life_ledger/core/database/app_database.dart';
import 'package:life_ledger/core/health/health_types.dart';
import 'package:life_ledger/core/time/clock.dart';
import 'package:life_ledger/features/goals/domain/entities/goal.dart';
import 'package:life_ledger/features/goals/infrastructure/repositories/goal_repository_impl.dart';

import '../../../support/fakes.dart';

void main() {
  late AppDatabase db;
  late GoalRepositoryImpl repository;
  const userId = 'u1';

  setUp(() async {
    db = await openTestDatabase();
    await seedUser(db, userId);
    repository = GoalRepositoryImpl(
      db: db,
      clock: FixedClock(DateTime.utc(2026, 7, 21, 8)),
      ids: SequentialIds(),
    );
  });

  tearDown(() => db.close());

  group('GoalRepositoryImpl versioning (docs/04 §4.2)', () {
    test('setGoal creates an active goal', () async {
      final result = await repository.setGoal(
        userId: userId,
        type: GoalType.protein,
        targetValue: 99.4,
        source: GoalSource.system,
      );
      final goal = result.valueOrNull!;
      expect(goal.isActive, isTrue);
      expect(goal.targetValue, 99.4);
      expect(goal.source, GoalSource.system);
    });

    test('a new version closes the old one — never updates it', () async {
      await repository.setGoal(
        userId: userId,
        type: GoalType.protein,
        targetValue: 99.4,
        source: GoalSource.system,
      );
      await repository.setGoal(
        userId: userId,
        type: GoalType.protein,
        targetValue: 120,
        source: GoalSource.user,
      );

      // Exactly one active version, and it's the user override.
      final active = (await repository.getActiveGoals(userId)).valueOrNull!;
      expect(active, hasLength(1));
      expect(active.single.targetValue, 120);
      expect(active.single.source, GoalSource.user);

      // History is preserved: two rows total, old one closed.
      final rows = await db.database.query(
        'goal',
        where: 'type = ?',
        whereArgs: ['protein'],
      );
      expect(rows, hasLength(2));
      final closed = rows.where((r) => r['effective_to'] != null).toList();
      expect(closed, hasLength(1));
      expect(closed.single['target_value'], 99.4);
    });

    test('versions of different types are independent', () async {
      await repository.setGoal(
        userId: userId,
        type: GoalType.protein,
        targetValue: 100,
        source: GoalSource.system,
      );
      await repository.setGoal(
        userId: userId,
        type: GoalType.water,
        targetValue: 2343,
        source: GoalSource.system,
      );
      final active = (await repository.getActiveGoals(userId)).valueOrNull!;
      expect(active, hasLength(2));
    });

    test('objective round-trips for calorie goals', () async {
      await repository.setGoal(
        userId: userId,
        type: GoalType.calories,
        targetValue: 1725,
        source: GoalSource.system,
        objective: WeightObjective.lose,
      );
      final active = (await repository.getActiveGoals(userId)).valueOrNull!;
      expect(active.single.objective, WeightObjective.lose);
    });

    test('empty state: no active goals for a fresh user', () async {
      final active = (await repository.getActiveGoals(userId)).valueOrNull!;
      expect(active, isEmpty);
    });
  });
}
