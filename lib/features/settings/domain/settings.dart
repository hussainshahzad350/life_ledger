import 'package:equatable/equatable.dart';
import 'package:life_ledger/core/error/result.dart';

/// Which theme the app renders in (docs/08 F15, FR-42).
enum ThemePreference {
  /// Follow the OS setting.
  system,

  /// Always light.
  light,

  /// Always dark.
  dark,
}

/// Measurement units the whole app follows (docs/08 F15).
enum UnitSystem {
  /// Kilograms, millilitres, centimetres.
  metric,

  /// Pounds, fluid ounces, feet/inches.
  imperial,
}

/// The user's app preferences (docs/08 F15). Reminders are **off by default**
/// (FR-34); nothing here ever touches the network.
class Settings extends Equatable {
  /// Creates settings.
  const Settings({
    this.theme = ThemePreference.system,
    this.units = UnitSystem.metric,
    this.remindersEnabled = false,
  });

  /// The theme preference.
  final ThemePreference theme;

  /// The unit system.
  final UnitSystem units;

  /// Whether local reminders are enabled (opt-in, off by default).
  final bool remindersEnabled;

  /// Copy with updates.
  Settings copyWith({
    ThemePreference? theme,
    UnitSystem? units,
    bool? remindersEnabled,
  }) {
    return Settings(
      theme: theme ?? this.theme,
      units: units ?? this.units,
      remindersEnabled: remindersEnabled ?? this.remindersEnabled,
    );
  }

  @override
  List<Object?> get props => [theme, units, remindersEnabled];
}

/// Reads and writes [Settings] (docs/08 F15).
abstract interface class SettingsRepository {
  /// Loads the current settings (defaults when unset).
  Future<Result<Settings>> load();

  /// Persists [settings].
  Future<Result<void>> save(Settings settings);
}
