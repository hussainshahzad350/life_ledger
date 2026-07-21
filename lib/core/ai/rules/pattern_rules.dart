import 'package:life_ledger/core/ai/ai_constants.dart';
import 'package:life_ledger/core/ai/insight.dart';
import 'package:life_ledger/core/ai/insight_engine.dart';

/// `GOAL_PROTEIN_GAP` — weekly protein intake consistently under the goal
/// (docs/07 §3). Gentle, factual; suggestions are experiments, not
/// prescriptions.
class GoalProteinGapRule implements InsightRule {
  /// Creates the rule.
  const GoalProteinGapRule();

  @override
  String get ruleId => 'GOAL_PROTEIN_GAP';

  @override
  InsightCandidate? evaluate(InsightContext context) {
    if (context.proteinGoalG <= 0) return null;

    final window = dateWindow(context.today, AiConstants.patternWindowDays);
    final values = [for (final d in window) ?context.proteinGByDate[d]];
    if (values.length < AiConstants.trendMinLoggedPerWindow) return null;

    final avgAdherence =
        values.map((v) => v / context.proteinGoalG).reduce((a, b) => a + b) /
        values.length;
    if (avgAdherence >= AiConstants.proteinGapPct) return null;

    final pct = (avgAdherence * 100).round();
    return InsightCandidate(
      ruleId: ruleId,
      category: InsightCategory.threshold,
      title: 'Protein below goal this week',
      body:
          "You're averaging $pct% of your protein goal this week. "
          'If you want, you could try adding one protein-rich food to a '
          'meal you already eat.',
      confidence: Confidence.medium,
      evidence: {
        'avgAdherence': avgAdherence,
        'daysObserved': values.length,
        'goalG': context.proteinGoalG,
      },
      periodStart: window.first,
      periodEnd: window.last,
    );
  }
}

/// `HYDRATION_TIMING` — most water is logged late in the day
/// (docs/07 §3, knowledge/hydration.md). A behavioral pattern, low
/// confidence, framed as an experiment.
class HydrationTimingRule implements InsightRule {
  /// Creates the rule.
  const HydrationTimingRule();

  @override
  String get ruleId => 'HYDRATION_TIMING';

  @override
  InsightCandidate? evaluate(InsightContext context) {
    final window = dateWindow(context.today, AiConstants.patternWindowDays);

    var lateDays = 0;
    var analyzableDays = 0;
    for (final day in window) {
      final events = context.waterEventsByDate[day];
      if (events == null || events.length < AiConstants.minWaterEventsPerDay) {
        continue;
      }
      analyzableDays++;
      final total = events.fold(0.0, (sum, e) => sum + e.amountMl);
      final late = events
          .where((e) => e.hourOfDay >= AiConstants.lateHour)
          .fold(0.0, (sum, e) => sum + e.amountMl);
      if (total > 0 && late / total >= AiConstants.lateSharePct) lateDays++;
    }
    if (lateDays < AiConstants.lateDaysMin) return null;

    return InsightCandidate(
      ruleId: ruleId,
      category: InsightCategory.pattern,
      title: 'Most of your water comes late',
      body:
          'On $lateDays of the last ${AiConstants.patternWindowDays} days, '
          'most of your water came after ${AiConstants.lateHour}:00 — '
          'spreading it through the day may help.',
      confidence: Confidence.low,
      evidence: {
        'lateDays': lateDays,
        'analyzableDays': analyzableDays,
        'lateHour': AiConstants.lateHour,
      },
      periodStart: window.first,
      periodEnd: window.last,
    );
  }
}
