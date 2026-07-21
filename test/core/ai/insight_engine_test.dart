import 'package:flutter_test/flutter_test.dart';
import 'package:life_ledger/core/ai/insight.dart';
import 'package:life_ledger/core/ai/insight_engine.dart';
import 'package:life_ledger/core/ai/rules/correlation_rules.dart';
import 'package:life_ledger/core/ai/rules/pattern_rules.dart';
import 'package:life_ledger/core/ai/rules/streak_rules.dart';
import 'package:life_ledger/core/ai/rules/trend_rules.dart';

/// Golden-dataset tests for the v1 rule catalog (docs/07 §3/§10): each rule
/// has a firing fixture and a silence fixture (thin data → no insight).
void main() {
  const today = '2026-07-21';

  // The 14-day window ending today: 2026-07-08 .. 2026-07-21.
  final last14 = dateWindow(today, 14);
  final priorWeek = last14.sublist(0, 7);
  final recentWeek = last14.sublist(7);

  group('TREND_PROTEIN_UP', () {
    const rule = TrendProteinUpRule();

    InsightContext contextWith({
      required int metPrior,
      required int metRecent,
    }) {
      final protein = <String, double>{
        for (var i = 0; i < 7; i++) priorWeek[i]: i < metPrior ? 100 : 50,
        for (var i = 0; i < 7; i++) recentWeek[i]: i < metRecent ? 100 : 50,
      };
      return InsightContext(
        today: today,
        proteinGByDate: protein,
        proteinGoalG: 100,
      );
    }

    test('fires medium on a 2→5 improvement (docs/07 example)', () {
      final candidate = rule.evaluate(contextWith(metPrior: 2, metRecent: 5))!;
      expect(candidate.ruleId, 'TREND_PROTEIN_UP');
      expect(candidate.confidence, Confidence.medium);
      expect(candidate.body, contains('5 of 7'));
      expect(candidate.evidence['metPrior'], 2);
      expect(candidate.evidence['metRecent'], 5);
    });

    test('fires high on a ≥4-day improvement', () {
      final candidate = rule.evaluate(contextWith(metPrior: 0, metRecent: 5))!;
      expect(candidate.confidence, Confidence.high);
    });

    test('silent without improvement or without a goal', () {
      expect(rule.evaluate(contextWith(metPrior: 5, metRecent: 5)), isNull);
      expect(rule.evaluate(const InsightContext(today: today)), isNull);
    });

    test('silent on thin data (fewer than 5 logged days per window)', () {
      final protein = <String, double>{
        for (var i = 0; i < 4; i++) recentWeek[i]: 100,
        for (var i = 0; i < 7; i++) priorWeek[i]: 50,
      };
      final context = InsightContext(
        today: today,
        proteinGByDate: protein,
        proteinGoalG: 100,
      );
      expect(rule.evaluate(context), isNull);
    });
  });

  group('TREND_WEIGHT', () {
    const rule = TrendWeightRule();

    test('fires on a steady downward trend with slope in evidence', () {
      const context = InsightContext(
        today: today,
        weightKgByDate: {
          '2026-06-24': 74.0,
          '2026-06-27': 73.9,
          '2026-06-30': 73.8,
          '2026-07-03': 73.6,
          '2026-07-06': 73.5,
          '2026-07-09': 73.4,
          '2026-07-12': 73.2,
          '2026-07-15': 73.1,
          '2026-07-18': 73.0,
          '2026-07-21': 72.8,
        },
      );
      final candidate = rule.evaluate(context)!;
      expect(candidate.title, contains('down'));
      final slope = candidate.evidence['slopeKgPerWeek']! as double;
      expect(slope, lessThan(0));
      expect(slope.abs(), greaterThan(0.15));
      // Not a rapid change: no clinician suggestion.
      expect(candidate.body, isNot(contains('healthcare professional')));
    });

    test('adds the gentle non-diagnostic note on rapid change', () {
      final context = InsightContext(
        today: today,
        weightKgByDate: {
          for (var i = 0; i < 10; i++)
            dateWindow(today, 28)[i * 3]: 80.0 - i * 0.8,
        },
      );
      final candidate = rule.evaluate(context)!;
      expect(candidate.body, contains('healthcare professional'));
      expect(candidate.body, isNot(contains('diagnos')));
    });

    test('silent with fewer than 8 weigh-ins', () {
      const context = InsightContext(
        today: today,
        weightKgByDate: {
          '2026-07-01': 74,
          '2026-07-08': 73.5,
          '2026-07-15': 73,
          '2026-07-21': 72.5,
        },
      );
      expect(rule.evaluate(context), isNull);
    });
  });

  group('STREAK_WATER_MISS', () {
    const rule = StreakWaterMissRule();

    test('fires after 4 consecutive logged misses', () {
      const context = InsightContext(
        today: today,
        waterGoalMl: 2000,
        waterMlByDate: {
          '2026-07-18': 900,
          '2026-07-19': 1100,
          '2026-07-20': 800,
          '2026-07-21': 1000,
        },
      );
      final candidate = rule.evaluate(context)!;
      expect(candidate.confidence, Confidence.high);
      expect(candidate.evidence['streakDays'], 4);
    });

    test('an unlogged day breaks the streak — missing is never a miss', () {
      const context = InsightContext(
        today: today,
        waterGoalMl: 2000,
        waterMlByDate: {
          // 2026-07-20 missing.
          '2026-07-18': 900,
          '2026-07-19': 1100,
          '2026-07-21': 1000,
        },
      );
      expect(rule.evaluate(context), isNull);
    });

    test('silent without a goal', () {
      expect(rule.evaluate(const InsightContext(today: today)), isNull);
    });
  });

  group('STREAK_LOG', () {
    const rule = StreakLogRule();

    test('fires at a 7-day logging streak, celebratory tone', () {
      final context = InsightContext(
        today: today,
        loggedDates: dateWindow(today, 7).toSet(),
      );
      final candidate = rule.evaluate(context)!;
      expect(candidate.title, contains('7-day'));
      expect(candidate.body.toLowerCase(), isNot(contains('fail')));
    });

    test('silent at 6 days', () {
      final context = InsightContext(
        today: today,
        loggedDates: dateWindow(today, 6).toSet(),
      );
      expect(rule.evaluate(context), isNull);
    });
  });

  group('CORR_FOOD_SYMPTOM', () {
    const rule = CorrFoodSymptomRule();

    InsightContext dairyBloating({required int exposedDays}) {
      final window = dateWindow(today, 28);
      final logged = window.take(20).toSet();
      final dairyDays = logged.take(exposedDays).toSet();
      final bloatingDays = <String>{
        // Symptom on most dairy days, and one non-dairy day.
        ...dairyDays.take((exposedDays * 0.75).round()),
        logged.last,
      };
      return InsightContext(
        today: today,
        loggedDates: logged,
        foodFlagDates: {'dairy': dairyDays},
        symptomDates: {'bloating': bloatingDays},
      );
    }

    test('fires low, hedged, with counts in the body and evidence', () {
      final candidate = rule.evaluate(dairyBloating(exposedDays: 8))!;
      expect(candidate.confidence, Confidence.low);
      expect(candidate.category, InsightCategory.correlation);
      expect(candidate.body, contains('association'));
      expect(candidate.body, contains('not a medical finding'));
      expect(candidate.evidence['flag'], 'dairy');
      expect(candidate.evidence['symptom'], 'bloating');
    });

    test('silent with too few exposed days (anti-noise, docs/07 §4)', () {
      expect(rule.evaluate(dairyBloating(exposedDays: 3)), isNull);
    });

    test('silent with no curated pairs at all', () {
      expect(rule.evaluate(const InsightContext(today: today)), isNull);
    });
  });

  group('CORR_SLEEP_MOOD', () {
    const rule = CorrSleepMoodRule();

    test('fires when short-sleep mood is clearly lower', () {
      final window = dateWindow(today, 28);
      final context = InsightContext(
        today: today,
        sleepMinutesByDate: {
          for (var i = 0; i < 6; i++) window[i]: 300, // short nights
          for (var i = 6; i < 14; i++) window[i]: 450,
        },
        moodByDate: {
          for (var i = 0; i < 6; i++) window[i]: 2,
          for (var i = 6; i < 14; i++) window[i]: 4,
        },
      );
      final candidate = rule.evaluate(context)!;
      expect(candidate.confidence, Confidence.low);
      expect(candidate.body, contains('tends to be lower'));
      expect(candidate.evidence['shortNights'], 6);
    });

    test('silent when the difference is small', () {
      final window = dateWindow(today, 28);
      final context = InsightContext(
        today: today,
        sleepMinutesByDate: {
          for (var i = 0; i < 6; i++) window[i]: 300,
          for (var i = 6; i < 14; i++) window[i]: 450,
        },
        moodByDate: {
          for (var i = 0; i < 6; i++) window[i]: 3,
          for (var i = 6; i < 14; i++) window[i]: 3,
        },
      );
      expect(rule.evaluate(context), isNull);
    });
  });

  group('GOAL_PROTEIN_GAP', () {
    const rule = GoalProteinGapRule();

    test('fires with the weekly percentage in the body', () {
      final week = dateWindow(today, 7);
      final context = InsightContext(
        today: today,
        proteinGoalG: 100,
        proteinGByDate: {
          week[0]: 60,
          week[1]: 60,
          week[2]: 70,
          week[3]: 50,
          week[4]: 60,
        },
      );
      final candidate = rule.evaluate(context)!;
      expect(candidate.body, contains('60%'));
      // Suggestion is an experiment, never a prescription (docs/07 §6).
      expect(candidate.body, contains('you could try'));
    });

    test('silent when adherence is at/above 80% or data is thin', () {
      final week = dateWindow(today, 7);
      final good = InsightContext(
        today: today,
        proteinGoalG: 100,
        proteinGByDate: {for (final d in week) d: 90},
      );
      expect(rule.evaluate(good), isNull);

      final thin = InsightContext(
        today: today,
        proteinGoalG: 100,
        proteinGByDate: {week[0]: 10, week[1]: 10},
      );
      expect(rule.evaluate(thin), isNull);
    });
  });

  group('HYDRATION_TIMING', () {
    const rule = HydrationTimingRule();

    List<WaterEvent> lateDay() => const [
      WaterEvent(hourOfDay: 8, amountMl: 250),
      WaterEvent(hourOfDay: 20, amountMl: 750),
      WaterEvent(hourOfDay: 21, amountMl: 750),
    ];

    test('fires when 5 of 7 days are late-clustered', () {
      final week = dateWindow(today, 7);
      final context = InsightContext(
        today: today,
        waterEventsByDate: {for (final d in week.take(5)) d: lateDay()},
      );
      final candidate = rule.evaluate(context)!;
      expect(candidate.confidence, Confidence.low);
      expect(candidate.evidence['lateDays'], 5);
    });

    test('silent at 4 late days', () {
      final week = dateWindow(today, 7);
      final context = InsightContext(
        today: today,
        waterEventsByDate: {for (final d in week.take(4)) d: lateDay()},
      );
      expect(rule.evaluate(context), isNull);
    });
  });

  group('InsightEngine (docs/07 §9/§10)', () {
    test('standard engine runs the full catalog over a rich context', () {
      final context = InsightContext(
        today: today,
        proteinGoalG: 100,
        proteinGByDate: {
          for (var i = 0; i < 7; i++) priorWeek[i]: i < 2 ? 100 : 50,
          for (var i = 0; i < 7; i++) recentWeek[i]: i < 5 ? 100 : 50,
        },
        loggedDates: dateWindow(today, 7).toSet(),
      );
      final result = InsightEngine.standard().run(context);
      final ruleIds = result.accepted.map((c) => c.ruleId).toSet();
      expect(ruleIds, contains('TREND_PROTEIN_UP'));
      expect(ruleIds, contains('STREAK_LOG'));
      expect(result.rejected, isEmpty);
    });

    test('an empty context produces silence, not noise', () {
      final result = InsightEngine.standard().run(
        const InsightContext(today: today),
      );
      expect(result.accepted, isEmpty);
      expect(result.rejected, isEmpty);
    });

    test('deterministic: identical contexts give identical output', () {
      final context = InsightContext(
        today: today,
        proteinGoalG: 100,
        proteinGByDate: {
          for (var i = 0; i < 7; i++) priorWeek[i]: i < 2 ? 100 : 50,
          for (var i = 0; i < 7; i++) recentWeek[i]: i < 5 ? 100 : 50,
        },
        loggedDates: dateWindow(today, 7).toSet(),
      );
      final engine = InsightEngine.standard();
      expect(engine.run(context), engine.run(context));
    });
  });

  group('dateWindow', () {
    test('returns count dates ending at the anchor, oldest first', () {
      final window = dateWindow('2026-07-21', 3);
      expect(window, ['2026-07-19', '2026-07-20', '2026-07-21']);
    });

    test('crosses month boundaries correctly', () {
      final window = dateWindow('2026-07-02', 4);
      expect(window, ['2026-06-29', '2026-06-30', '2026-07-01', '2026-07-02']);
    });
  });
}
