import 'package:sqflite/sqflite.dart';

/// One forward-only schema migration (docs/04-database-design.md §7, ADR-0005).
///
/// Rules:
/// - Migrations are keyed by the [version] they migrate the schema **to**.
/// - A shipped migration is immutable — corrections ship as a new migration.
/// - There is no "down": destructive changes are staged across versions.
/// - Every migration must have a data-preservation test (docs/11 §3.5).
abstract interface class Migration {
  /// The schema version this migration produces.
  int get version;

  /// Human-readable description recorded in the migration ledger (docs/04 §7.1).
  String get description;

  /// Applies the migration. Runs inside the transaction sqflite provides
  /// during `onCreate`/`onUpgrade`.
  Future<void> up(Database db);
}
