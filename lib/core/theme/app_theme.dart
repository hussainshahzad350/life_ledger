import 'package:flutter/material.dart';

import 'package:life_ledger/core/theme/tokens.dart';

/// Builds the Material 3 light and dark themes from a single seed
/// (docs/05-uiux-system.md §2–§3). Both brightnesses derive from
/// [AppTokens.seedColor] so they stay in sync; dynamic color harmonization
/// arrives with the dashboard milestone.
abstract final class AppTheme {
  /// The light theme.
  static ThemeData light() => _build(Brightness.light);

  /// The dark theme.
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppTokens.seedColor,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      cardTheme: const CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppTokens.radiusMd)),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
