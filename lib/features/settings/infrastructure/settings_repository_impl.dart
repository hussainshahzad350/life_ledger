import 'package:life_ledger/core/database/app_meta_store.dart';
import 'package:life_ledger/core/error/result.dart';
import 'package:life_ledger/features/settings/domain/settings.dart';

/// [SettingsRepository] backed by the `app_meta` key/value store (docs/04 §4.8,
/// docs/08 F15). Each preference is one well-known key; unknown/absent keys
/// fall back to the safe defaults on [Settings].
class SettingsRepositoryImpl implements SettingsRepository {
  /// Creates the repository.
  SettingsRepositoryImpl(this._meta);

  final AppMetaStore _meta;

  /// `app_meta` key for the theme preference.
  static const themeKey = 'settings_theme';

  /// `app_meta` key for the unit system.
  static const unitsKey = 'settings_units';

  /// `app_meta` key for the reminders opt-in.
  static const remindersKey = 'settings_reminders_enabled';

  @override
  Future<Result<Settings>> load() async {
    final theme = (await _meta.read(themeKey)).valueOrNull;
    final units = (await _meta.read(unitsKey)).valueOrNull;
    final reminders = (await _meta.read(remindersKey)).valueOrNull;
    return Result.success(
      Settings(
        theme: _enumOr(ThemePreference.values, theme, ThemePreference.system),
        units: _enumOr(UnitSystem.values, units, UnitSystem.metric),
        remindersEnabled: reminders == '1',
      ),
    );
  }

  @override
  Future<Result<void>> save(Settings settings) async {
    final results = [
      await _meta.write(themeKey, settings.theme.name),
      await _meta.write(unitsKey, settings.units.name),
      await _meta.write(remindersKey, settings.remindersEnabled ? '1' : '0'),
    ];
    final failure = results
        .map((r) => r.failureOrNull)
        .where((f) => f != null)
        .firstOrNull;
    return failure == null
        ? const Result.success(null)
        : Result.failure(failure);
  }

  T _enumOr<T extends Enum>(List<T> values, String? name, T fallback) {
    for (final v in values) {
      if (v.name == name) return v;
    }
    return fallback;
  }
}
