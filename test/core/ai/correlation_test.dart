import 'package:flutter_test/flutter_test.dart';
import 'package:life_ledger/core/ai/correlation.dart';

void main() {
  group('compareExposure (docs/07 §5)', () {
    test('computes group means, counts, and the difference', () {
      final finding = compareExposure(
        exposed: [1, 1, 1, 0, 1],
        unexposed: [0, 0, 1, 0, 0, 0],
      )!;
      expect(finding.exposedMean, closeTo(0.8, 0.0001));
      expect(finding.unexposedMean, closeTo(1 / 6, 0.0001));
      expect(finding.difference, closeTo(0.8 - 1 / 6, 0.0001));
      expect(finding.exposedCount, 5);
      expect(finding.unexposedCount, 6);
    });

    test('null when either group is empty', () {
      expect(compareExposure(exposed: [], unexposed: [1]), isNull);
      expect(compareExposure(exposed: [1], unexposed: []), isNull);
    });

    test('sample sufficiency thresholds (docs/07 §4)', () {
      final thin = compareExposure(
        exposed: List.filled(4, 1),
        unexposed: List.filled(10, 0),
      )!;
      expect(thin.sufficientSample, isFalse);

      final ok = compareExposure(
        exposed: List.filled(5, 1),
        unexposed: List.filled(5, 0),
      )!;
      expect(ok.sufficientSample, isTrue);
      expect(ok.mediumSample, isFalse);

      final medium = compareExposure(
        exposed: List.filled(10, 1),
        unexposed: List.filled(10, 0),
      )!;
      expect(medium.mediumSample, isTrue);
    });
  });
}
