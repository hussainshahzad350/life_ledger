import 'package:life_ledger/core/database/app_database.dart';
import 'package:life_ledger/core/error/failure.dart';
import 'package:life_ledger/core/error/result.dart';
import 'package:life_ledger/core/health/health_types.dart';
import 'package:life_ledger/core/time/clock.dart';
import 'package:life_ledger/features/profile/domain/entities/user_profile.dart';
import 'package:life_ledger/features/profile/domain/repositories/profile_repository.dart';
import 'package:sqflite/sqflite.dart';

/// SQLite implementation of [ProfileRepository] over `user_profile`
/// (docs/04 §4.1). Maps rows ↔ entities and exceptions ↔ typed failures.
class ProfileRepositoryImpl implements ProfileRepository {
  /// Creates the repository.
  ProfileRepositoryImpl({required AppDatabase db, required Clock clock})
    : _db = db,
      _clock = clock;

  final AppDatabase _db;
  final Clock _clock;

  @override
  Future<Result<UserProfile?>> getProfile() async {
    try {
      final rows = await _db.database.query(
        'user_profile',
        where: 'is_deleted = 0',
        limit: 1,
      );
      if (rows.isEmpty) return const Result.success(null);
      return Result.success(_fromRow(rows.single));
    } on DatabaseException catch (e) {
      return Result.failure(DatabaseFailure('profile read failed', cause: e));
    }
  }

  @override
  Future<Result<UserProfile>> saveProfile(UserProfile profile) async {
    try {
      final now = _clock.nowUtc().millisecondsSinceEpoch;
      final existing = await _db.database.query(
        'user_profile',
        columns: ['id', 'created_at'],
        where: 'id = ?',
        whereArgs: [profile.id],
      );
      final row = <String, Object?>{
        'id': profile.id,
        'display_name': profile.displayName,
        'sex': profile.sex.name,
        'birth_date': profile.birthDate?.millisecondsSinceEpoch,
        'height_cm': profile.heightCm,
        'unit_system': profile.unitSystem.name,
        'activity_level': _activityCode(profile.activityLevel),
        'created_at': existing.isEmpty ? now : existing.single['created_at'],
        'updated_at': now,
      };
      await _db.database.insert(
        'user_profile',
        row,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return Result.success(profile);
    } on DatabaseException catch (e) {
      return Result.failure(DatabaseFailure('profile save failed', cause: e));
    }
  }

  UserProfile _fromRow(Map<String, Object?> row) {
    return UserProfile(
      id: row['id']! as String,
      displayName: row['display_name'] as String?,
      sex: Sex.values.byName(row['sex'] as String? ?? 'unspecified'),
      birthDate: switch (row['birth_date']) {
        final int ms => DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true),
        _ => null,
      },
      heightCm: (row['height_cm'] as num?)?.toDouble(),
      unitSystem: UnitSystem.values.byName(
        row['unit_system'] as String? ?? 'metric',
      ),
      activityLevel: _activityFromCode(
        row['activity_level'] as String? ?? 'sedentary',
      ),
    );
  }

  /// DB stores snake_case codes (docs/04 §2 enum convention); Dart uses
  /// camelCase names — mapped explicitly for `very_active`.
  static String _activityCode(ActivityLevel level) =>
      level == ActivityLevel.veryActive ? 'very_active' : level.name;

  static ActivityLevel _activityFromCode(String code) => code == 'very_active'
      ? ActivityLevel.veryActive
      : ActivityLevel.values.byName(code);
}
