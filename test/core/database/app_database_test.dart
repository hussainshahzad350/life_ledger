import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_ledger/core/database/app_database.dart';
import 'package:life_ledger/core/logging/app_logger.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Database tests run against **real SQLite** off-device via
/// `sqflite_common_ffi` (docs/11 §2) — constraints, foreign keys, and
/// indexes are exercised for real, not mocked.
void main() {
  setUpAll(sqfliteFfiInit);

  AppDatabase newDb() => AppDatabase(
    logger: const ConsoleLogger(),
    factory: databaseFactoryFfi,
    path: inMemoryDatabasePath,
  );

  group('AppDatabase v1 schema', () {
    late AppDatabase appDb;

    setUp(() async {
      appDb = newDb();
      await appDb.open();
    });

    tearDown(() => appDb.close());

    test('opens at the current schema version', () async {
      final rows = await appDb.database.rawQuery('PRAGMA user_version');
      expect(rows.first.values.first, AppDatabase.schemaVersion);
    });

    test('creates all v1 tables', () async {
      final rows = await appDb.database.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table'",
      );
      final tables = rows.map((r) => r['name']).toSet();
      const expected = {
        'user_profile',
        'goal',
        'food_item',
        'food_entry',
        'water_entry',
        'weight_entry',
        'sleep_entry',
        'mood_entry',
        'symptom_type',
        'symptom_entry',
        'exercise_entry',
        'insight',
        'app_meta',
      };
      expect(
        tables.containsAll(expected),
        isTrue,
        reason: 'missing: ${expected.difference(tables.cast())}',
      );
    });

    test('creates the hot-path indexes (docs/04 §6)', () async {
      final rows = await appDb.database.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'index' "
        "AND name LIKE 'idx_%'",
      );
      final indexes = rows.map((r) => r['name']).toSet();
      const expected = {
        'idx_food_entry_user_date',
        'idx_food_entry_logged',
        'idx_water_user_date',
        'idx_weight_user_date',
        'idx_sleep_user_date',
        'idx_mood_user_date',
        'idx_symptom_user_date',
        'idx_exercise_user_date',
        'idx_goal_user_type_active',
        'idx_food_item_name',
        'idx_insight_user_period',
      };
      expect(
        indexes.containsAll(expected),
        isTrue,
        reason: 'missing: ${expected.difference(indexes.cast())}',
      );
    });

    test('foreign keys are enforced on the connection (NFR-12)', () async {
      // food_entry referencing a nonexistent user must be rejected.
      expect(
        () => appDb.database.insert('food_entry', <String, Object?>{
          'id': 'fe-1',
          'user_id': 'no-such-user',
          'food_item_id': 'no-such-food',
          'logged_at': 0,
          'local_date': '2026-07-21',
          'meal_slot': 'breakfast',
          'quantity': 1.0,
          'created_at': 0,
          'updated_at': 0,
        }),
        throwsA(isA<DatabaseException>()),
      );
    });

    test(
      'CHECK constraints reject out-of-domain values (docs/04 §11)',
      () async {
        // Weight of 0 violates weight_kg > 0.
        await appDb.database.insert('user_profile', <String, Object?>{
          'id': 'u1',
          'created_at': 0,
          'updated_at': 0,
        });
        expect(
          () => appDb.database.insert('weight_entry', <String, Object?>{
            'id': 'w1',
            'user_id': 'u1',
            'logged_at': 0,
            'local_date': '2026-07-21',
            'weight_kg': 0.0,
            'created_at': 0,
            'updated_at': 0,
          }),
          throwsA(isA<DatabaseException>()),
        );
        // Mood outside 1..5 is rejected.
        expect(
          () => appDb.database.insert('mood_entry', <String, Object?>{
            'id': 'm1',
            'user_id': 'u1',
            'logged_at': 0,
            'local_date': '2026-07-21',
            'mood': 6,
            'created_at': 0,
            'updated_at': 0,
          }),
          throwsA(isA<DatabaseException>()),
        );
      },
    );

    test('valid rows insert and read back', () async {
      final db = appDb.database;
      await db.insert('user_profile', <String, Object?>{
        'id': 'u1',
        'sex': 'female',
        'height_cm': 165.0,
        'unit_system': 'metric',
        'activity_level': 'moderate',
        'created_at': 1,
        'updated_at': 1,
      });
      await db.insert('weight_entry', <String, Object?>{
        'id': 'w1',
        'user_id': 'u1',
        'logged_at': 1,
        'local_date': '2026-07-21',
        'weight_kg': 71.0,
        'created_at': 1,
        'updated_at': 1,
      });
      final rows = await db.query(
        'weight_entry',
        where: 'user_id = ? AND local_date = ?',
        whereArgs: ['u1', '2026-07-21'],
      );
      expect(rows, hasLength(1));
      expect(rows.first['weight_kg'], 71.0);
      expect(rows.first['is_deleted'], 0);
      expect(rows.first['sync_status'], 'local');
    });

    test('seeds the symptom_type lookup (docs/04 §4.6)', () async {
      final rows = await appDb.database.query(
        'symptom_type',
        where: 'is_custom = 0',
      );
      expect(rows.length, greaterThanOrEqualTo(9));
      expect(
        rows.map((r) => r['name']),
        containsAll(<String>['Bloating', 'Headache', 'Fatigue']),
      );
    });
  });

  group('AppDatabase lifecycle', () {
    test('database getter throws before open()', () {
      final appDb = newDb();
      expect(() => appDb.database, throwsStateError);
    });

    test('open() is idempotent', () async {
      final appDb = newDb();
      final first = await appDb.open();
      final second = await appDb.open();
      expect(identical(first, second), isTrue);
      await appDb.close();
    });

    test('downgrade is refused (docs/04 §8)', () async {
      // Simulate a DB created by a *newer* app: bump user_version above
      // the current schema on a real file, then reopen at the current version.
      final dir = await Directory.systemTemp.createTemp('life_ledger_test');
      final path = p.join(dir.path, 'downgrade.db');
      addTearDown(() => dir.delete(recursive: true));

      final newer = await databaseFactoryFfi.openDatabase(path);
      await newer.execute(
        'PRAGMA user_version = ${AppDatabase.schemaVersion + 1}',
      );
      await newer.close();

      final appDb = AppDatabase(
        logger: const ConsoleLogger(),
        factory: databaseFactoryFfi,
        path: path,
      );
      await expectLater(appDb.open(), throwsA(isA<UnsupportedError>()));
    });
  });
}
