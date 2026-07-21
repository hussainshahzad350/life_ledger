import 'package:life_ledger/core/error/result.dart';
import 'package:life_ledger/features/weight/domain/entities/weight_entry.dart';

/// Persistence contract for weight readings (docs/08 F5).
///
/// M2 ships the subset the goal engine needs (add + latest); charts and
/// trend queries arrive with milestone M5.
abstract interface class WeightRepository {
  /// Records a reading and returns it.
  Future<Result<WeightEntry>> addEntry({
    required String userId,
    required double weightKg,
  });

  /// The most recent (non-deleted) reading, or null when none exist.
  Future<Result<WeightEntry?>> getLatest(String userId);

  /// The most recent [limit] readings, newest first (for the dashboard trend
  /// arrow and, later, the weight chart — docs/08 F5/F10).
  Future<Result<List<WeightEntry>>> getRecent(String userId, {int limit = 2});
}
