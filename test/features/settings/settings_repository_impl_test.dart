import 'package:flutter_test/flutter_test.dart';
import 'package:life_ledger/core/database/app_database.dart';
import 'package:life_ledger/core/database/app_meta_store.dart';
import 'package:life_ledger/features/settings/domain/settings.dart';
import 'package:life_ledger/features/settings/infrastructure/settings_repository_impl.dart';

import '../../support/fakes.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = await openTestDatabase();
  });

  tearDown(() => db.close());

  SettingsRepositoryImpl repo() => SettingsRepositoryImpl(AppMetaStore(db));

  group('SettingsRepositoryImpl (docs/08 F15)', () {
    test('defaults when nothing is stored', () async {
      final settings = (await repo().load()).valueOrNull!;
      expect(settings.theme, ThemePreference.system);
      expect(settings.units, UnitSystem.metric);
      expect(settings.remindersEnabled, isFalse);
    });

    test('round-trips theme, units and reminders', () async {
      await repo().save(
        const Settings(
          theme: ThemePreference.dark,
          units: UnitSystem.imperial,
          remindersEnabled: true,
        ),
      );
      final settings = (await repo().load()).valueOrNull!;
      expect(settings.theme, ThemePreference.dark);
      expect(settings.units, UnitSystem.imperial);
      expect(settings.remindersEnabled, isTrue);
    });

    test('an unknown stored value falls back to the default', () async {
      await AppMetaStore(db).write(SettingsRepositoryImpl.themeKey, 'bogus');
      final settings = (await repo().load()).valueOrNull!;
      expect(settings.theme, ThemePreference.system);
    });
  });
}
