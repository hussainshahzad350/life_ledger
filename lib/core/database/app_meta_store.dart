import 'package:life_ledger/core/database/app_database.dart';
import 'package:life_ledger/core/error/failure.dart';
import 'package:life_ledger/core/error/result.dart';
import 'package:sqflite/sqflite.dart';

/// Typed access to the `app_meta` key/value table (docs/04 §4.8) —
/// schema-independent app state such as onboarding completion.
class AppMetaStore {
  /// Creates the store over the shared database.
  AppMetaStore(this._db);

  final AppDatabase _db;

  /// Well-known key: `'1'` once onboarding finished or was skipped.
  static const String onboardingDoneKey = 'onboarding_done';

  /// Reads a value, null when the key is absent.
  Future<Result<String?>> read(String key) async {
    try {
      final rows = await _db.database.query(
        'app_meta',
        where: 'key = ?',
        whereArgs: [key],
      );
      return Result.success(
        rows.isEmpty ? null : rows.single['value'] as String?,
      );
    } on DatabaseException catch (e) {
      return Result.failure(DatabaseFailure('app_meta read failed', cause: e));
    }
  }

  /// Writes (upserts) a value.
  Future<Result<void>> write(String key, String value) async {
    try {
      await _db.database.insert('app_meta', {
        'key': key,
        'value': value,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      return const Result.success(null);
    } on DatabaseException catch (e) {
      return Result.failure(DatabaseFailure('app_meta write failed', cause: e));
    }
  }
}
