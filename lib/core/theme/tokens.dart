import 'package:flutter/material.dart';

/// Design tokens — the only source of visual constants
/// (docs/05-uiux-system.md §2.1). Widgets never hard-code spacing, radii,
/// or colors; they reference these tokens.
abstract final class AppTokens {
  /// Brand seed color used to derive the full Material 3 [ColorScheme]
  /// in both brightnesses. A calm teal-green: health without clinical white
  /// or aggressive "fitness red".
  static const Color seedColor = Color(0xFF2E7D6B);

  // Spacing — 4pt base grid (docs/05 §2.1).

  /// 4dp spacing step.
  static const double space1 = 4;

  /// 8dp spacing step.
  static const double space2 = 8;

  /// 12dp spacing step.
  static const double space3 = 12;

  /// 16dp spacing step.
  static const double space4 = 16;

  /// 24dp spacing step.
  static const double space6 = 24;

  /// 32dp spacing step.
  static const double space8 = 32;

  // Corner radii (docs/05 §2.1).

  /// Small radius (8) — chips, small controls.
  static const double radiusSm = 8;

  /// Medium radius (12) — cards.
  static const double radiusMd = 12;

  /// Large radius (16) — sheets, dialogs.
  static const double radiusLg = 16;

  /// Minimum touch target in dp (docs/05 §7 accessibility).
  static const double minTouchTarget = 48;
}
