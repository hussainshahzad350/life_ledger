import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:life_ledger/core/error/result.dart';
import 'package:life_ledger/features/data/domain/data_repository.dart';
import 'package:life_ledger/features/notifications/domain/reminder_scheduler.dart';
import 'package:life_ledger/features/settings/domain/settings.dart';

/// State for the Settings page (docs/08 F15).
class SettingsState extends Equatable {
  /// Creates a state.
  const SettingsState({this.settings = const Settings(), this.loading = true});

  /// The current preferences.
  final Settings settings;

  /// Whether settings are loading.
  final bool loading;

  /// Copy with updates.
  SettingsState copyWith({Settings? settings, bool? loading}) => SettingsState(
    settings: settings ?? this.settings,
    loading: loading ?? this.loading,
  );

  @override
  List<Object?> get props => [settings, loading];
}

/// Drives the Settings page: preferences, reminders opt-in, and the data
/// ownership actions (docs/08 F14/F15). All operations are local and offline.
class SettingsCubit extends Cubit<SettingsState> {
  /// Creates the cubit.
  SettingsCubit({
    required SettingsRepository settings,
    required DataRepository data,
    required BackupCipher cipher,
    required ReminderScheduler reminders,
    int reminderHour = 20,
  }) : _settings = settings,
       _data = data,
       _cipher = cipher,
       _reminders = reminders,
       _reminderHour = reminderHour,
       super(const SettingsState());

  final SettingsRepository _settings;
  final DataRepository _data;
  final BackupCipher _cipher;
  final ReminderScheduler _reminders;
  final int _reminderHour;

  /// Loads persisted settings.
  Future<void> load() async {
    final result = await _settings.load();
    emit(
      SettingsState(
        settings: result.valueOrNull ?? const Settings(),
        loading: false,
      ),
    );
  }

  /// Changes the theme preference.
  Future<void> setTheme(ThemePreference theme) =>
      _update(state.settings.copyWith(theme: theme));

  /// Changes the unit system.
  Future<void> setUnits(UnitSystem units) =>
      _update(state.settings.copyWith(units: units));

  /// Toggles local reminders, scheduling or cancelling accordingly.
  Future<void> setReminders(bool enabled) async {
    await _update(state.settings.copyWith(remindersEnabled: enabled));
    if (enabled) {
      await _reminders.scheduleDaily(hour: _reminderHour, minute: 0);
    } else {
      await _reminders.cancelAll();
    }
  }

  Future<void> _update(Settings settings) async {
    emit(state.copyWith(settings: settings));
    await _settings.save(settings);
  }

  /// Produces an encrypted backup document the user can copy out (docs F14).
  Future<Result<String>> exportBackup() async {
    final plain = await _data.exportJson();
    return plain.map(_cipher.seal);
  }

  /// Restores a backup produced by [exportBackup] (idempotent by id).
  Future<Result<ImportResult>> importBackup(String sealed) async {
    final String json;
    try {
      json = _cipher.open(sealed);
    } on Object {
      return _data.importJson(sealed); // tolerate an already-plain document
    }
    final result = await _data.importJson(json);
    if (result.isSuccess) await load();
    return result;
  }

  /// Hard-deletes all data, then reloads (settings revert to defaults).
  Future<Result<void>> wipeAll() async {
    final result = await _data.wipeAll();
    if (result.isSuccess) await load();
    return result;
  }
}
