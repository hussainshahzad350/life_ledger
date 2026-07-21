import 'package:flutter_test/flutter_test.dart';
import 'package:life_ledger/core/ai/correlation.dart';
import 'package:life_ledger/core/ai/food_text_parser.dart';
import 'package:life_ledger/core/ai/insight.dart';
import 'package:life_ledger/core/ai/safety_filter.dart';
import 'package:life_ledger/core/health/health_score.dart';
import 'package:life_ledger/core/health/health_types.dart';

/// Value-equality contracts for the engine value objects (docs/10 §1
/// immutability-by-default): equal content ⇒ equal objects, different
/// content ⇒ different objects.
///
/// Instances are built from runtime values (not const) so canonicalization
/// cannot short-circuit the comparison.
void main() {
  // Runtime values defeat const canonicalization.
  final one = double.parse('1');
  final two = double.parse('2');

  group('health value objects', () {
    test('Estimate equality', () {
      expect(
        Estimate(one, reducedConfidence: true, notes: const ['n']),
        Estimate(one, reducedConfidence: true, notes: const ['n']),
      );
      expect(Estimate(one), isNot(Estimate(two)));
    });

    test('BmiResult equality', () {
      expect(
        BmiResult(value: one, category: BmiCategory.overweight),
        BmiResult(value: one, category: BmiCategory.overweight),
      );
      expect(
        BmiResult(value: one, category: BmiCategory.overweight),
        isNot(BmiResult(value: two, category: BmiCategory.overweight)),
      );
    });

    test('MacroGoals equality', () {
      MacroGoals goals(double p) => MacroGoals(
        proteinG: p,
        carbsG: one,
        fatG: one,
        fiberG: one,
        sugarCeilingG: one,
      );
      expect(goals(one), goals(one));
      expect(goals(one), isNot(goals(two)));
    });

    test('ScoreComponent equality', () {
      ScoreComponent component(double actual) => ScoreComponent(
        kind: ScoreComponentKind.reach,
        actual: actual,
        target: two,
        weight: one,
      );
      expect(component(one), component(one));
      expect(component(one), isNot(component(two)));
    });
  });

  group('ai value objects', () {
    test('WaterEvent equality', () {
      expect(
        WaterEvent(hourOfDay: 20, amountMl: one),
        WaterEvent(hourOfDay: 20, amountMl: one),
      );
      expect(
        WaterEvent(hourOfDay: 20, amountMl: one),
        isNot(WaterEvent(hourOfDay: 8, amountMl: one)),
      );
    });

    test('InsightContext equality', () {
      InsightContext context(double goal) =>
          InsightContext(today: '2026-07-21', proteinGoalG: goal);
      expect(context(one), context(one));
      expect(context(one), isNot(context(two)));
    });

    test('CorrelationFinding equality', () {
      CorrelationFinding finding(double mean) => CorrelationFinding(
        exposedMean: mean,
        unexposedMean: one,
        exposedCount: 5,
        unexposedCount: 6,
      );
      expect(finding(one), finding(one));
      expect(finding(one), isNot(finding(two)));
    });

    test('FoodLexeme equality', () {
      FoodLexeme lexeme(String id) =>
          FoodLexeme(id: id, name: 'Egg', aliases: const ['anda']);
      expect(lexeme('a'), lexeme('a'));
      expect(lexeme('a'), isNot(lexeme('b')));
    });

    test('RejectedInsight equality', () {
      InsightCandidate candidate(String title) => InsightCandidate(
        ruleId: 'R',
        category: InsightCategory.trend,
        title: title,
        body: 'b',
        confidence: Confidence.low,
        evidence: const {},
        periodStart: '2026-07-01',
        periodEnd: '2026-07-21',
      );
      expect(
        RejectedInsight(candidate: candidate('t'), reason: 'r'),
        RejectedInsight(candidate: candidate('t'), reason: 'r'),
      );
      expect(
        RejectedInsight(candidate: candidate('t'), reason: 'r'),
        isNot(RejectedInsight(candidate: candidate('u'), reason: 'r')),
      );
    });
  });
}
