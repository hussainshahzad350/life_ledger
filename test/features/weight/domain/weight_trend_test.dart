import 'package:flutter_test/flutter_test.dart';
import 'package:life_ledger/features/weight/domain/entities/weight_entry.dart';
import 'package:life_ledger/features/weight/domain/weight_trend.dart';

WeightEntry _entry(double kg, int day) => WeightEntry(
  id: 'w$day',
  userId: 'u1',
  weightKg: kg,
  loggedAt: DateTime.utc(2026, 7, day),
  localDate: '2026-07-${day.toString().padLeft(2, '0')}',
);

void main() {
  group('computeWeightTrend (docs/06 weight)', () {
    test('returns null with fewer than two readings', () {
      expect(computeWeightTrend([]), isNull);
      expect(computeWeightTrend([_entry(70, 1)]), isNull);
    });

    test('falling readings report a downward trend', () {
      final trend = computeWeightTrend([
        _entry(72, 1),
        _entry(71.5, 2),
        _entry(71, 3),
        _entry(70.5, 4),
      ])!;
      expect(trend.direction, TrendDirection.down);
      expect(trend.deltaKg, lessThan(0));
      expect(trend.sampleCount, 4);
    });

    test('rising readings report an upward trend', () {
      final trend = computeWeightTrend([
        _entry(70, 1),
        _entry(70.5, 2),
        _entry(71, 3),
        _entry(71.5, 4),
      ])!;
      expect(trend.direction, TrendDirection.up);
      expect(trend.deltaKg, greaterThan(0));
    });

    test('small swings inside the noise band read as steady', () {
      final trend = computeWeightTrend([
        _entry(70.0, 1),
        _entry(70.2, 2),
        _entry(69.9, 3),
        _entry(70.1, 4),
      ])!;
      expect(trend.direction, TrendDirection.steady);
    });

    test('unsorted input is ordered before smoothing', () {
      final trend = computeWeightTrend([
        _entry(70.5, 4),
        _entry(72, 1),
        _entry(71, 3),
        _entry(71.5, 2),
      ])!;
      expect(trend.direction, TrendDirection.down);
      expect(trend.averageKg, closeTo(71.25, 0.001));
    });

    test('odd counts drop the middle reading', () {
      final trend = computeWeightTrend([
        _entry(72, 1),
        _entry(71, 2),
        _entry(70, 3),
      ])!;
      // Halves are [72] and [70]; the middle 71 is excluded.
      expect(trend.deltaKg, closeTo(-2, 0.001));
      expect(trend.sampleCount, 3);
    });
  });
}
