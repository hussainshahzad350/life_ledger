import 'package:flutter_test/flutter_test.dart';
import 'package:life_ledger/core/ai/insight.dart';
import 'package:life_ledger/core/ai/insight_engine.dart';
import 'package:life_ledger/core/error/failure.dart';
import 'package:life_ledger/core/error/result.dart';
import 'package:life_ledger/features/insights/application/generate_insights.dart';
import 'package:life_ledger/features/insights/domain/insight_record.dart';

/// A rule that always fires — lets us assert the engine→filter→save pipeline.
class _AlwaysRule implements InsightRule {
  const _AlwaysRule();

  @override
  String get ruleId => 'ALWAYS';

  @override
  InsightCandidate? evaluate(InsightContext context) => InsightCandidate(
    ruleId: ruleId,
    category: InsightCategory.trend,
    title: 'Something happened',
    body: 'A factual observation.',
    confidence: Confidence.high,
    evidence: const {},
    periodStart: context.today,
    periodEnd: context.today,
  );
}

class FakeGateway implements InsightContextGateway {
  FakeGateway(this._result);
  final Result<InsightContext> _result;

  @override
  Future<Result<InsightContext>> buildContext(
    String userId, {
    int windowDays = 28,
  }) async => _result;
}

class RecordingRepository implements InsightRepository {
  List<InsightCandidate>? saved;

  @override
  Future<Result<void>> save(
    String userId,
    List<InsightCandidate> accepted,
  ) async {
    saved = accepted;
    return const Result.success(null);
  }

  @override
  Future<Result<List<InsightRecord>>> active(String userId) async =>
      const Result.success([]);

  @override
  Future<Result<void>> setFeedback(String id, InsightFeedback feedback) async =>
      const Result.success(null);

  @override
  Future<Result<void>> dismiss(String id) async => const Result.success(null);
}

void main() {
  const context = InsightContext(today: '2026-07-21');

  group('GenerateInsights (docs/08 F11)', () {
    test('runs the engine and saves accepted candidates', () async {
      final repo = RecordingRepository();
      final useCase = GenerateInsights(
        gateway: FakeGateway(const Result.success(context)),
        repository: repo,
        engine: const InsightEngine([_AlwaysRule()]),
      );

      final result = await useCase('u1');

      expect(result.valueOrNull, 1);
      expect(repo.saved, hasLength(1));
      expect(repo.saved!.single.ruleId, 'ALWAYS');
    });

    test('propagates a context-build failure without saving', () async {
      final repo = RecordingRepository();
      final useCase = GenerateInsights(
        gateway: FakeGateway(const Result.failure(DatabaseFailure('boom'))),
        repository: repo,
        engine: const InsightEngine([_AlwaysRule()]),
      );

      final result = await useCase('u1');

      expect(result.isFailure, isTrue);
      expect(repo.saved, isNull);
    });
  });
}
