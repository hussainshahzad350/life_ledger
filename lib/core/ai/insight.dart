import 'package:equatable/equatable.dart';

/// Confidence attached to every insight — uncertainty is mandatory
/// (docs/07 §1/§4; FR-28).
enum Confidence {
  /// Minimum viable sample; weak/short pattern.
  low,

  /// Larger sample and clearer effect. The **cap for correlations**.
  medium,

  /// Robust, factual patterns (streaks/trends) only.
  high,
}

/// The category of a rule, governing its confidence policy (docs/07 §4).
enum InsightCategory {
  /// Factual trend over the user's own series.
  trend,

  /// Factual streak/habit observation.
  streak,

  /// Association between two series — capped at [Confidence.medium],
  /// always hedged, never causal.
  correlation,

  /// Goal-threshold observation.
  threshold,

  /// Behavioral pattern (e.g., timing).
  pattern,
}

/// A generated insight, ready for the safety filter and then storage
/// (docs/04 §4.7 `insight` row).
class InsightCandidate extends Equatable {
  /// Creates a candidate.
  const InsightCandidate({
    required this.ruleId,
    required this.category,
    required this.title,
    required this.body,
    required this.confidence,
    required this.evidence,
    required this.periodStart,
    required this.periodEnd,
  });

  /// Stable rule identifier (docs/07 §3 catalog).
  final String ruleId;

  /// The rule's category (drives the confidence policy).
  final InsightCategory category;

  /// Plain-language headline.
  final String title;

  /// Plain-language explanation — template-generated only (docs/07 §6).
  final String body;

  /// Honest confidence (correlations never exceed medium).
  final Confidence confidence;

  /// The data points that produced this insight (explainability, FR-29).
  final Map<String, Object?> evidence;

  /// First local date (YYYY-MM-DD) of the analyzed window.
  final String periodStart;

  /// Last local date (YYYY-MM-DD) of the analyzed window.
  final String periodEnd;

  @override
  List<Object?> get props => [
    ruleId,
    category,
    title,
    body,
    confidence,
    evidence,
    periodStart,
    periodEnd,
  ];
}

/// One timed water event within a day (for timing analysis).
class WaterEvent extends Equatable {
  /// Creates an event at [hourOfDay] (0–23, local) of [amountMl].
  const WaterEvent({required this.hourOfDay, required this.amountMl});

  /// Local hour of day the water was logged.
  final int hourOfDay;

  /// Amount in ml.
  final double amountMl;

  @override
  List<Object?> get props => [hourOfDay, amountMl];
}

/// Everything the rule set may look at, pre-aggregated by local date
/// (`YYYY-MM-DD`). Missing dates mean **not logged** — never assumed zero
/// (docs/07 §3 failure cases).
class InsightContext extends Equatable {
  /// Creates a context anchored at [today] (inclusive analysis end).
  const InsightContext({
    required this.today,
    this.proteinGByDate = const {},
    this.proteinGoalG = 0,
    this.waterMlByDate = const {},
    this.waterGoalMl = 0,
    this.weightKgByDate = const {},
    this.moodByDate = const {},
    this.sleepMinutesByDate = const {},
    this.loggedDates = const {},
    this.foodFlagDates = const {},
    this.symptomDates = const {},
    this.waterEventsByDate = const {},
  });

  /// Anchor local date (the analysis runs backwards from here).
  final String today;

  /// Daily protein intake in grams.
  final Map<String, double> proteinGByDate;

  /// The protein goal in force (goal versioning arrives with M2 wiring).
  final double proteinGoalG;

  /// Daily water intake in ml.
  final Map<String, double> waterMlByDate;

  /// The water goal in force (ml).
  final double waterGoalMl;

  /// Daily weight readings in kg (latest per day).
  final Map<String, double> weightKgByDate;

  /// Daily mood 1–5.
  final Map<String, int> moodByDate;

  /// Daily sleep duration in minutes.
  final Map<String, int> sleepMinutesByDate;

  /// Dates with at least one entry of any kind (logging streak input).
  final Set<String> loggedDates;

  /// Food flag → the set of dates it was logged (curated pairs only,
  /// docs/07 §5 anti-dredging rule).
  final Map<String, Set<String>> foodFlagDates;

  /// Symptom name → the set of dates it was reported.
  final Map<String, Set<String>> symptomDates;

  /// Date → timed water events (for HYDRATION_TIMING).
  final Map<String, List<WaterEvent>> waterEventsByDate;

  @override
  List<Object?> get props => [
    today,
    proteinGByDate,
    proteinGoalG,
    waterMlByDate,
    waterGoalMl,
    weightKgByDate,
    moodByDate,
    sleepMinutesByDate,
    loggedDates,
    foodFlagDates,
    symptomDates,
    waterEventsByDate,
  ];
}

/// Returns the [count] local dates ending at [anchor] inclusive
/// (oldest first). Dates are `YYYY-MM-DD`.
List<String> dateWindow(String anchor, int count) {
  final end = DateTime.parse(anchor);
  return List.generate(count, (i) {
    final d = end.subtract(Duration(days: count - 1 - i));
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  });
}
