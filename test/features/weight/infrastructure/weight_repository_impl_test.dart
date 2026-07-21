import 'package:flutter_test/flutter_test.dart';
import 'package:life_ledger/core/database/app_database.dart';
import 'package:life_ledger/core/time/clock.dart';
import 'package:life_ledger/features/weight/infrastructure/repositories/weight_repository_impl.dart';

import '../../../support/fakes.dart';

void main() {
  late AppDatabase db;
  // One shared generator so repeated inserts get distinct ids (production
  // uses UUIDs; a per-call generator would collide on the PK).
  late SequentialIds ids;
  const userId = 'u1';

  setUp(() async {
    db = await openTestDatabase();
    ids = SequentialIds();
    await seedUser(db, userId);
  });

  tearDown(() => db.close());

  WeightRepositoryImpl repo(DateTime now) =>
      WeightRepositoryImpl(db: db, clock: FixedClock(now), ids: ids);

  group('WeightRepositoryImpl (docs/04 §4.5)', () {
    test('null latest for a fresh user', () async {
      final latest = await repo(DateTime.utc(2026, 7, 21)).getLatest(userId);
      expect(latest.valueOrNull, isNull);
    });

    test('addEntry stamps local_date at write time (docs/04 §4.4)', () async {
      final entry = (await repo(
        DateTime(2026, 7, 21, 23, 30),
      ).addEntry(userId: userId, weightKg: 71)).valueOrNull!;
      expect(entry.localDate, '2026-07-21');
      expect(entry.weightKg, 71);
    });

    test('getLatest returns the most recent reading', () async {
      await repo(
        DateTime.utc(2026, 7, 19, 8),
      ).addEntry(userId: userId, weightKg: 72);
      await repo(
        DateTime.utc(2026, 7, 21, 8),
      ).addEntry(userId: userId, weightKg: 71);
      final latest = (await repo(
        DateTime.utc(2026, 7, 21, 9),
      ).getLatest(userId)).valueOrNull!;
      expect(latest.weightKg, 71);
    });
  });
}
