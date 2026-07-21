import 'package:equatable/equatable.dart';
import 'package:life_ledger/core/health/health_types.dart';

/// The user's display unit preference (docs/02 FR-2).
enum UnitSystem {
  /// Canonical storage units (kg/cm/ml).
  metric,

  /// Imperial display (lb/ft-in/fl oz); storage stays metric (docs/04 §5).
  imperial,
}

/// The local user profile (docs/08 F1) — the minimum body data needed to
/// personalize goals. All fields except units are optional so the app is
/// usable immediately with defaults (FR-4).
class UserProfile extends Equatable {
  /// Creates a profile.
  const UserProfile({
    required this.id,
    this.displayName,
    this.sex = Sex.unspecified,
    this.birthDate,
    this.heightCm,
    this.unitSystem = UnitSystem.metric,
    this.activityLevel = ActivityLevel.sedentary,
  });

  /// Row id (UUID).
  final String id;

  /// Optional display name — never required (privacy-first).
  final String? displayName;

  /// Sex for the BMR equation (docs/06 Rule 1).
  final Sex sex;

  /// Birth date, used to derive age.
  final DateTime? birthDate;

  /// Height in cm (canonical metric).
  final double? heightCm;

  /// Preferred display units.
  final UnitSystem unitSystem;

  /// Self-reported activity level (PAL input, docs/06 Rule 2).
  final ActivityLevel activityLevel;

  /// Age in whole years at [now], or null without a birth date.
  int? ageYearsAt(DateTime now) {
    final birth = birthDate;
    if (birth == null) return null;
    var age = now.year - birth.year;
    if (now.month < birth.month ||
        (now.month == birth.month && now.day < birth.day)) {
      age--;
    }
    return age;
  }

  /// Copy with updated fields.
  UserProfile copyWith({
    String? displayName,
    Sex? sex,
    DateTime? birthDate,
    double? heightCm,
    UnitSystem? unitSystem,
    ActivityLevel? activityLevel,
  }) {
    return UserProfile(
      id: id,
      displayName: displayName ?? this.displayName,
      sex: sex ?? this.sex,
      birthDate: birthDate ?? this.birthDate,
      heightCm: heightCm ?? this.heightCm,
      unitSystem: unitSystem ?? this.unitSystem,
      activityLevel: activityLevel ?? this.activityLevel,
    );
  }

  @override
  List<Object?> get props => [
    id,
    displayName,
    sex,
    birthDate,
    heightCm,
    unitSystem,
    activityLevel,
  ];
}
