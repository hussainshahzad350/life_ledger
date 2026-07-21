import 'package:flutter_test/flutter_test.dart';
import 'package:life_ledger/core/database/app_database.dart';
import 'package:life_ledger/core/error/failure.dart';
import 'package:life_ledger/core/time/clock.dart';
import 'package:life_ledger/features/data/infrastructure/data_repository_impl.dart';

import '../../../support/fakes.dart';

void main() {
  late AppDatabase db;
  const userId = 'u1';

  DataRepositoryImpl repo() =>
      DataRepositoryImpl(db: db, clock: FixedClock(DateTime.utc(2026, 7, 21)));

  Future<int> weightCount() async {
    final rows = await db.database.query('weight_entry');
    return rows.length;
  }

  Future<void> seedWeight(String id, double kg) {
    return db.database.insert('weight_entry', <String, Object?>{
      'id': id,
      'user_id': userId,
      'logged_at': 0,
      'local_date': '2026-07-21',
      'weight_kg': kg,
      'created_at': 0,
      'updated_at': 0,
    });
  }

  setUp(() async {
    db = await openTestDatabase();
    await seedUser(db, userId);
  });

  tearDown(() => db.close());

  group('DataRepositoryImpl (docs/08 F14)', () {
    test('export → wipe → import restores the data (round-trip)', () async {
      await seedWeight('w1', 70);
      await seedWeight('w2', 69.5);

      final backup = (await repo().exportJson()).valueOrNull!;
      expect(await weightCount(), 2);

      await repo().wipeAll();
      expect(await weightCount(), 0);
      // The seeded profile is gone too — a full wipe.
      expect(await db.database.query('user_profile'), isEmpty);

      final imported = (await repo().importJson(backup)).valueOrNull!;
      expect(imported.migrated, isFalse);
      expect(await weightCount(), 2);
      final restored = await db.database.query('weight_entry', orderBy: 'id');
      expect(restored.first['weight_kg'], 70);
    });

    test(
      're-importing the same backup is idempotent (no duplicates)',
      () async {
        await seedWeight('w1', 70);
        final backup = (await repo().exportJson()).valueOrNull!;
        await repo().importJson(backup);
        await repo().importJson(backup);
        expect(await weightCount(), 1);
      },
    );

    test('export document carries the format and schema headers', () async {
      final backup = (await repo().exportJson()).valueOrNull!;
      expect(backup, contains('"formatVersion":1'));
      expect(backup, contains('"schemaVersion":'));
    });

    test('import refuses a document newer than the app', () async {
      const future = '{"formatVersion":999,"tables":{}}';
      final result = await repo().importJson(future);
      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('import rejects invalid JSON', () async {
      final result = await repo().importJson('not json {');
      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('import tolerates a missing table key', () async {
      const doc = '{"formatVersion":1,"tables":{}}';
      final result = await repo().importJson(doc);
      expect(result.valueOrNull!.rowsWritten, 0);
    });
  });
}
