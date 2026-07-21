import 'package:life_ledger/core/database/app_database.dart';
import 'package:life_ledger/core/error/failure.dart';
import 'package:life_ledger/core/error/result.dart';
import 'package:life_ledger/core/health/health_types.dart';
import 'package:life_ledger/core/time/clock.dart';
import 'package:life_ledger/core/utils/id_generator.dart';
import 'package:life_ledger/features/goals/domain/entities/goal.dart';
import 'package:life_ledger/features/goals/domain/repositories/goal_repository.dart';
import 'package:sqflite/sqflite.dart';

/// SQLite implementation of [GoalRepository] over the versioned `goal`
/// table (docs/04 §4.2). The close-then-insert rule runs in a single
/// transaction so no two active versions of a type can coexist.
class GoalRepositoryImpl implements GoalRepository {
  /// Creates the repository.
  GoalRepositoryImpl({
    required AppDatabase db,
    required Clock clock,
    required IdGenerator ids,
  }) : _db = db,
       _clock = clock,
       _ids = ids;

  final AppDatabase _db;
  final Clock _clock;
  final IdGenerator _ids;

  @override
  Future<Result<List<Goal>>> getActiveGoals(String userId) async {
    try {
      final rows = await _db.database.query(
        'goal',
        where: 'user_id = ? AND effective_to IS NULL AND is_deleted = 0',
        whereArgs: [userId],
        orderBy: 'type',
      );
      return Result.success(rows.map(_fromRow).toList());
    } on DatabaseException catch (e) {
      return Result.failure(DatabaseFailure('goal read failed', cause: e));
    }
  }

  @override
  Future<Result<Goal>> setGoal({
    required String userId,
    required GoalType type,
    required double targetValue,
    required GoalSource source,
    WeightObjective? objective,
  }) async {
    try {
      final now = _clock.nowUtc().millisecondsSinceEpoch;
      final goal = Goal(
        id: _ids.newId(),
        userId: userId,
        type: type,
        targetValue: targetValue,
        source: source,
        objective: objective,
        effectiveFrom: DateTime.fromMillisecondsSinceEpoch(now, isUtc: true),
      );

      await _db.database.transaction((txn) async {
        // Versioning rule (docs/04 §4.2): close, then insert — never update.
        await txn.update(
          'goal',
          {'effective_to': now, 'updated_at': now},
          where: 'user_id = ? AND type = ? AND effective_to IS NULL',
          whereArgs: [userId, type.name],
        );
        await txn.insert('goal', <String, Object?>{
          'id': goal.id,
          'user_id': userId,
          'type': type.name,
          'target_value': targetValue,
          'source': source.name,
          'objective': objective?.name,
          'effective_from': now,
          'effective_to': null,
          'created_at': now,
          'updated_at': now,
        });
      });

      return Result.success(goal);
    } on DatabaseException catch (e) {
      return Result.failure(DatabaseFailure('goal write failed', cause: e));
    }
  }

  Goal _fromRow(Map<String, Object?> row) {
    return Goal(
      id: row['id']! as String,
      userId: row['user_id']! as String,
      type: GoalType.values.byName(row['type']! as String),
      targetValue: (row['target_value']! as num).toDouble(),
      source: GoalSource.values.byName(row['source']! as String),
      objective: switch (row['objective']) {
        final String name => WeightObjective.values.byName(name),
        _ => null,
      },
      effectiveFrom: DateTime.fromMillisecondsSinceEpoch(
        row['effective_from']! as int,
        isUtc: true,
      ),
      effectiveTo: switch (row['effective_to']) {
        final int ms => DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true),
        _ => null,
      },
    );
  }
}
