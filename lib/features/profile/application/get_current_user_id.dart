import 'package:life_ledger/core/error/result.dart';
import 'package:life_ledger/features/profile/domain/repositories/profile_repository.dart';

/// Resolves the current (single, v1) user's id (docs/08 F1). Onboarding —
/// including skip — always leaves a profile, so this is non-null after
/// first launch; returns null only before onboarding completes.
class GetCurrentUserId {
  /// Creates the use case.
  const GetCurrentUserId(this._repository);

  final ProfileRepository _repository;

  /// Returns the user id, or null when no profile exists yet.
  Future<Result<String?>> call() async {
    final result = await _repository.getProfile();
    return result.map((profile) => profile?.id);
  }
}
