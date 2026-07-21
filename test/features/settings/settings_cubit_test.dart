import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_ledger/core/error/result.dart';
import 'package:life_ledger/features/data/domain/data_repository.dart';
import 'package:life_ledger/features/notifications/domain/reminder_scheduler.dart';
import 'package:life_ledger/features/settings/domain/settings.dart';
import 'package:life_ledger/features/settings/presentation/cubit/settings_cubit.dart';

class FakeSettingsRepository implements SettingsRepository {
  Settings stored = const Settings();

  @override
  Future<Result<Settings>> load() async => Result.success(stored);

  @override
  Future<Result<void>> save(Settings settings) async {
    stored = settings;
    return const Result.success(null);
  }
}

class FakeDataRepository implements DataRepository {
  bool wiped = false;
  String? imported;

  @override
  Future<Result<String>> exportJson() async =>
      const Result.success('{"formatVersion":1,"tables":{}}');

  @override
  Future<Result<ImportResult>> importJson(String json) async {
    imported = json;
    return const Result.success(ImportResult(rowsWritten: 3, migrated: false));
  }

  @override
  Future<Result<void>> wipeAll() async {
    wiped = true;
    return const Result.success(null);
  }
}

class RecordingScheduler implements ReminderScheduler {
  int scheduled = 0;
  int cancelled = 0;

  @override
  Future<Result<void>> scheduleDaily({
    required int hour,
    required int minute,
  }) async {
    scheduled++;
    return const Result.success(null);
  }

  @override
  Future<Result<void>> cancelAll() async {
    cancelled++;
    return const Result.success(null);
  }
}

void main() {
  late FakeSettingsRepository settings;
  late FakeDataRepository data;
  late RecordingScheduler scheduler;

  SettingsCubit build() => SettingsCubit(
    settings: settings,
    data: data,
    cipher: const IdentityBackupCipher(),
    reminders: scheduler,
  );

  setUp(() {
    settings = FakeSettingsRepository();
    data = FakeDataRepository();
    scheduler = RecordingScheduler();
  });

  group('SettingsCubit (docs/08 F14/F15)', () {
    blocTest<SettingsCubit, SettingsState>(
      'load reads persisted settings',
      build: () {
        settings.stored = const Settings(theme: ThemePreference.dark);
        return build();
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        const SettingsState(
          settings: Settings(theme: ThemePreference.dark),
          loading: false,
        ),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'setTheme persists and emits',
      build: build,
      seed: () => const SettingsState(loading: false),
      act: (cubit) => cubit.setTheme(ThemePreference.light),
      expect: () => [
        const SettingsState(
          settings: Settings(theme: ThemePreference.light),
          loading: false,
        ),
      ],
      verify: (_) => expect(settings.stored.theme, ThemePreference.light),
    );

    test('enabling reminders schedules a daily reminder', () async {
      final cubit = build();
      await cubit.setReminders(true);
      expect(settings.stored.remindersEnabled, isTrue);
      expect(scheduler.scheduled, 1);
      expect(scheduler.cancelled, 0);
    });

    test('disabling reminders cancels them', () async {
      final cubit = build();
      await cubit.setReminders(false);
      expect(scheduler.cancelled, 1);
      expect(scheduler.scheduled, 0);
    });

    test('exportBackup seals the exported JSON', () async {
      final backup = (await build().exportBackup()).valueOrNull!;
      expect(backup, contains('"formatVersion":1'));
    });

    test('importBackup delegates to the data repository', () async {
      final result = await build().importBackup(
        '{"formatVersion":1,"tables":{}}',
      );
      expect(result.valueOrNull!.rowsWritten, 3);
      expect(data.imported, isNotNull);
    });

    test('wipeAll clears data and reloads', () async {
      final cubit = build();
      final result = await cubit.wipeAll();
      expect(result.isSuccess, isTrue);
      expect(data.wiped, isTrue);
    });
  });
}
