import 'package:life_ledger/core/ai/insight.dart';
import 'package:life_ledger/core/ai/rules/correlation_rules.dart';
import 'package:life_ledger/core/ai/rules/pattern_rules.dart';
import 'package:life_ledger/core/ai/rules/streak_rules.dart';
import 'package:life_ledger/core/ai/rules/trend_rules.dart';
import 'package:life_ledger/core/ai/safety_filter.dart';

/// One insight rule: pure `context → candidate?` (docs/07 §3).
///
/// Returning null means silence — the rule's trigger or minimum-sample
/// requirements were not met (silence over noise, docs/07 §4).
abstract interface class InsightRule {
  /// Stable identifier stored on the `insight` row (docs/04 §4.7).
  String get ruleId;

  /// Evaluates the rule; null when it does not fire.
  InsightCandidate? evaluate(InsightContext context);
}

/// The deterministic Phase-1 insight engine (docs/07, ADR-0007):
/// runs every registered rule over a context and passes the candidates
/// through the mandatory [SafetyFilter].
class InsightEngine {
  /// Creates an engine over an explicit rule set (tests may inject subsets).
  const InsightEngine(this.rules);

  /// The engine with the full v1 rule catalog (docs/07 §3).
  factory InsightEngine.standard() => const InsightEngine([
    TrendProteinUpRule(),
    TrendWeightRule(),
    StreakWaterMissRule(),
    StreakLogRule(),
    CorrFoodSymptomRule(),
    CorrSleepMoodRule(),
    GoalProteinGapRule(),
    HydrationTimingRule(),
  ]);

  /// The rules this engine evaluates, in order.
  final List<InsightRule> rules;

  /// Runs all rules and applies the safety gate. Deterministic: identical
  /// contexts produce identical results (docs/07 §10).
  SafetyResult run(InsightContext context) {
    final candidates = <InsightCandidate>[
      for (final rule in rules) ?rule.evaluate(context),
    ];
    return SafetyFilter.apply(candidates);
  }
}
