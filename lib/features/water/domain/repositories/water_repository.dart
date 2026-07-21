import 'package:life_ledger/core/error/result.dart';

/// One-tap water logging + daily totals (docs/08 F4).
abstract interface class WaterRepository {
  /// Logs [amountMl] of water now. Returns the new day total (ml).
  Future<Result<double>> addWater({
    required String userId,
    required double amountMl,
  });

  /// The total water logged (ml) for [localDate].
  Future<Result<double>> totalForDate(String userId, String localDate);
}
