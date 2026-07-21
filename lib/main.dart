import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:life_ledger/app/app.dart';
import 'package:life_ledger/core/database/app_database.dart';
import 'package:life_ledger/core/database/app_meta_store.dart';
import 'package:life_ledger/core/di/injector.dart';

/// Application entry point.
///
/// Bootstraps the composition root (docs/03 §3), verifies the dependency
/// graph in debug (M0 DoD), opens the database at the current schema
/// version (docs/04 §7), then runs the shell — showing the skippable
/// onboarding wizard on first launch (docs/08 F1).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await configureDependencies();
  if (kDebugMode) diSelfCheck();
  await getIt<AppDatabase>().open();

  final onboardingDone = (await getIt<AppMetaStore>().read(
    AppMetaStore.onboardingDoneKey,
  )).valueOrNull;

  runApp(LifeLedgerApp(showOnboarding: onboardingDone != '1'));
}
