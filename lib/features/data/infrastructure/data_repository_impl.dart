import 'dart:convert';

import 'package:life_ledger/core/database/app_database.dart';
import 'package:life_ledger/core/error/failure.dart';
import 'package:life_ledger/core/error/result.dart';
import 'package:life_ledger/core/time/clock.dart';
import 'package:life_ledger/features/data/domain/data_repository.dart';
import 'package:sqflite/sqflite.dart';

/// SQLite implementation of [DataRepository] (docs/08 F14).
///
/// Export walks [kBackupTables] into a version-headered JSON document; import
/// validates the header, refuses a newer format, and upserts every row by
/// primary key in one transaction so re-importing is idempotent (FR-39); wipe
/// clears the tables child-first inside a transaction.
class DataRepositoryImpl implements DataRepository {
  /// Creates the repository.
  DataRepositoryImpl({required AppDatabase db, required Clock clock})
    : _db = db,
      _clock = clock;

  final AppDatabase _db;
  final Clock _clock;

  @override
  Future<Result<String>> exportJson() async {
    try {
      final tables = <String, List<Map<String, Object?>>>{};
      for (final table in kBackupTables) {
        tables[table] = await _db.database.query(table);
      }
      final doc = <String, Object?>{
        'formatVersion': kBackupFormatVersion,
        'schemaVersion': AppDatabase.schemaVersion,
        'exportedAt': _clock.nowUtc().toIso8601String(),
        'tables': tables,
      };
      return Result.success(jsonEncode(doc));
    } on DatabaseException catch (e) {
      return Result.failure(DatabaseFailure('export failed', cause: e));
    }
  }

  @override
  Future<Result<ImportResult>> importJson(String json) async {
    final Map<String, Object?> doc;
    try {
      doc = jsonDecode(json) as Map<String, Object?>;
    } on FormatException catch (e) {
      return Result.failure(
        ValidationFailure(
          field: 'backup',
          reason: 'not valid JSON: ${e.message}',
        ),
      );
    }

    final formatVersion = doc['formatVersion'];
    if (formatVersion is! int) {
      return const Result.failure(
        ValidationFailure(field: 'formatVersion', reason: 'missing'),
      );
    }
    if (formatVersion > kBackupFormatVersion) {
      return const Result.failure(
        ValidationFailure(
          field: 'formatVersion',
          reason: 'backup is newer than this app; update to restore it',
        ),
      );
    }
    final tables = doc['tables'];
    if (tables is! Map) {
      return const Result.failure(
        ValidationFailure(field: 'tables', reason: 'missing'),
      );
    }

    try {
      var rowsWritten = 0;
      await _db.database.transaction((txn) async {
        for (final table in kBackupTables) {
          final rows = tables[table];
          if (rows is! List) continue;
          for (final row in rows) {
            if (row is! Map) continue;
            await txn.insert(
              table,
              row.cast<String, Object?>(),
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
            rowsWritten++;
          }
        }
      });
      return Result.success(
        ImportResult(
          rowsWritten: rowsWritten,
          migrated: formatVersion < kBackupFormatVersion,
        ),
      );
    } on DatabaseException catch (e) {
      return Result.failure(DatabaseFailure('import failed', cause: e));
    }
  }

  @override
  Future<Result<void>> wipeAll() async {
    try {
      await _db.database.transaction((txn) async {
        for (final table in kBackupTables.reversed) {
          await txn.delete(table);
        }
      });
      return const Result.success(null);
    } on DatabaseException catch (e) {
      return Result.failure(DatabaseFailure('wipe failed', cause: e));
    }
  }
}
