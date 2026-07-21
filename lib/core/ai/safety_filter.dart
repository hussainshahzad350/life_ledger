import 'package:equatable/equatable.dart';
import 'package:life_ledger/core/ai/insight.dart';

/// The mandatory output gate every insight passes before storage or display
/// (docs/07 §6, decisions/why-ai-is-not-a-doctor.md).
///
/// Generation is template-only, so this filter is defense-in-depth: it
/// rejects any candidate whose text drifts into diagnosis or prescription
/// territory, and it **caps correlation confidence at medium** so an
/// association can never masquerade as a strong claim.
abstract final class SafetyFilter {
  /// Lower-cased fragments that must never appear in insight text.
  /// Diagnosis language, disease naming, and prescriptive commands.
  static const List<String> deniedFragments = [
    'diagnos', // diagnose/diagnosis/diagnostic
    'disease',
    'disorder',
    'cancer',
    'diabet', // diabetes/diabetic
    'depression',
    'syndrome',
    'prescri', // prescribe/prescription
    'medication',
    'you must',
    'you have to',
    'stop eating', // prescriptive elimination
    'never eat',
    'cure',
    'treat your',
  ];

  /// Applies the gate to [candidates]: correlation confidence is capped at
  /// medium, and candidates containing denied language are rejected.
  static SafetyResult apply(List<InsightCandidate> candidates) {
    final accepted = <InsightCandidate>[];
    final rejected = <RejectedInsight>[];

    for (final candidate in candidates) {
      final text = '${candidate.title} ${candidate.body}'.toLowerCase();
      final hit = deniedFragments
          .where(text.contains)
          .cast<String?>()
          .firstWhere((_) => true, orElse: () => null);
      if (hit != null) {
        rejected.add(
          RejectedInsight(
            candidate: candidate,
            reason: 'contains denied language: "$hit"',
          ),
        );
        continue;
      }

      // Correlations are association-only: never above medium (docs/07 §4).
      final capped =
          candidate.category == InsightCategory.correlation &&
              candidate.confidence == Confidence.high
          ? InsightCandidate(
              ruleId: candidate.ruleId,
              category: candidate.category,
              title: candidate.title,
              body: candidate.body,
              confidence: Confidence.medium,
              evidence: candidate.evidence,
              periodStart: candidate.periodStart,
              periodEnd: candidate.periodEnd,
            )
          : candidate;

      accepted.add(capped);
    }

    return SafetyResult(accepted: accepted, rejected: rejected);
  }
}

/// A candidate the filter refused, with the reason (locally logged, never
/// shown as an insight).
class RejectedInsight extends Equatable {
  /// Creates a rejection record.
  const RejectedInsight({required this.candidate, required this.reason});

  /// The refused candidate.
  final InsightCandidate candidate;

  /// Why it was refused.
  final String reason;

  @override
  List<Object?> get props => [candidate, reason];
}

/// Output of [SafetyFilter.apply].
class SafetyResult extends Equatable {
  /// Creates a result.
  const SafetyResult({required this.accepted, required this.rejected});

  /// Candidates that passed (correlations capped at medium).
  final List<InsightCandidate> accepted;

  /// Candidates that were refused, with reasons.
  final List<RejectedInsight> rejected;

  @override
  List<Object?> get props => [accepted, rejected];
}
