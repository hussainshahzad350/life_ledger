import 'package:flutter_test/flutter_test.dart';
import 'package:life_ledger/core/ai/insight.dart';
import 'package:life_ledger/core/database/app_database.dart';
import 'package:life_ledger/core/time/clock.dart';
import 'package:life_ledger/features/insights/domain/insight_record.dart';
import 'package:life_ledger/features/insights/infrastructure/insight_repository_impl.dart';

import '../../../support/fakes.dart';

void main() {
  late AppDatabase db;
  late SequentialIds ids;
  const userId = 'u1';

  setUp(() async {
    db = await openTestDatabase();
    ids = SequentialIds();
    await seedUser(db, userId);
  });

  tearDown(() => db.close());

  InsightRepositoryImpl repo() => InsightRepositoryImpl(
    db: db,
    clock: FixedClock(DateTime.utc(2026, 7, 21)),
    ids: ids,
  );

  InsightCandidate candidate({
    String ruleId = 'TREND_PROTEIN_UP',
    InsightCategory category = InsightCategory.trend,
    String title = 'Protein trending up',
    Confidence confidence = Confidence.high,
  }) {
    return InsightCandidate(
      ruleId: ruleId,
      category: category,
      title: title,
      body: 'You hit your protein goal more often this week.',
      confidence: confidence,
      evidence: const {'improvementDays': 3, 'rate': 0.75},
      periodStart: '2026-07-08',
      periodEnd: '2026-07-21',
    );
  }

  group('InsightRepositoryImpl (docs/08 F11)', () {
    test(
      'save then active round-trips category, confidence and evidence',
      () async {
        await repo().save(userId, [candidate()]);
        final active = (await repo().active(userId)).valueOrNull!;
        expect(active, hasLength(1));
        final i = active.single;
        expect(i.ruleId, 'TREND_PROTEIN_UP');
        expect(i.category, InsightCategory.trend);
        expect(i.confidence, Confidence.high);
        expect(i.evidence['improvementDays'], 3);
        expect(i.evidence['rate'], 0.75);
        expect(i.periodStart, '2026-07-08');
        expect(i.periodEnd, '2026-07-21');
        expect(i.isCorrelation, isFalse);
      },
    );

    test(
      'regeneration is idempotent per rule (updates, no duplicates)',
      () async {
        await repo().save(userId, [candidate()]);
        await repo().save(userId, [candidate(title: 'Protein climbing')]);
        final active = (await repo().active(userId)).valueOrNull!;
        expect(active, hasLength(1));
        expect(active.single.title, 'Protein climbing');
      },
    );

    test('a rule that stops firing is cleared', () async {
      await repo().save(userId, [candidate()]);
      await repo().save(userId, const []);
      expect((await repo().active(userId)).valueOrNull, isEmpty);
    });

    test('dismissed insights stay gone across regeneration', () async {
      await repo().save(userId, [candidate()]);
      final id = (await repo().active(userId)).valueOrNull!.single.id;
      await repo().dismiss(id);
      expect((await repo().active(userId)).valueOrNull, isEmpty);

      // Same rule fires again — must not resurrect.
      await repo().save(userId, [candidate()]);
      expect((await repo().active(userId)).valueOrNull, isEmpty);
    });

    test('feedback is stored and read back', () async {
      await repo().save(userId, [candidate()]);
      final id = (await repo().active(userId)).valueOrNull!.single.id;
      await repo().setFeedback(id, InsightFeedback.helpful);
      final i = (await repo().active(userId)).valueOrNull!.single;
      expect(i.feedback, InsightFeedback.helpful);
    });

    test('correlation category round-trips and flags isCorrelation', () async {
      await repo().save(userId, [
        candidate(
          ruleId: 'CORR_SLEEP_MOOD',
          category: InsightCategory.correlation,
          confidence: Confidence.medium,
        ),
      ]);
      final i = (await repo().active(userId)).valueOrNull!.single;
      expect(i.category, InsightCategory.correlation);
      expect(i.isCorrelation, isTrue);
    });

    test('two distinct rules coexist', () async {
      await repo().save(userId, [
        candidate(),
        candidate(
          ruleId: 'STREAK_LOG',
          category: InsightCategory.streak,
          title: '7-day streak',
        ),
      ]);
      final active = (await repo().active(userId)).valueOrNull!;
      expect(active.map((i) => i.ruleId).toSet(), {
        'TREND_PROTEIN_UP',
        'STREAK_LOG',
      });
    });
  });
}
