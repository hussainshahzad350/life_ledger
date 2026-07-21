import 'package:flutter_test/flutter_test.dart';
import 'package:life_ledger/core/database/app_database.dart';
import 'package:life_ledger/core/time/clock.dart';
import 'package:life_ledger/features/water/infrastructure/repositories/water_repository_impl.dart';

import '../../../support/fakes.dart';

void main() {
  late AppDatabase db;
  late SequentialIds ids;
  const userId = 'u1';

  WaterRepositoryImpl repo(DateTime now) =>
      WaterRepositoryImpl(db: db, clock: FixedClock(now), ids: ids);

  setUp(() async {
    db = await openTestDatabase();
    ids = SequentialIds();
    await seedUser(db, userId);
  });

  tearDown(() => db.close());

  group('WaterRepositoryImpl (docs/08 F4)', () {
    test('zero total for a fresh day', () async {
      final total = await repo(
        DateTime.utc(2026, 7, 21),
      ).totalForDate(userId, '2026-07-21');
      expect(total.valueOrNull, 0);
    });

    test('addWater accumulates the day total (SQL SUM)', () async {
      await repo(
        DateTime.utc(2026, 7, 21, 8),
      ).addWater(userId: userId, amountMl: 250);
      final total = (await repo(
        DateTime.utc(2026, 7, 21, 10),
      ).addWater(userId: userId, amountMl: 500)).valueOrNull!;
      expect(total, 750);
    });

    test('rejects non-positive amounts', () async {
      expect(
        (await repo(
          DateTime.utc(2026, 7, 21),
        ).addWater(userId: userId, amountMl: 0)).isFailure,
        isTrue,
      );
    });

    test('totals are scoped per local day', () async {
      await repo(
        DateTime.utc(2026, 7, 20, 8),
      ).addWater(userId: userId, amountMl: 300);
      await repo(
        DateTime.utc(2026, 7, 21, 8),
      ).addWater(userId: userId, amountMl: 500);
      final today = await repo(
        DateTime.utc(2026, 7, 21, 9),
      ).totalForDate(userId, '2026-07-21');
      expect(today.valueOrNull, 500);
    });
  });
}
