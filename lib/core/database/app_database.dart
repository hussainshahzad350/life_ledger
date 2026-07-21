import 'package:life_ledger/core/database/migrations/migration.dart';
import 'package:life_ledger/core/database/migrations/v1_initial.dart';
import 'package:life_ledger/core/logging/app_logger.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Owns the SQLite connection and schema lifecycle
/// (docs/04-database-design.md §7, ADR-0005).
///
/// - Foreign keys are enabled on **every** connection (`onConfigure`).
/// - The schema is versioned via sqflite's `version` (SQLite `user_version`);
///   forward-only [Migration]s are applied in order on create/upgrade.
/// - Downgrades are refused: opening a database newer than the app understands
///   is an error (the user must update the app — docs/04 §8).
class AppDatabase {
  /// Creates the database gateway. [databaseFactory] is injectable so tests
  /// can use `sqflite_common_ffi` (docs/11 §2); when null, the platform
  /// default factory is used.
  AppDatabase({required this.logger, this.factory, this.path});

  /// Local-only logger for lifecycle events (docs/03 §5).
  final AppLogger logger;

  /// Override factory for tests (`sqflite_common_ffi`); null = platform default.
  final DatabaseFactory? factory;

  /// Override database path for tests; null = default app databases directory.
  final String? path;

  /// The ordered, append-only migration ledger (docs/04 §7.1).
  /// New migrations are appended — never inserted, never edited.
  static const List<Migration> migrations = [V1Initial()];

  /// The schema version this build of the app requires.
  static final int schemaVersion = migrations.last.version;

  /// Database file name inside the app's databases directory.
  static const String databaseFileName = 'life_ledger.db';

  Database? _db;

  /// The open database. Throws [StateError] if [open] has not completed.
  Database get database {
    final db = _db;
    if (db == null) {
      throw StateError('AppDatabase.open() must complete before use.');
    }
    return db;
  }

  /// Whether the database has been opened.
  bool get isOpen => _db?.isOpen ?? false;

  /// Opens (creating/migrating as needed) and returns the database.
  Future<Database> open() async {
    if (_db case final db? when db.isOpen) return db;

    final factory = this.factory ?? databaseFactory;
    final path =
        this.path ?? p.join(await factory.getDatabasesPath(), databaseFileName);

    final db = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onConfigure: (db) async {
          // Referential integrity on every connection (docs/04 §7, NFR-12).
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          logger.info('Creating database at schema v$version');
          for (final migration in migrations) {
            if (migration.version <= version) {
              await migration.up(db);
            }
          }
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          logger.info('Upgrading database v$oldVersion -> v$newVersion');
          for (final migration in migrations) {
            if (migration.version > oldVersion &&
                migration.version <= newVersion) {
              logger.info(
                'Applying migration v${migration.version}: '
                '${migration.description}',
              );
              await migration.up(db);
            }
          }
        },
        onDowngrade: (db, oldVersion, newVersion) async {
          // A newer-schema DB with an older app: refuse rather than corrupt
          // (docs/04 §8 restore rule).
          throw UnsupportedError(
            'Database schema v$oldVersion is newer than this app supports '
            '(v$newVersion). Update the app.',
          );
        },
      ),
    );

    _db = db;
    logger.info('Database open at schema v$schemaVersion');
    return db;
  }

  /// Closes the connection (used by tests and teardown paths).
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
