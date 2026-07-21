import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:life_ledger/app/app.dart';
import 'package:life_ledger/core/database/app_database.dart';
import 'package:life_ledger/core/di/injector.dart';

/// Application entry point.
///
/// Bootstraps the composition root (docs/03 §3), verifies the dependency
/// graph in debug (M0 DoD, docs/12), opens the database at the current
/// schema version (docs/04 §7), then runs the app shell.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await configureDependencies();
  if (kDebugMode) diSelfCheck();
  await getIt<AppDatabase>().open();

  runApp(const LifeLedgerApp());
}
