import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_ledger/core/database/app_meta_store.dart';
import 'package:life_ledger/core/error/failure.dart';
import 'package:life_ledger/core/error/result.dart';
import 'package:life_ledger/core/health/health_types.dart';
import 'package:life_ledger/features/goals/application/generate_default_goals.dart';
import 'package:life_ledger/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:life_ledger/features/profile/application/save_profile.dart';
import 'package:life_ledger/features/profile/domain/entities/user_profile.dart';
import 'package:life_ledger/features/weight/domain/entities/weight_entry.dart';
import 'package:life_ledger/features/weight/domain/repositories/weight_repository.dart';
import 'package:mocktail/mocktail.dart';

import '../../../support/fakes.dart';

class MockSaveProfile extends Mock implements SaveProfile {}

class MockGenerateDefaultGoals extends Mock implements GenerateDefaultGoals {}

class MockWeightRepository extends Mock implements WeightRepository {}

class MockAppMetaStore extends Mock implements AppMetaStore {}

void main() {
  late MockSaveProfile saveProfile;
  late MockGenerateDefaultGoals generateGoals;
  late MockWeightRepository weights;
  late MockAppMetaStore appMeta;

  setUpAll(() {
    registerFallbackValue(const UserProfile(id: 'fallback'));
    registerFallbackValue(WeightObjective.maintain);
  });

  setUp(() {
    saveProfile = MockSaveProfile();
    generateGoals = MockGenerateDefaultGoals();
    weights = MockWeightRepository();
    appMeta = MockAppMetaStore();

    when(() => saveProfile(any())).thenAnswer(
      (i) async => Result.success(i.positionalArguments.first as UserProfile),
    );
    when(
      () => weights.addEntry(
        userId: any(named: 'userId'),
        weightKg: any(named: 'weightKg'),
      ),
    ).thenAnswer(
      (_) async => Result.success(
        WeightEntry(
          id: 'w1',
          userId: 'u1',
          weightKg: 71,
          loggedAt: DateTime.utc(2026, 7, 21),
          localDate: '2026-07-21',
        ),
      ),
    );
    when(
      () => generateGoals(
        profile: any(named: 'profile'),
        weightKg: any(named: 'weightKg'),
        objective: any(named: 'objective'),
      ),
    ).thenAnswer((_) async => const Result.success([]));
    when(
      () => appMeta.write(any(), any()),
    ).thenAnswer((_) async => const Result.success(null));
  });

  OnboardingCubit build() => OnboardingCubit(
    saveProfile: saveProfile,
    generateDefaultGoals: generateGoals,
    weightRepository: weights,
    appMeta: appMeta,
    ids: SequentialIds(),
  );

  Future<void> complete(OnboardingCubit cubit) => cubit.complete(
    sex: Sex.female,
    birthDate: DateTime.utc(1997, 3, 2),
    heightCm: 165,
    weightKg: 71,
    activityLevel: ActivityLevel.moderate,
    objective: WeightObjective.maintain,
  );

  group('OnboardingCubit (docs/08 F1/F2)', () {
    blocTest<OnboardingCubit, OnboardingState>(
      'happy path: saving → done, and marks onboarding complete',
      build: build,
      act: complete,
      expect: () => const [OnboardingSaving(), OnboardingDone(skipped: false)],
      verify: (_) {
        verify(() => saveProfile(any())).called(1);
        verify(
          () => weights.addEntry(userId: any(named: 'userId'), weightKg: 71),
        ).called(1);
        verify(
          () => appMeta.write(AppMetaStore.onboardingDoneKey, '1'),
        ).called(1);
      },
    );

    blocTest<OnboardingCubit, OnboardingState>(
      'a failure surfaces as an error state and does not mark done',
      build: () {
        when(() => saveProfile(any())).thenAnswer(
          (_) async => const Result.failure(DatabaseFailure('boom')),
        );
        return build();
      },
      act: complete,
      expect: () => const [
        OnboardingSaving(),
        OnboardingError(DatabaseFailure('boom')),
      ],
      verify: (_) => verifyNever(() => appMeta.write(any(), any())),
    );

    blocTest<OnboardingCubit, OnboardingState>(
      'skip (FR-4): still creates a default profile so logging has a user',
      build: build,
      act: (cubit) => cubit.skip(),
      expect: () => const [OnboardingDone(skipped: true)],
      verify: (_) {
        // A minimal default profile is created; no weight/goals are generated.
        verify(() => saveProfile(any())).called(1);
        verifyNever(
          () => weights.addEntry(
            userId: any(named: 'userId'),
            weightKg: any(named: 'weightKg'),
          ),
        );
        verify(
          () => appMeta.write(AppMetaStore.onboardingDoneKey, '1'),
        ).called(1);
      },
    );
  });
}
