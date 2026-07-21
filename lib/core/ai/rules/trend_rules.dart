import 'package:life_ledger/core/ai/ai_constants.dart';
import 'package:life_ledger/core/ai/insight.dart';
import 'package:life_ledger/core/ai/insight_engine.dart';

/// `TREND_PROTEIN_UP` — protein-goal adherence rose week over week
/// (docs/07 §3). Factual trend; medium/high confidence.
class TrendProteinUpRule implements InsightRule {
  /// Creates the rule.
  const TrendProteinUpRule();

  @override
  String get ruleId => 'TREND_PROTEIN_UP';

  @override
  InsightCandidate? evaluate(InsightContext context) {
    if (context.proteinGoalG <= 0) return null;

    final fullWindow = dateWindow(
      context.today,
      AiConstants.trendWindowDays * 2,
    );
    final prior = fullWindow.sublist(0, AiConstants.trendWindowDays);
    final recent = fullWindow.sublist(AiConstants.trendWindowDays);

    int logged(List<String> days) =>
        days.where(context.proteinGByDate.containsKey).length;
    // Silence over noise: both windows need enough data (docs/07 §4).
    if (logged(recent) < AiConstants.trendMinLoggedPerWindow ||
        logged(prior) < AiConstants.trendMinLoggedPerWindow) {
      return null;
    }

    int met(List<String> days) => days
        .where((d) => (context.proteinGByDate[d] ?? -1) >= context.proteinGoalG)
        .length;
    final metRecent = met(recent);
    final metPrior = met(prior);
    final improvement = metRecent - metPrior;
    if (improvement < AiConstants.trendProteinMinImprovementDays) return null;

    return InsightCandidate(
      ruleId: ruleId,
      category: InsightCategory.trend,
      title: 'Protein trending up',
      body:
          'You hit your protein goal $metRecent of '
          '${AiConstants.trendWindowDays} days this week — up from $metPrior '
          'the week before.',
      confidence: improvement >= AiConstants.trendProteinHighConfidenceDays
          ? Confidence.high
          : Confidence.medium,
      evidence: {
        'metRecent': metRecent,
        'metPrior': metPrior,
        'goalG': context.proteinGoalG,
      },
      periodStart: fullWindow.first,
      periodEnd: fullWindow.last,
    );
  }
}

/// `TREND_WEIGHT` — the moving trend of body weight over the last four weeks
/// (docs/07 §3). Descriptive, never predictive; adds a gentle non-diagnostic
/// note when the change is unusually fast.
class TrendWeightRule implements InsightRule {
  /// Creates the rule.
  const TrendWeightRule();

  @override
  String get ruleId => 'TREND_WEIGHT';

  @override
  InsightCandidate? evaluate(InsightContext context) {
    final window = dateWindow(context.today, AiConstants.weightTrendWindowDays);
    final points = [
      for (final d in window)
        if (context.weightKgByDate[d] case final w?) (date: d, kg: w),
    ];
    if (points.length < AiConstants.trendWeightMinPoints) return null;

    // Average the first and last few readings, then convert the change to
    // kg/week over the span between those endpoint midpoints.
    const k = AiConstants.weightEndpointWindow;
    final first = points.take(k).toList();
    final last = points.skip(points.length - k).toList();
    double mean(Iterable<({String date, double kg})> xs) =>
        xs.map((p) => p.kg).reduce((a, b) => a + b) / xs.length;
    double dayOf(({String date, double kg}) p) =>
        DateTime.parse(p.date).millisecondsSinceEpoch /
        Duration.millisecondsPerDay;
    final spanDays = dayOf(last[last.length ~/ 2]) - dayOf(first[k ~/ 2]);
    if (spanDays <= 0) return null;

    final slopeKgPerWeek = (mean(last) - mean(first)) / spanDays * 7;
    if (slopeKgPerWeek.abs() < AiConstants.weightSlopeMinKgPerWeek) {
      return null;
    }

    final direction = slopeKgPerWeek < 0 ? 'down' : 'up';
    final rapid = slopeKgPerWeek.abs() > AiConstants.weightRapidKgPerWeek;

    return InsightCandidate(
      ruleId: ruleId,
      category: InsightCategory.trend,
      title: 'Weight trend: $direction',
      body:
          'Your weight trend is gently $direction '
          '(~${slopeKgPerWeek.abs().toStringAsFixed(1)} kg/week) over the '
          'last month.'
          '${rapid ? ' That is a fast change — if it is unexpected, '
                    'consider reviewing your goals or speaking with a healthcare '
                    'professional.' : ''}',
      confidence: Confidence.medium,
      evidence: {
        'slopeKgPerWeek': slopeKgPerWeek,
        'points': points.length,
        'firstMeanKg': mean(first),
        'lastMeanKg': mean(last),
      },
      periodStart: window.first,
      periodEnd: window.last,
    );
  }
}
