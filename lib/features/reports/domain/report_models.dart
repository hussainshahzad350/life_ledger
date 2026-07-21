import 'package:equatable/equatable.dart';
import 'package:life_ledger/core/error/result.dart';
import 'package:life_ledger/core/time/clock.dart';
import 'package:life_ledger/features/goals/domain/entities/goal.dart';

/// The time span a report covers (docs/08 F12, docs/05 §5.4).
///
/// Windows are trailing: they end on the anchor day and reach back
/// [days] − 1 days, so "week" is the last seven days including today.
enum ReportRange {
  /// A single day.
  day(1, 'Day'),

  /// The last 7 days.
  week(7, 'Week'),

  /// The last 30 days.
  month(30, 'Month'),

  /// The last 365 days.
  year(365, 'Year');

  const ReportRange(this.days, this.label);

  /// Number of calendar days in the window.
  final int days;

  /// Short human label for the range switch.
  final String label;
}

/// The inclusive local-date bounds of a [range] anchored on [anchorLocal].
class ReportWindow extends Equatable {
  /// Creates a window.
  const ReportWindow({
    required this.startDate,
    required this.endDate,
    required this.dates,
  });

  /// Builds the window for [range] ending on [anchorLocal].
  factory ReportWindow.of(ReportRange range, DateTime anchorLocal) {
    final anchor = DateTime(
      anchorLocal.year,
      anchorLocal.month,
      anchorLocal.day,
    );
    final dates = <String>[];
    for (var i = range.days - 1; i >= 0; i--) {
      dates.add(Clock.formatLocalDate(anchor.subtract(Duration(days: i))));
    }
    return ReportWindow(
      startDate: dates.first,
      endDate: dates.last,
      dates: dates,
    );
  }

  /// First day (`YYYY-MM-DD`), inclusive.
  final String startDate;

  /// Last day (`YYYY-MM-DD`), inclusive.
  final String endDate;

  /// Every day in the window, oldest first.
  final List<String> dates;

  @override
  List<Object?> get props => [startDate, endDate, dates];
}

/// One day's aggregated actuals across every tracker (docs/08 F12).
///
/// Absent metrics are null (no reading) rather than zero, so charts can tell
/// "logged nothing" apart from "logged a real zero".
class DailyPoint extends Equatable {
  /// Creates a point.
  const DailyPoint({
    required this.localDate,
    this.calories = 0,
    this.proteinG = 0,
    this.waterMl = 0,
    this.weightKg,
    this.sleepMin,
    this.moodAvg,
    this.exerciseMin = 0,
    this.symptomCount = 0,
  });

  /// The calendar day (`YYYY-MM-DD`).
  final String localDate;

  /// Total calories logged (kcal).
  final double calories;

  /// Total protein logged (g).
  final double proteinG;

  /// Total water logged (ml).
  final double waterMl;

  /// Mean weight reading for the day (kg), or null.
  final double? weightKg;

  /// Total sleep for the day (minutes), or null.
  final int? sleepMin;

  /// Mean mood for the day (1–5), or null.
  final double? moodAvg;

  /// Total exercise for the day (minutes).
  final int exerciseMin;

  /// Number of symptoms logged.
  final int symptomCount;

  /// Whether anything at all was logged this day.
  bool get hasAnyLog =>
      calories > 0 ||
      waterMl > 0 ||
      weightKg != null ||
      sleepMin != null ||
      moodAvg != null ||
      exerciseMin > 0 ||
      symptomCount > 0;

  @override
  List<Object?> get props => [
    localDate,
    calories,
    proteinG,
    waterMl,
    weightKg,
    sleepMin,
    moodAvg,
    exerciseMin,
    symptomCount,
  ];
}

/// A full report: the daily series plus the goals that were in force across
/// the window, so charts can draw goal-adherence honoring versioning
/// (docs/08 F12 business rules, FR-8).
class ReportSummary extends Equatable {
  /// Creates a summary.
  const ReportSummary({
    required this.range,
    required this.window,
    required this.points,
    required this.goals,
  });

  /// The range this report covers.
  final ReportRange range;

  /// The resolved date window.
  final ReportWindow window;

  /// One point per day, oldest first.
  final List<DailyPoint> points;

  /// Every goal version overlapping the window (any type).
  final List<Goal> goals;

  /// Days on which the user logged anything.
  int get daysLogged => points.where((p) => p.hasAnyLog).length;

  /// Mean of [selector] over the days that have a value, or null when none do.
  double? averageOf(num? Function(DailyPoint) selector) {
    final values = points.map(selector).whereType<num>().toList();
    if (values.isEmpty) return null;
    return values.fold<double>(0, (s, v) => s + v) / values.length;
  }

  /// Mean daily calories over days with any food logged.
  double? get avgCalories =>
      averageOf((p) => p.calories > 0 ? p.calories : null);

  /// Mean daily protein over days with any food logged.
  double? get avgProteinG =>
      averageOf((p) => p.calories > 0 ? p.proteinG : null);

  /// Mean daily water over days with any water logged.
  double? get avgWaterMl => averageOf((p) => p.waterMl > 0 ? p.waterMl : null);

  /// Total exercise minutes across the window.
  int get totalExerciseMin => points.fold<int>(0, (s, p) => s + p.exerciseMin);

  /// The most recent weight reading in the window, or null.
  double? get latestWeightKg {
    for (final p in points.reversed) {
      if (p.weightKg != null) return p.weightKg;
    }
    return null;
  }

  /// The target for [type] in force on [localDate], honoring goal versioning
  /// (the goal whose window contains noon of that day). Null when no goal
  /// applied. Sugar is a ceiling; callers interpret accordingly.
  double? targetFor(GoalType type, String localDate) {
    final parts = localDate.split('-').map(int.parse).toList();
    final instant = DateTime(
      parts[0],
      parts[1],
      parts[2],
      12,
    ).millisecondsSinceEpoch;
    Goal? best;
    for (final g in goals) {
      if (g.type != type) continue;
      final from = g.effectiveFrom.millisecondsSinceEpoch;
      final to = g.effectiveTo?.millisecondsSinceEpoch;
      if (from <= instant && (to == null || to > instant)) {
        if (best == null || g.effectiveFrom.isAfter(best.effectiveFrom)) {
          best = g;
        }
      }
    }
    return best?.targetValue;
  }

  @override
  List<Object?> get props => [range, window, points, goals];
}

/// Read-only reporting queries over every log table (docs/08 F12).
abstract interface class ReportRepository {
  /// Builds the [range] report for [userId], anchored on [anchor]
  /// (defaults to today).
  Future<Result<ReportSummary>> summary({
    required String userId,
    required ReportRange range,
    DateTime? anchor,
  });
}
