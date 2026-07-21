/// Named thresholds of the insight engine — no magic numbers
/// (docs/07-ai-rules.md §4). Product defaults, documented and unit-tested;
/// any change is an ADR.
abstract final class AiConstants {
  // Trend rules (docs/07 §3 TREND_*).

  /// Days in each comparison window for protein trends (current vs. prior).
  static const int trendWindowDays = 7;

  /// Minimum logged days per window before a trend may fire (silence over
  /// noise — docs/07 §4).
  static const int trendMinLoggedPerWindow = 5;

  /// Minimum improvement in goal-met days between windows to call it a trend.
  static const int trendProteinMinImprovementDays = 2;

  /// Improvement (in days) at or above which a protein trend is high
  /// confidence instead of medium.
  static const int trendProteinHighConfidenceDays = 4;

  /// Minimum weigh-ins required for a weight trend.
  static const int trendWeightMinPoints = 8;

  /// Analysis span for the weight trend (four weeks of readings).
  static const int weightTrendWindowDays = 28;

  /// Analysis span for correlation rules (four weeks of observations).
  static const int corrWindowDays = 28;

  /// Minimum |slope| in kg/week for a weight trend to be worth reporting.
  static const double weightSlopeMinKgPerWeek = 0.15;

  /// |slope| beyond which the message adds a gentle "consider reviewing
  /// goals / a clinician for rapid unexplained change" warning — never a
  /// diagnosis (docs/07 §6).
  static const double weightRapidKgPerWeek = 1.0;

  /// Sub-window length used to average the endpoints of a weight series.
  static const int weightEndpointWindow = 3;

  // Streak rules (docs/07 §3 STREAK_*).

  /// Consecutive missed water days that trigger the water-miss streak.
  static const int streakWaterMissMinDays = 3;

  /// Consecutive logged days that trigger the logging-streak celebration.
  static const int streakLogMinDays = 7;

  // Correlation rules (docs/07 §4/§5).

  /// Minimum exposed days for any correlation.
  static const int minExposedDays = 5;

  /// Minimum unexposed (comparison) days for any correlation.
  static const int minUnexposedDays = 5;

  /// Sample size per group at which a correlation may reach medium.
  static const int mediumConfidenceSample = 10;

  /// Minimum difference in symptom day-rate (0..1) to report food↔symptom.
  static const double corrRateDifferenceMin = 0.25;

  /// Rate difference at/above which (with sufficient sample) confidence may
  /// be medium instead of low. Correlations never exceed medium (docs/07 §4).
  static const double corrRateDifferenceMedium = 0.40;

  /// Minimum mean-mood difference (1–5 scale) for sleep↔mood.
  static const double corrMoodDifferenceMin = 0.8;

  /// Mood difference at/above which confidence may be medium.
  static const double corrMoodDifferenceMedium = 1.2;

  /// "Short sleep" threshold in minutes (< 6 h — knowledge/sleep.md).
  static const int shortSleepMinutes = 360;

  // Threshold / pattern rules.

  /// Weekly protein adherence below this share of goal fires the gap rule.
  static const double proteinGapPct = 0.80;

  /// Hour of day (local, 24h) after which water counts as "late".
  static const int lateHour = 18;

  /// Share of a day's water after [lateHour] for the day to count as
  /// late-clustered.
  static const double lateSharePct = 0.60;

  /// Late-clustered days (within the analysis week) needed to fire
  /// HYDRATION_TIMING.
  static const int lateDaysMin = 5;

  /// Minimum water events on a day for its timing to be analyzable.
  static const int minWaterEventsPerDay = 2;

  /// Analysis window for weekly pattern rules.
  static const int patternWindowDays = 7;
}
