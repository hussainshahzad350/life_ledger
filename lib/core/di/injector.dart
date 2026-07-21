import 'package:get_it/get_it.dart';

import 'package:life_ledger/core/database/app_database.dart';
import 'package:life_ledger/core/logging/app_logger.dart';
import 'package:life_ledger/core/time/clock.dart';

/// The application-wide service locator (docs/03-architecture.md §3, ADR-0003).
final GetIt getIt = GetIt.instance;

/// Registers every core dependency at the composition root.
///
/// Lifetimes follow docs/03 §3: singletons for stateless services, factories
/// for Blocs/use cases (added as features land in M2+). Nothing outside this
/// file references concrete implementations.
///
/// Note: registration is hand-written while the graph is this small;
/// `injectable` codegen (ADR-0003) is introduced when feature slices multiply
/// in M2+ — same locator, generated wiring.
Future<void> configureDependencies() async {
  getIt
    ..registerLazySingleton<AppLogger>(ConsoleLogger.new)
    ..registerLazySingleton<Clock>(SystemClock.new)
    ..registerLazySingleton<AppDatabase>(
      () => AppDatabase(logger: getIt<AppLogger>()),
    );
}

/// Fails fast in debug if the dependency graph is miswired
/// (docs/03 §9 "DI misconfiguration" mitigation; M0 DoD in docs/12).
///
/// Resolves every registered core service once; any missing or cyclic
/// registration throws immediately at startup instead of at first use.
void diSelfCheck() {
  getIt
    ..get<AppLogger>()
    ..get<Clock>()
    ..get<AppDatabase>();
}

/// Clears all registrations (test support).
Future<void> resetDependencies() => getIt.reset();
