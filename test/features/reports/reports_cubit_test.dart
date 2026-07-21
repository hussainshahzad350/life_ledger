import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_ledger/core/error/failure.dart';
import 'package:life_ledger/core/error/result.dart';
import 'package:life_ledger/features/reports/domain/report_models.dart';
import 'package:life_ledger/features/reports/presentation/cubit/reports_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockReportRepository extends Mock implements ReportRepository {}

void main() {
  late MockReportRepository repo;
  const userId = 'u1';

  ReportSummary summaryFor(ReportRange range) => ReportSummary(
    range: range,
    window: ReportWindow.of(range, DateTime(2026, 7, 21)),
    points: const [DailyPoint(localDate: '2026-07-21', calories: 2000)],
    goals: const [],
  );

  ReportsCubit build() => ReportsCubit(repository: repo, userId: userId);

  setUp(() => repo = MockReportRepository());

  group('ReportsCubit (docs/08 F12)', () {
    blocTest<ReportsCubit, ReportsState>(
      'load fetches the week report by default',
      build: () {
        when(
          () => repo.summary(userId: userId, range: ReportRange.week),
        ).thenAnswer((_) async => Result.success(summaryFor(ReportRange.week)));
        return build();
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        const ReportsState(),
        isA<ReportsState>()
            .having((s) => s.loading, 'loading', false)
            .having((s) => s.error, 'error', false)
            .having((s) => s.summary?.range, 'range', ReportRange.week),
      ],
    );

    blocTest<ReportsCubit, ReportsState>(
      'setRange switches range and reloads',
      build: () {
        when(
          () => repo.summary(userId: userId, range: ReportRange.month),
        ).thenAnswer(
          (_) async => Result.success(summaryFor(ReportRange.month)),
        );
        return build();
      },
      act: (cubit) => cubit.setRange(ReportRange.month),
      expect: () => [
        const ReportsState(range: ReportRange.month),
        isA<ReportsState>()
            .having((s) => s.range, 'range', ReportRange.month)
            .having((s) => s.loading, 'loading', false),
      ],
      verify: (_) {
        verify(
          () => repo.summary(userId: userId, range: ReportRange.month),
        ).called(1);
      },
    );

    blocTest<ReportsCubit, ReportsState>(
      'load surfaces an error on failure',
      build: () {
        when(
          () => repo.summary(userId: userId, range: ReportRange.week),
        ).thenAnswer(
          (_) async => const Result.failure(DatabaseFailure('boom')),
        );
        return build();
      },
      act: (cubit) => cubit.load(),
      expect: () => [
        const ReportsState(),
        const ReportsState(loading: false, error: true),
      ],
    );
  });
}
