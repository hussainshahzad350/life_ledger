import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_ledger/core/ai/insight.dart';
import 'package:life_ledger/core/ai/insight_engine.dart';
import 'package:life_ledger/core/di/injector.dart';
import 'package:life_ledger/core/error/result.dart';
import 'package:life_ledger/features/insights/application/generate_insights.dart';
import 'package:life_ledger/features/insights/domain/insight_record.dart';
import 'package:life_ledger/features/insights/presentation/pages/insights_page.dart';

class FakeGateway implements InsightContextGateway {
  @override
  Future<Result<InsightContext>> buildContext(
    String userId, {
    int windowDays = 28,
  }) async => const Result.success(InsightContext(today: '2026-07-21'));
}

/// In-memory insight repo seeded with [_seed]; save is a no-op so the seeded
/// insights survive the page's regenerate-then-list load.
class FakeInsightRepository implements InsightRepository {
  FakeInsightRepository(this._records);
  final List<InsightRecord> _records;

  @override
  Future<Result<List<InsightRecord>>> active(String userId) async =>
      Result.success(_records.where((r) => !r.dismissed).toList());

  @override
  Future<Result<void>> save(String userId, List<InsightCandidate> a) async =>
      const Result.success(null);

  @override
  Future<Result<void>> setFeedback(String id, InsightFeedback feedback) async {
    final i = _records.indexWhere((r) => r.id == id);
    final r = _records[i];
    _records[i] = InsightRecord(
      id: r.id,
      ruleId: r.ruleId,
      category: r.category,
      title: r.title,
      body: r.body,
      confidence: r.confidence,
      evidence: r.evidence,
      periodStart: r.periodStart,
      periodEnd: r.periodEnd,
      feedback: feedback,
      dismissed: r.dismissed,
    );
    return const Result.success(null);
  }

  @override
  Future<Result<void>> dismiss(String id) async {
    _records.removeWhere((r) => r.id == id);
    return const Result.success(null);
  }
}

InsightRecord record({
  String id = 'i1',
  InsightCategory category = InsightCategory.trend,
  String title = 'Protein trending up',
  Confidence confidence = Confidence.high,
}) {
  return InsightRecord(
    id: id,
    ruleId: 'RULE_$id',
    category: category,
    title: title,
    body: 'An observation about $title.',
    confidence: confidence,
    evidence: const {'improvementDays': 3},
    periodStart: '2026-07-15',
    periodEnd: '2026-07-21',
  );
}

void main() {
  tearDown(getIt.reset);

  Future<void> pump(WidgetTester tester, List<InsightRecord> seed) async {
    final repo = FakeInsightRepository(seed);
    getIt
      ..registerSingleton<InsightRepository>(repo)
      ..registerSingleton<GenerateInsights>(
        GenerateInsights(
          gateway: FakeGateway(),
          repository: repo,
          engine: const InsightEngine([]),
        ),
      );
    await tester.pumpWidget(
      const MaterialApp(home: InsightsPage(userId: 'u1')),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the disclaimer and insight cards', (tester) async {
    await pump(tester, [
      record(),
      record(
        id: 'i2',
        category: InsightCategory.correlation,
        title: 'Sleep and mood',
        confidence: Confidence.medium,
      ),
    ]);
    expect(find.textContaining('not medical advice'), findsOneWidget);
    expect(find.text('Protein trending up'), findsOneWidget);
    expect(find.text('High confidence'), findsOneWidget);
    // The correlation card carries the extra hedge.
    expect(find.text('Association, not cause.'), findsOneWidget);
  });

  testWidgets('empty state guides the user', (tester) async {
    await pump(tester, []);
    expect(find.textContaining('No insights yet'), findsOneWidget);
  });

  testWidgets('why-tile reveals evidence', (tester) async {
    await pump(tester, [record()]);
    await tester.tap(find.text('Why?'));
    await tester.pumpAndSettle();
    expect(find.text('Improvement days'), findsOneWidget);
  });

  testWidgets('dismiss removes the card', (tester) async {
    await pump(tester, [record()]);
    expect(find.text('Protein trending up'), findsOneWidget);
    await tester.drag(find.text('Protein trending up'), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Protein trending up'), findsNothing);
  });
}
