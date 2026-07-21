import 'package:life_ledger/core/error/failure.dart';
import 'package:life_ledger/core/error/result.dart';
import 'package:life_ledger/core/health/health_constants.dart';
import 'package:life_ledger/core/time/clock.dart';
import 'package:life_ledger/features/profile/domain/entities/user_profile.dart';
import 'package:life_ledger/features/profile/domain/repositories/profile_repository.dart';

/// Validates and persists the user profile (docs/08 F1).
///
/// Domain validation runs *before* the repository (defense in depth,
/// docs/04 §11): the DB CHECKs are the last line, not the only line.
class SaveProfile {
  /// Creates the use case.
  SaveProfile({required ProfileRepository repository, required Clock clock})
    : _repository = repository,
      _clock = clock;

  final ProfileRepository _repository;
  final Clock _clock;

  /// Validates [profile] and saves it.
  Future<Result<UserProfile>> call(UserProfile profile) async {
    final height = profile.heightCm;
    if (height != null &&
        (height <= HealthConstants.minHeightCm ||
            height >= HealthConstants.maxHeightCm)) {
      return const Result.failure(
        ValidationFailure(field: 'heightCm', reason: 'must be in (0, 300) cm'),
      );
    }
    final birth = profile.birthDate;
    if (birth != null && birth.isAfter(_clock.nowUtc())) {
      return const Result.failure(
        ValidationFailure(
          field: 'birthDate',
          reason: 'must not be in the future',
        ),
      );
    }
    return _repository.saveProfile(profile);
  }
}

/// Loads the stored profile, if any (docs/08 F1).
class GetProfile {
  /// Creates the use case.
  GetProfile(this._repository);

  final ProfileRepository _repository;

  /// Returns the profile or null when onboarding hasn't created one.
  Future<Result<UserProfile?>> call() => _repository.getProfile();
}
