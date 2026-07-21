import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_ledger/core/error/result.dart';
import 'package:life_ledger/features/data/domain/data_repository.dart';
import 'package:life_ledger/features/notifications/domain/reminder_scheduler.dart';
import 'package:life_ledger/features/settings/domain/settings.dart';
import 'package:life_ledger/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:life_ledger/features/settings/presentation/pages/settings_page.dart';

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

  @override
  Future<Result<String>> exportJson() async => const Result.success('{}');

  @override
  Future<Result<ImportResult>> importJson(String json) async =>
      const Result.success(ImportResult(rowsWritten: 0, migrated: false));

  @override
  Future<Result<void>> wipeAll() async {
    wiped = true;
    return const Result.success(null);
  }
}

void main() {
  late FakeSettingsRepository settingsRepo;
  late FakeDataRepository dataRepo;

  setUp(() {
    settingsRepo = FakeSettingsRepository();
    dataRepo = FakeDataRepository();
  });

  Future<SettingsCubit> pump(WidgetTester tester) async {
    final cubit = SettingsCubit(
      settings: settingsRepo,
      data: dataRepo,
      cipher: const IdentityBackupCipher(),
      reminders: const NoopReminderScheduler(),
    );
    await cubit.load();
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(value: cubit, child: const SettingsPage()),
      ),
    );
    await tester.pumpAndSettle();
    return cubit;
  }

  testWidgets('renders sections and the offline affirmation', (tester) async {
    await pump(tester);
    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Units'), findsOneWidget);
    expect(find.text('Daily reminder'), findsOneWidget);
    expect(find.textContaining('works fully offline'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Cloud sync'), 200);
    expect(find.text('Cloud sync'), findsOneWidget);
  });

  testWidgets('toggling the reminder switch persists the choice', (
    tester,
  ) async {
    await pump(tester);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(settingsRepo.stored.remindersEnabled, isTrue);
  });

  testWidgets('export copies a backup to the clipboard', (tester) async {
    final clips = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') clips.add(call);
        return null;
      },
    );
    await pump(tester);
    await tester.tap(find.text('Export backup'));
    await tester.pumpAndSettle();
    expect(find.text('Backup copied to clipboard'), findsOneWidget);
    expect(clips, isNotEmpty);
  });

  testWidgets('import restores from pasted text', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Import backup'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField),
      '{"formatVersion":1,"tables":{}}',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Restore'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Restored'), findsOneWidget);
  });

  testWidgets('delete requires typing DELETE before it wipes', (tester) async {
    await pump(tester);
    await tester.tap(find.text('Delete all data'));
    await tester.pumpAndSettle();

    // The Delete button is disabled until the confirmation text matches.
    final deleteButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Delete'),
    );
    expect(deleteButton.onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'DELETE');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(dataRepo.wiped, isTrue);
    expect(find.text('All data deleted'), findsOneWidget);
  });
}
