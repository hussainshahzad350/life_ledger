import 'package:flutter_test/flutter_test.dart';
import 'package:life_ledger/core/database/app_database.dart';
import 'package:life_ledger/core/error/failure.dart';
import 'package:life_ledger/core/time/clock.dart';
import 'package:life_ledger/features/exercise/domain/exercise_entry.dart';
import 'package:life_ledger/features/exercise/infrastructure/exercise_repository_impl.dart';

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

  ExerciseRepositoryImpl repo(DateTime now) =>
      ExerciseRepositoryImpl(db: db, clock: FixedClock(now), ids: ids);

  group('ExerciseRepositoryImpl (docs/04 §4.5)', () {
    test('add stores activity, intensity and energy', () async {
      final entry = (await repo(DateTime(2026, 7, 21, 18)).add(
        userId: userId,
        activity: '  Running  ',
        durationMin: 30,
        intensity: ExerciseIntensity.vigorous,
        energyKcal: 300,
      )).valueOrNull!;
      expect(entry.activity, 'Running');
      expect(entry.localDate, '2026-07-21');
      expect(entry.intensity, ExerciseIntensity.vigorous);
      expect(entry.energyKcal, 300);
    });

    test('intensity and energy are optional', () async {
      final entry = (await repo(
        DateTime.utc(2026, 7, 21),
      ).add(userId: userId, activity: 'Yoga', durationMin: 45)).valueOrNull!;
      expect(entry.intensity, isNull);
      expect(entry.energyKcal, isNull);
    });

    test('rejects empty activity', () async {
      final result = await repo(
        DateTime.utc(2026, 7, 21),
      ).add(userId: userId, activity: '   ', durationMin: 10);
      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('rejects negative duration', () async {
      final result = await repo(
        DateTime.utc(2026, 7, 21),
      ).add(userId: userId, activity: 'Walk', durationMin: -5);
      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('rejects negative energy', () async {
      final result = await repo(
        DateTime.utc(2026, 7, 21),
      ).add(userId: userId, activity: 'Walk', durationMin: 20, energyKcal: -1);
      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('forDate returns all sessions newest first', () async {
      await repo(
        DateTime.utc(2026, 7, 21, 8),
      ).add(userId: userId, activity: 'Walk', durationMin: 20);
      await repo(
        DateTime.utc(2026, 7, 21, 18),
      ).add(userId: userId, activity: 'Run', durationMin: 30);
      final entries = (await repo(
        DateTime.utc(2026, 7, 21, 20),
      ).forDate(userId, '2026-07-21')).valueOrNull!;
      expect(entries.map((e) => e.activity), ['Run', 'Walk']);
    });

    test('fromToken parses and rejects', () {
      expect(
        ExerciseIntensity.fromToken('moderate'),
        ExerciseIntensity.moderate,
      );
      expect(ExerciseIntensity.fromToken(null), isNull);
      expect(ExerciseIntensity.fromToken('nope'), isNull);
    });
  });
}
