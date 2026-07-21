import 'package:equatable/equatable.dart';
import 'package:life_ledger/core/ai/insight.dart';
import 'package:life_ledger/core/error/result.dart';

/// The user's reaction to an insight (docs/07, FR-30). Stored, never required.
enum InsightFeedback {
  /// The insight was useful.
  helpful,

  /// The insight missed the mark.
  unhelpful,
}

/// A persisted insight row (docs/04 §4.7): an engine [InsightCandidate] plus
/// the identity and user-state the engine does not own — its row id, the
/// user's feedback, and whether it has been dismissed.
class InsightRecord extends Equatable {
  /// Creates a record.
  const InsightRecord({
    required this.id,
    required this.ruleId,
    required this.category,
    required this.title,
    required this.body,
    required this.confidence,
    required this.evidence,
    required this.periodStart,
    required this.periodEnd,
    this.feedback,
    this.dismissed = false,
  });

  /// Row id (UUID).
  final String id;

  /// The rule that produced it (docs/07 §3).
  final String ruleId;

  /// The rule's category — drives the "association, not causation" note.
  final InsightCategory category;

  /// Plain-language headline.
  final String title;

  /// Plain-language explanation.
  final String body;

  /// Honest confidence (correlations never exceed medium).
  final Confidence confidence;

  /// The data points behind it (explainability, FR-29).
  final Map<String, Object?> evidence;

  /// First analyzed day (`YYYY-MM-DD`).
  final String periodStart;

  /// Last analyzed day (`YYYY-MM-DD`).
  final String periodEnd;

  /// The user's feedback, if given.
  final InsightFeedback? feedback;

  /// Whether the user dismissed it.
  final bool dismissed;

  /// Whether this is an association (never causal), needing the extra hedge.
  bool get isCorrelation => category == InsightCategory.correlation;

  @override
  List<Object?> get props => [
    id,
    ruleId,
    category,
    title,
    body,
    confidence,
    evidence,
    periodStart,
    periodEnd,
    feedback,
    dismissed,
  ];
}

/// Persistence for generated insights (docs/08 F11).
abstract interface class InsightRepository {
  /// Active (non-dismissed) insights, most recent period first.
  Future<Result<List<InsightRecord>>> active(String userId);

  /// Idempotently stores the freshly [accepted] candidates for [userId]:
  /// each rule keeps at most one current insight, dismissed rules stay
  /// dismissed, and rules that no longer fire are cleared (docs/07 §10).
  Future<Result<void>> save(String userId, List<InsightCandidate> accepted);

  /// Records the user's [feedback] on an insight.
  Future<Result<void>> setFeedback(String insightId, InsightFeedback feedback);

  /// Marks an insight dismissed so it does not reappear on regeneration.
  Future<Result<void>> dismiss(String insightId);
}

/// Builds the [InsightContext] the engine consumes from persisted data
/// (docs/07 §3 — the bridge from storage to the pure rule set).
abstract interface class InsightContextGateway {
  /// Assembles the analysis context for [userId] over the trailing
  /// [windowDays] days (defaults to the engine's analysis window).
  Future<Result<InsightContext>> buildContext(String userId, {int windowDays});
}
