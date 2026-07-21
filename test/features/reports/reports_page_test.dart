import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_ledger/core/di/injector.dart';
import 'package:life_ledger/core/error/result.dart';
import 'package:life_ledger/features/reports/domain/report_models.dart';
import 'package:life_ledger/features/reports/presentation/pages/reports_page.dart';
import 'package:life_ledger/features/reports/presentation/widgets/series_chart.dart';

/// In-memory report repo — no real DB, so the widget settles (docs/11 §6).
class FakeReportRepository implements ReportRepository {
  ReportRange? lastRange;

  @override
  Future<Result<ReportSummary>> summary({
    required String userId,
    required ReportRange range,
    DateTime? anchor,
  }) async {
    lastRange = range;
    final window = ReportWindow.of(range, DateTime(2026, 7, 21));
    final points = [
      for (final d in window.dates)
        DailyPoint(localDate: d, calories: 2000, waterMl: 1500, weightKg: 70),
    ];
    return Result.success(
      ReportSummary(
        range: range,
        window: window,
        points: points,
        goals: const [],
      ),
    );
  }
}

class EmptyReportRepository implements ReportRepository {
  @override
  Future<Result<ReportSummary>> summary({
    required String userId,
    required ReportRange range,
    DateTime? anchor,
  }) async {
    final window = ReportWindow.of(range, DateTime(2026, 7, 21));
    return Result.success(
      ReportSummary(
        range: range,
        window: window,
        points: [for (final d in window.dates) DailyPoint(localDate: d)],
        goals: const [],
      ),
    );
  }
}

void main() {
  tearDown(getIt.reset);

  Future<void> pump(WidgetTester tester, ReportRepository repo) async {
    getIt.registerSingleton<ReportRepository>(repo);
    await tester.pumpWidget(const MaterialApp(home: ReportsPage(userId: 'u1')));
    await tester.pumpAndSettle();
  }

  testWidgets('renders charts and stats for a populated range', (tester) async {
    await pump(tester, FakeReportRepository());
    expect(find.text('Days logged'), findsOneWidget);
    expect(find.text('Calories'), findsOneWidget);
    // At least the above-the-fold charts render; the rest lazy-build on scroll.
    expect(find.byType(SeriesChart), findsWidgets);

    // The Weight line chart is lower in the list — scroll it into view.
    await tester.scrollUntilVisible(find.text('Weight'), 200);
    expect(find.text('Weight'), findsOneWidget);
  });

  testWidgets('switching range asks the repository for the new range', (
    tester,
  ) async {
    final repo = FakeReportRepository();
    await pump(tester, repo);
    expect(repo.lastRange, ReportRange.week);

    await tester.tap(find.text('Month'));
    await tester.pumpAndSettle();
    expect(repo.lastRange, ReportRange.month);
  });

  testWidgets('empty range shows guidance', (tester) async {
    await pump(tester, EmptyReportRepository());
    expect(find.textContaining('Nothing logged'), findsOneWidget);
    expect(find.byType(SeriesChart), findsNothing);
  });
}
