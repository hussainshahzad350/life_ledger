import 'package:life_ledger/core/database/app_database.dart';
import 'package:life_ledger/core/logging/app_logger.dart';
import 'package:life_ledger/core/utils/id_generator.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Deterministic sequential id generator for tests.
class SequentialIds implements IdGenerator {
  int _next = 0;

  @override
  String newId() => 'id-${_next++}';
}

/// Opens a fresh in-memory [AppDatabase] on real SQLite (docs/11 §2).
Future<AppDatabase> openTestDatabase() async {
  sqfliteFfiInit();
  final db = AppDatabase(
    logger: const ConsoleLogger(),
    factory: databaseFactoryFfi,
    path: inMemoryDatabasePath,
  );
  await db.open();
  return db;
}

/// Inserts a minimal profile row so FK-constrained tables accept [userId].
Future<void> seedUser(AppDatabase db, String userId) async {
  await db.database.insert('user_profile', <String, Object?>{
    'id': userId,
    'created_at': 0,
    'updated_at': 0,
  });
}
