import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_ledger/core/ai/insight.dart';
import 'package:life_ledger/core/error/failure.dart';
import 'package:life_ledger/core/error/result.dart';
import 'package:life_ledger/features/insights/application/generate_insights.dart';
import 'package:life_ledger/features/insights/domain/insight_record.dart';
import 'package:life_ledger/features/insights/presentation/cubit/insights_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockGenerateInsights extends Mock implements GenerateInsights {}

class MockInsightRepository extends Mock implements InsightRepository {}

void main() {
  late MockGenerateInsights generate;
  late MockInsightRepository repo;
  const userId = 'u1';

  const insight = InsightRecord(
    id: 'i1',
    ruleId: 'STREAK_LOG',
    category: InsightCategory.streak,
    title: '7-day streak',
    body: 'Nice.',
    confidence: Confidence.high,
    evidence: {},
    periodStart: '2026-07-15',
    periodEnd: '2026-07-21',
  );

  InsightsCubit build() =>
      InsightsCubit(generate: generate, repository: repo, userId: userId);

  setUp(() {
    generate = MockGenerateInsights();
    repo = MockInsightRepository();
    when(
      () => generate(userId),
    ).thenAnswer((_) async => const Result.success(1));
  });

  group('InsightsCubit (docs/08 F11)', () {
    blocTest<InsightsCubit, InsightsState>(
      'load regenerates then lists active insights',
      build: () {
        when(
          () => repo.active(userId),
        ).thenAnswer((_) async => const Result.success([insight]));
        return build();
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        const InsightsState(),
        const InsightsState(insights: [insight], loading: false),
      ],
      verify: (_) {
        verify(() => generate(userId)).called(1);
        verify(() => repo.active(userId)).called(1);
      },
    );

    blocTest<InsightsCubit, InsightsState>(
      'a generation failure still shows stored insights',
      build: () {
        when(() => generate(userId)).thenAnswer(
          (_) async => const Result.failure(DatabaseFailure('boom')),
        );
        when(
          () => repo.active(userId),
        ).thenAnswer((_) async => const Result.success([insight]));
        return build();
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        const InsightsState(),
        const InsightsState(insights: [insight], loading: false),
      ],
    );

    blocTest<InsightsCubit, InsightsState>(
      'dismiss removes the insight and reloads',
      build: () {
        when(
          () => repo.dismiss('i1'),
        ).thenAnswer((_) async => const Result.success(null));
        when(
          () => repo.active(userId),
        ).thenAnswer((_) async => const Result.success([]));
        return build();
      },
      seed: () => const InsightsState(insights: [insight], loading: false),
      act: (cubit) => cubit.dismiss('i1'),
      expect: () => [const InsightsState(loading: false)],
      verify: (_) {
        verify(() => repo.dismiss('i1')).called(1);
      },
    );

    blocTest<InsightsCubit, InsightsState>(
      'giveFeedback records feedback and reloads',
      build: () {
        when(
          () => repo.setFeedback('i1', InsightFeedback.helpful),
        ).thenAnswer((_) async => const Result.success(null));
        when(
          () => repo.active(userId),
        ).thenAnswer((_) async => const Result.success([insight]));
        return build();
      },
      act: (cubit) => cubit.giveFeedback('i1', InsightFeedback.helpful),
      verify: (_) {
        verify(() => repo.setFeedback('i1', InsightFeedback.helpful)).called(1);
      },
    );
  });
}
