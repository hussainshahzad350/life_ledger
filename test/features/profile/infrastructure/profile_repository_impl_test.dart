import 'package:flutter_test/flutter_test.dart';
import 'package:life_ledger/core/database/app_database.dart';
import 'package:life_ledger/core/health/health_types.dart';
import 'package:life_ledger/core/time/clock.dart';
import 'package:life_ledger/features/profile/domain/entities/user_profile.dart';
import 'package:life_ledger/features/profile/infrastructure/repositories/profile_repository_impl.dart';

import '../../../support/fakes.dart';

void main() {
  late AppDatabase db;
  late ProfileRepositoryImpl repository;

  setUp(() async {
    db = await openTestDatabase();
    repository = ProfileRepositoryImpl(
      db: db,
      clock: FixedClock(DateTime.utc(2026, 7, 21, 8)),
    );
  });

  tearDown(() => db.close());

  group('ProfileRepositoryImpl (docs/04 §4.1)', () {
    final profile = UserProfile(
      id: 'p1',
      displayName: 'Maya',
      sex: Sex.female,
      birthDate: DateTime.utc(1997, 3, 2),
      heightCm: 165,
      activityLevel: ActivityLevel.veryActive,
    );

    test('null when no profile exists yet', () async {
      expect((await repository.getProfile()).valueOrNull, isNull);
    });

    test('save/read round-trip preserves every field, incl. the '
        'very_active snake_case mapping', () async {
      await repository.saveProfile(profile);
      final loaded = (await repository.getProfile()).valueOrNull!;
      expect(loaded, profile);

      final row = (await db.database.query('user_profile')).single;
      expect(row['activity_level'], 'very_active');
      expect(row['sex'], 'female');
    });

    test('updating preserves created_at and bumps updated_at', () async {
      await repository.saveProfile(profile);
      final created = (await db.database.query(
        'user_profile',
      )).single['created_at'];

      final later = ProfileRepositoryImpl(
        db: db,
        clock: FixedClock(DateTime.utc(2026, 7, 22, 9)),
      );
      await later.saveProfile(profile.copyWith(heightCm: 166));

      final row = (await db.database.query('user_profile')).single;
      expect(row['created_at'], created);
      expect(row['updated_at'], isNot(created));
      expect(row['height_cm'], 166.0);
    });
  });

  group('UserProfile.ageYearsAt', () {
    test('handles the birthday boundary correctly', () {
      final profile = UserProfile(
        id: 'p',
        birthDate: DateTime.utc(1997, 7, 22),
      );
      expect(profile.ageYearsAt(DateTime.utc(2026, 7, 21)), 28);
      expect(profile.ageYearsAt(DateTime.utc(2026, 7, 22)), 29);
    });

    test('null without a birth date', () {
      const profile = UserProfile(id: 'p');
      expect(profile.ageYearsAt(DateTime.utc(2026)), isNull);
    });
  });
}
