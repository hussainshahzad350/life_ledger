import 'package:life_ledger/core/ai/ai_constants.dart';
import 'package:life_ledger/core/ai/insight.dart';
import 'package:life_ledger/core/ai/insight_engine.dart';

/// `STREAK_WATER_MISS` — the water goal was missed on consecutive **logged**
/// days (docs/07 §3). An unlogged day is *not* assumed to be a miss
/// (missing ≠ zero); it simply ends the streak.
class StreakWaterMissRule implements InsightRule {
  /// Creates the rule.
  const StreakWaterMissRule();

  @override
  String get ruleId => 'STREAK_WATER_MISS';

  @override
  InsightCandidate? evaluate(InsightContext context) {
    if (context.waterGoalMl <= 0) return null;

    var streak = 0;
    // Walk backwards from today while logged-and-under-goal.
    for (final date in dateWindow(
      context.today,
      AiConstants.corrWindowDays,
    ).reversed) {
      final amount = context.waterMlByDate[date];
      if (amount == null || amount >= context.waterGoalMl) break;
      streak++;
    }
    if (streak < AiConstants.streakWaterMissMinDays) return null;

    final window = dateWindow(context.today, streak);
    return InsightCandidate(
      ruleId: ruleId,
      category: InsightCategory.streak,
      title: 'Water goal missed $streak days running',
      body:
          "You've been under your water goal $streak days in a row — "
          'small, earlier sips could make it easier.',
      confidence: Confidence.high,
      evidence: {'streakDays': streak, 'goalMl': context.waterGoalMl},
      periodStart: window.first,
      periodEnd: window.last,
    );
  }
}

/// `STREAK_LOG` — celebrated consecutive days of logging anything
/// (docs/07 §3). A *humane* streak: it celebrates, never punishes
/// (knowledge/psychology/streak-psychology.md).
class StreakLogRule implements InsightRule {
  /// Creates the rule.
  const StreakLogRule();

  @override
  String get ruleId => 'STREAK_LOG';

  @override
  InsightCandidate? evaluate(InsightContext context) {
    var streak = 0;
    for (final date in dateWindow(
      context.today,
      AiConstants.corrWindowDays,
    ).reversed) {
      if (!context.loggedDates.contains(date)) break;
      streak++;
    }
    if (streak < AiConstants.streakLogMinDays) return null;

    final window = dateWindow(context.today, streak);
    return InsightCandidate(
      ruleId: ruleId,
      category: InsightCategory.streak,
      title: '$streak-day logging streak',
      body:
          '$streak days of logging in a row — nice consistency. '
          'This is what makes your patterns visible.',
      confidence: Confidence.high,
      evidence: {'streakDays': streak},
      periodStart: window.first,
      periodEnd: window.last,
    );
  }
}
