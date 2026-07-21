import 'package:flutter_test/flutter_test.dart';
import 'package:life_ledger/core/database/app_database.dart';
import 'package:life_ledger/core/error/failure.dart';
import 'package:life_ledger/core/time/clock.dart';
import 'package:life_ledger/features/symptoms/infrastructure/symptom_repository_impl.dart';

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

  SymptomRepositoryImpl repo(DateTime now) =>
      SymptomRepositoryImpl(db: db, clock: FixedClock(now), ids: ids);

  group('SymptomRepositoryImpl (docs/04 §4.5/§4.6)', () {
    test('types returns the seeded lookup, alphabetical', () async {
      final types = (await repo(
        DateTime.utc(2026, 7, 21),
      ).types()).valueOrNull!;
      expect(types, isNotEmpty);
      final names = types.map((t) => t.name).toList();
      final sorted = [...names]..sort();
      expect(names, sorted);
      expect(types.every((t) => t.isCustom == false), isTrue);
    });

    test('add joins the type back into the returned entry', () async {
      final entry = (await repo(DateTime(2026, 7, 21, 14)).add(
        userId: userId,
        symptomTypeId: 'st-bloating',
        severity: 3,
        note: 'after lunch',
      )).valueOrNull!;
      expect(entry.type.name, 'Bloating');
      expect(entry.severity, 3);
      expect(entry.note, 'after lunch');
      expect(entry.localDate, '2026-07-21');
    });

    test('rejects severity out of range', () async {
      final result = await repo(
        DateTime.utc(2026, 7, 21),
      ).add(userId: userId, symptomTypeId: 'st-bloating', severity: 9);
      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('forDate lists the day entries newest first', () async {
      await repo(
        DateTime.utc(2026, 7, 21, 9),
      ).add(userId: userId, symptomTypeId: 'st-headache', severity: 2);
      await repo(
        DateTime.utc(2026, 7, 21, 15),
      ).add(userId: userId, symptomTypeId: 'st-nausea', severity: 4);
      final entries = (await repo(
        DateTime.utc(2026, 7, 21, 20),
      ).forDate(userId, '2026-07-21')).valueOrNull!;
      expect(entries.map((e) => e.type.name), ['Nausea', 'Headache']);
    });
  });
}
