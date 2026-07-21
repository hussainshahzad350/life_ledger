import 'package:get_it/get_it.dart';

import 'package:life_ledger/core/database/app_database.dart';
import 'package:life_ledger/core/database/app_meta_store.dart';
import 'package:life_ledger/core/logging/app_logger.dart';
import 'package:life_ledger/core/time/clock.dart';
import 'package:life_ledger/core/utils/id_generator.dart';
import 'package:life_ledger/features/goals/application/generate_default_goals.dart';
import 'package:life_ledger/features/goals/domain/repositories/goal_repository.dart';
import 'package:life_ledger/features/goals/infrastructure/repositories/goal_repository_impl.dart';
import 'package:life_ledger/features/goals/presentation/cubit/goals_cubit.dart';
import 'package:life_ledger/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:life_ledger/features/profile/application/save_profile.dart';
import 'package:life_ledger/features/profile/domain/repositories/profile_repository.dart';
import 'package:life_ledger/features/profile/infrastructure/repositories/profile_repository_impl.dart';
import 'package:life_ledger/features/weight/domain/repositories/weight_repository.dart';
import 'package:life_ledger/features/weight/infrastructure/repositories/weight_repository_impl.dart';

/// The application-wide service locator (docs/03-architecture.md §3, ADR-0003).
final GetIt getIt = GetIt.instance;

/// Registers every dependency at the composition root.
///
/// Lifetimes follow docs/03 §3: singletons for stateless services and
/// repositories; factories for use cases and Cubits. Nothing outside this
/// file references concrete implementations.
///
/// Note: registration is hand-written while the graph is this small;
/// `injectable` codegen (ADR-0003) is introduced when the graph justifies
/// the codegen setup — same locator, generated wiring.
Future<void> configureDependencies() async {
  getIt
    // Core services.
    ..registerLazySingleton<AppLogger>(ConsoleLogger.new)
    ..registerLazySingleton<Clock>(SystemClock.new)
    ..registerLazySingleton<IdGenerator>(UuidGenerator.new)
    ..registerLazySingleton<AppDatabase>(
      () => AppDatabase(logger: getIt<AppLogger>()),
    )
    ..registerLazySingleton<AppMetaStore>(
      () => AppMetaStore(getIt<AppDatabase>()),
    )
    // Repositories (interfaces → infrastructure implementations).
    ..registerLazySingleton<ProfileRepository>(
      () => ProfileRepositoryImpl(
        db: getIt<AppDatabase>(),
        clock: getIt<Clock>(),
      ),
    )
    ..registerLazySingleton<GoalRepository>(
      () => GoalRepositoryImpl(
        db: getIt<AppDatabase>(),
        clock: getIt<Clock>(),
        ids: getIt<IdGenerator>(),
      ),
    )
    ..registerLazySingleton<WeightRepository>(
      () => WeightRepositoryImpl(
        db: getIt<AppDatabase>(),
        clock: getIt<Clock>(),
        ids: getIt<IdGenerator>(),
      ),
    )
    // Use cases.
    ..registerFactory<SaveProfile>(
      () => SaveProfile(
        repository: getIt<ProfileRepository>(),
        clock: getIt<Clock>(),
      ),
    )
    ..registerFactory<GetProfile>(() => GetProfile(getIt<ProfileRepository>()))
    ..registerFactory<GenerateDefaultGoals>(
      () => GenerateDefaultGoals(
        goals: getIt<GoalRepository>(),
        clock: getIt<Clock>(),
      ),
    )
    // Cubits.
    ..registerFactory<GoalsCubit>(
      () => GoalsCubit(repository: getIt<GoalRepository>()),
    )
    ..registerFactory<OnboardingCubit>(
      () => OnboardingCubit(
        saveProfile: getIt<SaveProfile>(),
        generateDefaultGoals: getIt<GenerateDefaultGoals>(),
        weightRepository: getIt<WeightRepository>(),
        appMeta: getIt<AppMetaStore>(),
        ids: getIt<IdGenerator>(),
      ),
    );
}

/// Fails fast in debug if the dependency graph is miswired
/// (docs/03 §9 mitigation; M0 DoD in docs/12).
void diSelfCheck() {
  getIt
    ..get<AppLogger>()
    ..get<Clock>()
    ..get<IdGenerator>()
    ..get<AppDatabase>()
    ..get<AppMetaStore>()
    ..get<ProfileRepository>()
    ..get<GoalRepository>()
    ..get<WeightRepository>()
    ..get<SaveProfile>()
    ..get<GetProfile>()
    ..get<GenerateDefaultGoals>()
    ..get<GoalsCubit>()
    ..get<OnboardingCubit>();
}

/// Clears all registrations (test support).
Future<void> resetDependencies() => getIt.reset();
