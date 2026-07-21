import 'package:flutter_test/flutter_test.dart';
import 'package:life_ledger/core/error/failure.dart';
import 'package:life_ledger/core/error/result.dart';
import 'package:life_ledger/core/time/clock.dart';
import 'package:life_ledger/features/profile/application/save_profile.dart';
import 'package:life_ledger/features/profile/domain/entities/user_profile.dart';
import 'package:life_ledger/features/profile/domain/repositories/profile_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late MockProfileRepository repository;
  late SaveProfile useCase;
  final now = DateTime.utc(2026, 7, 21);

  setUpAll(() => registerFallbackValue(const UserProfile(id: 'fallback')));

  setUp(() {
    repository = MockProfileRepository();
    useCase = SaveProfile(repository: repository, clock: FixedClock(now));
    when(() => repository.saveProfile(any())).thenAnswer(
      (invocation) async =>
          Result.success(invocation.positionalArguments.first as UserProfile),
    );
  });

  group('SaveProfile validation (docs/08 F1)', () {
    test('valid profile passes through to the repository', () async {
      final profile = UserProfile(
        id: 'p1',
        heightCm: 165,
        birthDate: DateTime.utc(1997, 3, 2),
      );
      final result = await useCase(profile);
      expect(result.valueOrNull, profile);
      verify(() => repository.saveProfile(profile)).called(1);
    });

    test(
      'rejects out-of-domain height before hitting the repository',
      () async {
        for (final height in [0.0, 300.0, -5.0]) {
          final result = await useCase(UserProfile(id: 'p1', heightCm: height));
          expect(result.failureOrNull, isA<ValidationFailure>());
        }
        verifyNever(() => repository.saveProfile(any()));
      },
    );

    test('rejects a birth date in the future', () async {
      final result = await useCase(
        UserProfile(id: 'p1', birthDate: DateTime.utc(2030)),
      );
      final failure = result.failureOrNull! as ValidationFailure;
      expect(failure.field, 'birthDate');
      verifyNever(() => repository.saveProfile(any()));
    });

    test(
      'a profile with no optional data is valid (skippable, FR-4)',
      () async {
        final result = await useCase(const UserProfile(id: 'p1'));
        expect(result.isSuccess, isTrue);
      },
    );
  });
}
