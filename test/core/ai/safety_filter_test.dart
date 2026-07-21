import 'package:flutter_test/flutter_test.dart';
import 'package:life_ledger/core/ai/insight.dart';
import 'package:life_ledger/core/ai/safety_filter.dart';

InsightCandidate candidate({
  String title = 'Neutral title',
  String body = 'A neutral, hedged observation.',
  InsightCategory category = InsightCategory.trend,
  Confidence confidence = Confidence.medium,
}) {
  return InsightCandidate(
    ruleId: 'TEST_RULE',
    category: category,
    title: title,
    body: body,
    confidence: confidence,
    evidence: const {},
    periodStart: '2026-07-01',
    periodEnd: '2026-07-21',
  );
}

void main() {
  group('SafetyFilter (docs/07 §6)', () {
    test('clean candidates pass unchanged', () {
      final result = SafetyFilter.apply([candidate()]);
      expect(result.accepted, hasLength(1));
      expect(result.rejected, isEmpty);
    });

    test('diagnosis language is rejected with a reason', () {
      final bad = [
        candidate(body: 'This looks like a disease pattern.'),
        candidate(body: 'You may have diabetes.'),
        candidate(title: 'Possible diagnosis found'),
      ];
      final result = SafetyFilter.apply(bad);
      expect(result.accepted, isEmpty);
      expect(result.rejected, hasLength(3));
      for (final r in result.rejected) {
        expect(r.reason, contains('denied language'));
      }
    });

    test('prescriptive language is rejected', () {
      final bad = [
        candidate(body: 'You must stop eating dairy.'),
        candidate(body: 'Take this medication in the morning.'),
        candidate(body: 'Never eat sugar again.'),
      ];
      final result = SafetyFilter.apply(bad);
      expect(result.accepted, isEmpty);
      expect(result.rejected, hasLength(3));
    });

    test('correlation confidence is capped at medium — never high', () {
      final result = SafetyFilter.apply([
        candidate(
          category: InsightCategory.correlation,
          confidence: Confidence.high,
        ),
      ]);
      expect(result.accepted.single.confidence, Confidence.medium);
    });

    test('non-correlation high confidence is preserved', () {
      final result = SafetyFilter.apply([
        candidate(
          category: InsightCategory.streak,
          confidence: Confidence.high,
        ),
      ]);
      expect(result.accepted.single.confidence, Confidence.high);
    });

    test('the gentle clinician suggestion is allowed (not a diagnosis)', () {
      final result = SafetyFilter.apply([
        candidate(
          body:
              'If this is unexpected, consider speaking with a healthcare '
              'professional.',
        ),
      ]);
      expect(result.accepted, hasLength(1));
    });
  });
}
