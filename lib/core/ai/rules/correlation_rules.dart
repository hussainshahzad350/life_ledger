import 'package:life_ledger/core/ai/ai_constants.dart';
import 'package:life_ledger/core/ai/correlation.dart';
import 'package:life_ledger/core/ai/insight.dart';
import 'package:life_ledger/core/ai/insight_engine.dart';

/// `CORR_FOOD_SYMPTOM` — a curated food flag co-occurs with a symptom above
/// chance (docs/07 §3/§5). Association only, hedged copy, capped at medium.
///
/// Observations are **logged** days only (missing ≠ symptom-free). The rule
/// evaluates only the curated pairs present in the context — never an
/// exhaustive sweep (anti-data-dredging, docs/07 §5).
class CorrFoodSymptomRule implements InsightRule {
  /// Creates the rule.
  const CorrFoodSymptomRule();

  @override
  String get ruleId => 'CORR_FOOD_SYMPTOM';

  @override
  InsightCandidate? evaluate(InsightContext context) {
    final window = dateWindow(context.today, AiConstants.corrWindowDays);
    final observedDays = window.where(context.loggedDates.contains).toList();
    if (observedDays.isEmpty) return null;

    InsightCandidate? best;
    var bestDifference = 0.0;

    for (final MapEntry(key: flag, value: flagDates)
        in context.foodFlagDates.entries) {
      for (final MapEntry(key: symptom, value: symptomDays)
          in context.symptomDates.entries) {
        final exposed = <double>[];
        final unexposed = <double>[];
        for (final day in observedDays) {
          final hadSymptom = symptomDays.contains(day) ? 1.0 : 0.0;
          (flagDates.contains(day) ? exposed : unexposed).add(hadSymptom);
        }

        final finding = compareExposure(exposed: exposed, unexposed: unexposed);
        if (finding == null || !finding.sufficientSample) continue;
        if (finding.difference < AiConstants.corrRateDifferenceMin) continue;
        if (finding.difference <= bestDifference) continue;

        final confidence =
            finding.difference >= AiConstants.corrRateDifferenceMedium &&
                finding.mediumSample
            ? Confidence.medium
            : Confidence.low;

        final exposedDaysWith = (finding.exposedMean * finding.exposedCount)
            .round();
        final unexposedDaysWith =
            (finding.unexposedMean * finding.unexposedCount).round();

        bestDifference = finding.difference;
        best = InsightCandidate(
          ruleId: ruleId,
          category: InsightCategory.correlation,
          title: 'Possible link: $flag and $symptom',
          body:
              "On days you logged '$flag', you reported $symptom more "
              'often ($exposedDaysWith of ${finding.exposedCount} days, vs '
              '$unexposedDaysWith of ${finding.unexposedCount} without). '
              'This is an association in your own data — many things affect '
              'how you feel, and this is not a medical finding.',
          confidence: confidence,
          evidence: {
            'flag': flag,
            'symptom': symptom,
            'exposedRate': finding.exposedMean,
            'unexposedRate': finding.unexposedMean,
            'exposedCount': finding.exposedCount,
            'unexposedCount': finding.unexposedCount,
          },
          periodStart: window.first,
          periodEnd: window.last,
        );
      }
    }
    return best;
  }
}

/// `CORR_SLEEP_MOOD` — short-sleep days associate with lower mood
/// (docs/07 §3). Association only, hedged, capped at medium.
class CorrSleepMoodRule implements InsightRule {
  /// Creates the rule.
  const CorrSleepMoodRule();

  @override
  String get ruleId => 'CORR_SLEEP_MOOD';

  @override
  InsightCandidate? evaluate(InsightContext context) {
    final window = dateWindow(context.today, AiConstants.corrWindowDays);

    final exposed = <double>[]; // mood after short sleep
    final unexposed = <double>[];
    for (final day in window) {
      final sleep = context.sleepMinutesByDate[day];
      final mood = context.moodByDate[day];
      if (sleep == null || mood == null) continue;
      (sleep < AiConstants.shortSleepMinutes ? exposed : unexposed).add(
        mood.toDouble(),
      );
    }

    final finding = compareExposure(exposed: exposed, unexposed: unexposed);
    if (finding == null || !finding.sufficientSample) return null;
    // Lower mood on short sleep = negative difference.
    if (-finding.difference < AiConstants.corrMoodDifferenceMin) return null;

    final confidence =
        -finding.difference >= AiConstants.corrMoodDifferenceMedium &&
            finding.mediumSample
        ? Confidence.medium
        : Confidence.low;

    const hours = AiConstants.shortSleepMinutes ~/ 60;
    return InsightCandidate(
      ruleId: ruleId,
      category: InsightCategory.correlation,
      title: 'Sleep and mood may be linked',
      body:
          'Your mood tends to be lower after nights under ${hours}h '
          '(average ${finding.exposedMean.toStringAsFixed(1)} vs '
          '${finding.unexposedMean.toStringAsFixed(1)} otherwise). '
          'An association in your own data, not a medical finding.',
      confidence: confidence,
      evidence: {
        'shortSleepMoodMean': finding.exposedMean,
        'normalSleepMoodMean': finding.unexposedMean,
        'shortNights': finding.exposedCount,
        'normalNights': finding.unexposedCount,
      },
      periodStart: window.first,
      periodEnd: window.last,
    );
  }
}
