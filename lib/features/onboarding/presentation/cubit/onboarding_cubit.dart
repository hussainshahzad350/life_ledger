import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:life_ledger/core/database/app_meta_store.dart';
import 'package:life_ledger/core/error/failure.dart';
import 'package:life_ledger/core/health/health_types.dart';
import 'package:life_ledger/core/utils/id_generator.dart';
import 'package:life_ledger/features/goals/application/generate_default_goals.dart';
import 'package:life_ledger/features/profile/application/save_profile.dart';
import 'package:life_ledger/features/profile/domain/entities/user_profile.dart';
import 'package:life_ledger/features/weight/domain/repositories/weight_repository.dart';

/// Onboarding flow states (docs/08 F1, docs/05 §5.6).
sealed class OnboardingState extends Equatable {
  const OnboardingState();

  @override
  List<Object?> get props => [];
}

/// Collecting input (initial).
final class OnboardingInProgress extends OnboardingState {
  /// Creates the in-progress state.
  const OnboardingInProgress();
}

/// Saving profile + generating goals.
final class OnboardingSaving extends OnboardingState {
  /// Creates the saving state.
  const OnboardingSaving();
}

/// Finished (completed with data, or skipped) — the app shell takes over.
final class OnboardingDone extends OnboardingState {
  /// Creates the done state. [skipped] is true when the user skipped setup.
  const OnboardingDone({required this.skipped});

  /// Whether onboarding was skipped (defaults in force, FR-4).
  final bool skipped;

  @override
  List<Object?> get props => [skipped];
}

/// Something failed; the wizard stays usable.
final class OnboardingError extends OnboardingState {
  /// Creates the error state.
  const OnboardingError(this.failure);

  /// What went wrong (localized by the UI from the type).
  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

/// Orchestrates the skippable onboarding wizard (docs/08 F1/F2):
/// save profile → first weight entry → engine-default goals → mark done.
class OnboardingCubit extends Cubit<OnboardingState> {
  /// Creates the cubit.
  OnboardingCubit({
    required SaveProfile saveProfile,
    required GenerateDefaultGoals generateDefaultGoals,
    required WeightRepository weightRepository,
    required AppMetaStore appMeta,
    required IdGenerator ids,
  }) : _saveProfile = saveProfile,
       _generateDefaultGoals = generateDefaultGoals,
       _weightRepository = weightRepository,
       _appMeta = appMeta,
       _ids = ids,
       super(const OnboardingInProgress());

  final SaveProfile _saveProfile;
  final GenerateDefaultGoals _generateDefaultGoals;
  final WeightRepository _weightRepository;
  final AppMetaStore _appMeta;
  final IdGenerator _ids;

  /// Completes onboarding with the collected inputs.
  Future<void> complete({
    String? displayName,
    required Sex sex,
    required DateTime birthDate,
    required double heightCm,
    required double weightKg,
    required ActivityLevel activityLevel,
    required WeightObjective objective,
    UnitSystem unitSystem = UnitSystem.metric,
  }) async {
    emit(const OnboardingSaving());

    final profile = UserProfile(
      id: _ids.newId(),
      displayName: displayName,
      sex: sex,
      birthDate: birthDate,
      heightCm: heightCm,
      unitSystem: unitSystem,
      activityLevel: activityLevel,
    );

    final saved = await _saveProfile(profile);
    if (saved.failureOrNull case final failure?) {
      emit(OnboardingError(failure));
      return;
    }

    final weight = await _weightRepository.addEntry(
      userId: profile.id,
      weightKg: weightKg,
    );
    if (weight.failureOrNull case final failure?) {
      emit(OnboardingError(failure));
      return;
    }

    final goals = await _generateDefaultGoals(
      profile: profile,
      weightKg: weightKg,
      objective: objective,
    );
    if (goals.failureOrNull case final failure?) {
      emit(OnboardingError(failure));
      return;
    }

    await _appMeta.write(AppMetaStore.onboardingDoneKey, '1');
    emit(const OnboardingDone(skipped: false));
  }

  /// Skips onboarding entirely — the app stays fully usable with defaults
  /// (FR-4). A minimal default profile is still created so logging always
  /// has a user to attribute entries to; the user can complete their profile
  /// and goals later from Settings.
  Future<void> skip() async {
    await _saveProfile(UserProfile(id: _ids.newId()));
    await _appMeta.write(AppMetaStore.onboardingDoneKey, '1');
    emit(const OnboardingDone(skipped: true));
  }
}
