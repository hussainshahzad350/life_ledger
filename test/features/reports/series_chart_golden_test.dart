import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_ledger/core/theme/tokens.dart';
import 'package:life_ledger/features/reports/presentation/widgets/series_chart.dart';

Widget _host({required Brightness brightness, required Widget child}) {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppTokens.seedColor,
    brightness: brightness,
  );
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(colorScheme: scheme, useMaterial3: true),
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 300,
          height: 160,
          child: RepaintBoundary(child: child),
        ),
      ),
    ),
  );
}

void main() {
  const bars = SeriesChart(
    values: [1800, 2100, null, 2000, 2400, 1950, 2200],
    color: Color(0xFF2E7D6B),
    targetValue: 2000,
  );
  const line = SeriesChart(
    values: [71.0, 70.8, null, 70.5, 70.2, 70.1, 69.8],
    color: Color(0xFFDD8452),
    mode: ChartMode.line,
  );

  group('SeriesChart goldens', () {
    testWidgets('bar chart with target — light', (tester) async {
      await tester.pumpWidget(_host(brightness: Brightness.light, child: bars));
      await expectLater(
        find.byType(SeriesChart),
        matchesGoldenFile('goldens/bar_chart_light.png'),
      );
    });

    testWidgets('bar chart with target — dark', (tester) async {
      await tester.pumpWidget(_host(brightness: Brightness.dark, child: bars));
      await expectLater(
        find.byType(SeriesChart),
        matchesGoldenFile('goldens/bar_chart_dark.png'),
      );
    });

    testWidgets('line chart — light', (tester) async {
      await tester.pumpWidget(_host(brightness: Brightness.light, child: line));
      await expectLater(
        find.byType(SeriesChart),
        matchesGoldenFile('goldens/line_chart_light.png'),
      );
    });

    testWidgets('line chart — dark', (tester) async {
      await tester.pumpWidget(_host(brightness: Brightness.dark, child: line));
      await expectLater(
        find.byType(SeriesChart),
        matchesGoldenFile('goldens/line_chart_dark.png'),
      );
    });
  });
}
