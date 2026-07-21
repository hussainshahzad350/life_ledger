import 'package:flutter_test/flutter_test.dart';
import 'package:life_ledger/features/goals/domain/entities/goal.dart';
import 'package:life_ledger/features/reports/domain/report_models.dart';

void main() {
  final anchor = DateTime(2026, 7, 21);

  group('ReportWindow.of', () {
    test('day is a single date', () {
      final w = ReportWindow.of(ReportRange.day, anchor);
      expect(w.dates, ['2026-07-21']);
      expect(w.startDate, '2026-07-21');
      expect(w.endDate, '2026-07-21');
    });

    test('week spans seven trailing days ending on the anchor', () {
      final w = ReportWindow.of(ReportRange.week, anchor);
      expect(w.dates, hasLength(7));
      expect(w.startDate, '2026-07-15');
      expect(w.endDate, '2026-07-21');
    });

    test('month and year have the right length and cross boundaries', () {
      expect(ReportWindow.of(ReportRange.month, anchor).dates, hasLength(30));
      final year = ReportWindow.of(ReportRange.year, anchor);
      expect(year.dates, hasLength(365));
      expect(year.startDate, '2025-07-22');
    });
  });

  group('ReportSummary aggregates', () {
    ReportSummary summaryOf(List<DailyPoint> points) => ReportSummary(
      range: ReportRange.week,
      window: ReportWindow.of(ReportRange.week, anchor),
      points: points,
      goals: const [],
    );

    test('averages ignore days without a value', () {
      final s = summaryOf(const [
        DailyPoint(localDate: '2026-07-20'),
        DailyPoint(localDate: '2026-07-21', calories: 2000, proteinG: 100),
      ]);
      expect(s.avgCalories, 2000);
      expect(s.avgProteinG, 100);
      expect(s.avgWaterMl, isNull);
      expect(s.daysLogged, 1);
    });

    test('latestWeightKg walks back from the newest day', () {
      final s = summaryOf(const [
        DailyPoint(localDate: '2026-07-19', weightKg: 71),
        DailyPoint(localDate: '2026-07-20', weightKg: 70),
        DailyPoint(localDate: '2026-07-21'),
      ]);
      expect(s.latestWeightKg, 70);
    });

    test('totalExerciseMin sums across the window', () {
      final s = summaryOf(const [
        DailyPoint(localDate: '2026-07-20', exerciseMin: 20),
        DailyPoint(localDate: '2026-07-21', exerciseMin: 30),
      ]);
      expect(s.totalExerciseMin, 50);
    });

    test('targetFor returns null when there are no goals', () {
      final s = summaryOf(const [DailyPoint(localDate: '2026-07-21')]);
      expect(s.targetFor(GoalType.calories, '2026-07-21'), isNull);
    });
  });
}
