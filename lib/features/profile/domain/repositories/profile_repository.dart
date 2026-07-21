import 'package:life_ledger/core/error/result.dart';
import 'package:life_ledger/features/profile/domain/entities/user_profile.dart';

/// Persistence contract for the (single, v1) user profile — docs/08 F1.
/// Implemented in infrastructure; returns `Result` per docs/03 §4.
abstract interface class ProfileRepository {
  /// The stored profile, or null when none exists yet.
  Future<Result<UserProfile?>> getProfile();

  /// Inserts or updates the profile (id decides).
  Future<Result<UserProfile>> saveProfile(UserProfile profile);
}
