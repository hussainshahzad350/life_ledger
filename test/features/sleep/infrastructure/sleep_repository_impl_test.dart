import 'package:flutter_test/flutter_test.dart';
import 'package:life_ledger/core/database/app_database.dart';
import 'package:life_ledger/core/error/failure.dart';
import 'package:life_ledger/core/time/clock.dart';
import 'package:life_ledger/features/sleep/infrastructure/sleep_repository_impl.dart';

import '../../../support/fakes.dart';

void main() {
  late AppDatabase db;
  late SequentialIds ids;
  const userId = 'u1';

  setUp(() async {
    db = await openTestDatabase();
    ids = SequentialIds();
    await seedUser(db, userId);
  });

  tearDown(() => db.close());

  SleepRepositoryImpl repo(DateTime now) =>
      SleepRepositoryImpl(db: db, clock: FixedClock(now), ids: ids);

  group('SleepRepositoryImpl (docs/04 §4.5)', () {
    test('add stamps local_date and stores quality', () async {
      final entry = (await repo(
        DateTime(2026, 7, 21, 7, 30),
      ).add(userId: userId, durationMin: 465, quality: 4)).valueOrNull!;
      expect(entry.localDate, '2026-07-21');
      expect(entry.durationMin, 465);
      expect(entry.quality, 4);
      expect(entry.hm, (7, 45));
    });

    test('quality is optional', () async {
      final entry = (await repo(
        DateTime.utc(2026, 7, 21),
      ).add(userId: userId, durationMin: 400)).valueOrNull!;
      expect(entry.quality, isNull);
    });

    test('rejects negative duration', () async {
      final result = await repo(
        DateTime.utc(2026, 7, 21),
      ).add(userId: userId, durationMin: -1);
      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('rejects quality out of range', () async {
      final result = await repo(
        DateTime.utc(2026, 7, 21),
      ).add(userId: userId, durationMin: 400, quality: 6);
      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('forDate returns the newest entry for the day', () async {
      await repo(
        DateTime.utc(2026, 7, 21, 6),
      ).add(userId: userId, durationMin: 400);
      await repo(
        DateTime.utc(2026, 7, 21, 7),
      ).add(userId: userId, durationMin: 500);
      final entry = (await repo(
        DateTime.utc(2026, 7, 21, 8),
      ).forDate(userId, '2026-07-21')).valueOrNull;
      expect(entry!.durationMin, 500);
    });

    test('forDate is null when nothing logged', () async {
      final entry = (await repo(
        DateTime.utc(2026, 7, 21),
      ).forDate(userId, '2026-07-21')).valueOrNull;
      expect(entry, isNull);
    });
  });
}
