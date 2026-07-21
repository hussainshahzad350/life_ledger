import 'package:get_it/get_it.dart';

import 'package:life_ledger/core/database/app_database.dart';
import 'package:life_ledger/core/database/app_meta_store.dart';
import 'package:life_ledger/core/logging/app_logger.dart';
import 'package:life_ledger/core/time/clock.dart';
import 'package:life_ledger/core/utils/id_generator.dart';
import 'package:life_ledger/features/dashboard/application/get_daily_summary.dart';
import 'package:life_ledger/features/data/domain/data_repository.dart';
import 'package:life_ledger/features/data/infrastructure/data_repository_impl.dart';
import 'package:life_ledger/features/exercise/domain/exercise_entry.dart';
import 'package:life_ledger/features/exercise/infrastructure/exercise_repository_impl.dart';
import 'package:life_ledger/features/food/application/food_use_cases.dart';
import 'package:life_ledger/features/food/domain/repositories/food_repository.dart';
import 'package:life_ledger/features/food/infrastructure/food_seeder.dart';
import 'package:life_ledger/features/food/infrastructure/repositories/food_repository_impl.dart';
import 'package:life_ledger/features/goals/application/generate_default_goals.dart';
import 'package:life_ledger/features/goals/domain/repositories/goal_repository.dart';
import 'package:life_ledger/features/goals/infrastructure/repositories/goal_repository_impl.dart';
import 'package:life_ledger/features/goals/presentation/cubit/goals_cubit.dart';
import 'package:life_ledger/features/insights/application/generate_insights.dart';
import 'package:life_ledger/features/insights/domain/insight_record.dart';
import 'package:life_ledger/features/insights/infrastructure/insight_context_gateway_impl.dart';
import 'package:life_ledger/features/insights/infrastructure/insight_repository_impl.dart';
import 'package:life_ledger/features/mood/domain/mood_entry.dart';
import 'package:life_ledger/features/mood/infrastructure/mood_repository_impl.dart';
import 'package:life_ledger/features/notifications/domain/reminder_scheduler.dart';
import 'package:life_ledger/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:life_ledger/features/profile/application/get_current_user_id.dart';
import 'package:life_ledger/features/profile/application/save_profile.dart';
import 'package:life_ledger/features/profile/domain/repositories/profile_repository.dart';
import 'package:life_ledger/features/profile/infrastructure/repositories/profile_repository_impl.dart';
import 'package:life_ledger/features/reports/domain/report_models.dart';
import 'package:life_ledger/features/reports/infrastructure/report_repository_impl.dart';
import 'package:life_ledger/features/settings/domain/settings.dart';
import 'package:life_ledger/features/settings/infrastructure/settings_repository_impl.dart';
import 'package:life_ledger/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:life_ledger/features/sleep/domain/sleep_entry.dart';
import 'package:life_ledger/features/sleep/infrastructure/sleep_repository_impl.dart';
import 'package:life_ledger/features/symptoms/domain/symptom.dart';
import 'package:life_ledger/features/symptoms/infrastructure/symptom_repository_impl.dart';
import 'package:life_ledger/features/water/domain/repositories/water_repository.dart';
import 'package:life_ledger/features/water/infrastructure/repositories/water_repository_impl.dart';
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
    ..registerLazySingleton<FoodRepository>(
      () => FoodRepositoryImpl(
        db: getIt<AppDatabase>(),
        clock: getIt<Clock>(),
        ids: getIt<IdGenerator>(),
      ),
    )
    ..registerLazySingleton<WaterRepository>(
      () => WaterRepositoryImpl(
        db: getIt<AppDatabase>(),
        clock: getIt<Clock>(),
        ids: getIt<IdGenerator>(),
      ),
    )
    ..registerLazySingleton<SleepRepository>(
      () => SleepRepositoryImpl(
        db: getIt<AppDatabase>(),
        clock: getIt<Clock>(),
        ids: getIt<IdGenerator>(),
      ),
    )
    ..registerLazySingleton<MoodRepository>(
      () => MoodRepositoryImpl(
        db: getIt<AppDatabase>(),
        clock: getIt<Clock>(),
        ids: getIt<IdGenerator>(),
      ),
    )
    ..registerLazySingleton<SymptomRepository>(
      () => SymptomRepositoryImpl(
        db: getIt<AppDatabase>(),
        clock: getIt<Clock>(),
        ids: getIt<IdGenerator>(),
      ),
    )
    ..registerLazySingleton<ExerciseRepository>(
      () => ExerciseRepositoryImpl(
        db: getIt<AppDatabase>(),
        clock: getIt<Clock>(),
        ids: getIt<IdGenerator>(),
      ),
    )
    ..registerLazySingleton<ReportRepository>(
      () =>
          ReportRepositoryImpl(db: getIt<AppDatabase>(), clock: getIt<Clock>()),
    )
    ..registerLazySingleton<InsightContextGateway>(
      () => InsightContextGatewayImpl(
        db: getIt<AppDatabase>(),
        goals: getIt<GoalRepository>(),
        clock: getIt<Clock>(),
      ),
    )
    ..registerLazySingleton<InsightRepository>(
      () => InsightRepositoryImpl(
        db: getIt<AppDatabase>(),
        clock: getIt<Clock>(),
        ids: getIt<IdGenerator>(),
      ),
    )
    ..registerLazySingleton<DataRepository>(
      () => DataRepositoryImpl(db: getIt<AppDatabase>(), clock: getIt<Clock>()),
    )
    ..registerLazySingleton<SettingsRepository>(
      () => SettingsRepositoryImpl(getIt<AppMetaStore>()),
    )
    ..registerLazySingleton<BackupCipher>(IdentityBackupCipher.new)
    ..registerLazySingleton<ReminderScheduler>(NoopReminderScheduler.new)
    ..registerLazySingleton<FoodSeeder>(() => FoodSeeder(getIt<AppDatabase>()))
    // Use cases.
    ..registerFactory<SaveProfile>(
      () => SaveProfile(
        repository: getIt<ProfileRepository>(),
        clock: getIt<Clock>(),
      ),
    )
    ..registerFactory<GetProfile>(() => GetProfile(getIt<ProfileRepository>()))
    ..registerFactory<GetCurrentUserId>(
      () => GetCurrentUserId(getIt<ProfileRepository>()),
    )
    ..registerFactory<LogFoodEntry>(() => LogFoodEntry(getIt<FoodRepository>()))
    ..registerFactory<GetDayTimeline>(
      () => GetDayTimeline(getIt<FoodRepository>()),
    )
    ..registerFactory<GetDailySummary>(
      () => GetDailySummary(
        food: getIt<FoodRepository>(),
        water: getIt<WaterRepository>(),
        weight: getIt<WeightRepository>(),
        goals: getIt<GoalRepository>(),
        clock: getIt<Clock>(),
      ),
    )
    ..registerFactory<GenerateDefaultGoals>(
      () => GenerateDefaultGoals(
        goals: getIt<GoalRepository>(),
        clock: getIt<Clock>(),
      ),
    )
    ..registerFactory<GenerateInsights>(
      () => GenerateInsights(
        gateway: getIt<InsightContextGateway>(),
        repository: getIt<InsightRepository>(),
      ),
    )
    // Cubits.
    ..registerFactory<SettingsCubit>(
      () => SettingsCubit(
        settings: getIt<SettingsRepository>(),
        data: getIt<DataRepository>(),
        cipher: getIt<BackupCipher>(),
        reminders: getIt<ReminderScheduler>(),
      ),
    )
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
    ..get<FoodRepository>()
    ..get<WaterRepository>()
    ..get<SleepRepository>()
    ..get<MoodRepository>()
    ..get<SymptomRepository>()
    ..get<ExerciseRepository>()
    ..get<ReportRepository>()
    ..get<InsightContextGateway>()
    ..get<InsightRepository>()
    ..get<DataRepository>()
    ..get<SettingsRepository>()
    ..get<BackupCipher>()
    ..get<ReminderScheduler>()
    ..get<FoodSeeder>()
    ..get<SaveProfile>()
    ..get<GetProfile>()
    ..get<GetCurrentUserId>()
    ..get<LogFoodEntry>()
    ..get<GetDayTimeline>()
    ..get<GetDailySummary>()
    ..get<GenerateDefaultGoals>()
    ..get<GenerateInsights>()
    ..get<SettingsCubit>()
    ..get<GoalsCubit>()
    ..get<OnboardingCubit>();
}

/// Clears all registrations (test support).
Future<void> resetDependencies() => getIt.reset();
