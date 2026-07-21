import 'package:flutter_test/flutter_test.dart';
import 'package:life_ledger/core/database/app_database.dart';
import 'package:life_ledger/core/error/failure.dart';
import 'package:life_ledger/core/time/clock.dart';
import 'package:life_ledger/features/mood/infrastructure/mood_repository_impl.dart';

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

  MoodRepositoryImpl repo(DateTime now) =>
      MoodRepositoryImpl(db: db, clock: FixedClock(now), ids: ids);

  group('MoodRepositoryImpl (docs/04 §4.5)', () {
    test('add stamps local_date and stores note', () async {
      final entry = (await repo(
        DateTime(2026, 7, 21, 20),
      ).add(userId: userId, mood: 4, note: 'good day')).valueOrNull!;
      expect(entry.localDate, '2026-07-21');
      expect(entry.mood, 4);
      expect(entry.note, 'good day');
    });

    test('rejects mood out of range', () async {
      final result = await repo(
        DateTime.utc(2026, 7, 21),
      ).add(userId: userId, mood: 0);
      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('forDate returns the newest check-in', () async {
      await repo(DateTime.utc(2026, 7, 21, 9)).add(userId: userId, mood: 2);
      await repo(DateTime.utc(2026, 7, 21, 18)).add(userId: userId, mood: 5);
      final entry = (await repo(
        DateTime.utc(2026, 7, 21, 20),
      ).forDate(userId, '2026-07-21')).valueOrNull;
      expect(entry!.mood, 5);
    });

    test('forDate is null when nothing logged', () async {
      final entry = (await repo(
        DateTime.utc(2026, 7, 21),
      ).forDate(userId, '2026-07-21')).valueOrNull;
      expect(entry, isNull);
    });
  });
}
