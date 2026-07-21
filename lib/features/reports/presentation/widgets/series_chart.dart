import 'package:flutter/material.dart';
import 'package:life_ledger/core/theme/tokens.dart';

/// How a [SeriesChart] draws its series.
enum ChartMode {
  /// Vertical bars, one per value — good for daily totals.
  bar,

  /// A connected line — good for trends like weight.
  line,
}

/// A small, dependency-free chart for a single daily series (docs/08 F12).
///
/// Values map one-to-one to days, oldest first; a null value is a gap (no
/// data) and is skipped rather than drawn as zero. An optional [targetValue]
/// draws a horizontal goal line so goal adherence is visible at a glance.
/// Colours come from the caller (the dataviz palette, [AppTokens.dataViz]) so
/// the widget renders correctly in both themes.
class SeriesChart extends StatelessWidget {
  /// Creates a chart.
  const SeriesChart({
    required this.values,
    required this.color,
    this.targetValue,
    this.mode = ChartMode.bar,
    this.height = 140,
    super.key,
  });

  /// One value per day, oldest first; null = no data that day.
  final List<double?> values;

  /// Series colour (from [AppTokens.dataViz]).
  final Color color;

  /// Optional horizontal goal line.
  final double? targetValue;

  /// Bar or line rendering.
  final ChartMode mode;

  /// Chart height in logical pixels.
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasData = values.any((v) => v != null);
    return SizedBox(
      height: height,
      width: double.infinity,
      child: hasData
          ? CustomPaint(
              painter: _SeriesPainter(
                values: values,
                color: color,
                targetValue: targetValue,
                mode: mode,
                axisColor: scheme.outlineVariant,
                targetColor: scheme.outline,
              ),
            )
          : Center(
              child: Text(
                'No data for this range',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
    );
  }
}

class _SeriesPainter extends CustomPainter {
  _SeriesPainter({
    required this.values,
    required this.color,
    required this.targetValue,
    required this.mode,
    required this.axisColor,
    required this.targetColor,
  });

  final List<double?> values;
  final Color color;
  final double? targetValue;
  final ChartMode mode;
  final Color axisColor;
  final Color targetColor;

  @override
  void paint(Canvas canvas, Size size) {
    final present = values.whereType<double>().toList();
    if (present.isEmpty) return;

    var maxV = present.reduce((a, b) => a > b ? a : b);
    var minV = present.reduce((a, b) => a < b ? a : b);
    if (targetValue case final t?) {
      if (t > maxV) maxV = t;
      if (t < minV) minV = t;
    }
    // Bars grow from a zero baseline; lines frame the data range.
    if (mode == ChartMode.bar && minV > 0) minV = 0;
    if (maxV == minV) maxV = minV + 1; // avoid divide-by-zero on flat series.

    final range = maxV - minV;
    double y(double v) => size.height - ((v - minV) / range) * size.height;

    final axisPaint = Paint()
      ..color = axisColor
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height - 0.5),
      Offset(size.width, size.height - 0.5),
      axisPaint,
    );

    if (targetValue case final t?) {
      final ty = y(t);
      final dashPaint = Paint()
        ..color = targetColor
        ..strokeWidth = 1;
      const dash = 6.0;
      for (var x = 0.0; x < size.width; x += dash * 2) {
        canvas.drawLine(Offset(x, ty), Offset(x + dash, ty), dashPaint);
      }
    }

    final n = values.length;
    if (mode == ChartMode.bar) {
      final slot = size.width / n;
      final barWidth = slot * 0.6;
      final paint = Paint()..color = color;
      for (var i = 0; i < n; i++) {
        final v = values[i];
        if (v == null) continue;
        final left = slot * i + (slot - barWidth) / 2;
        final top = y(v);
        final rect = Rect.fromLTRB(left, top, left + barWidth, size.height);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(2)),
          paint,
        );
      }
    } else {
      final linePaint = Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round;
      final dotPaint = Paint()..color = color;
      final path = Path();
      var started = false;
      final step = n > 1 ? size.width / (n - 1) : 0.0;
      for (var i = 0; i < n; i++) {
        final v = values[i];
        if (v == null) continue;
        final px = step * i;
        final py = y(v);
        if (!started) {
          path.moveTo(px, py);
          started = true;
        } else {
          path.lineTo(px, py);
        }
        canvas.drawCircle(Offset(px, py), 2.5, dotPaint);
      }
      canvas.drawPath(path, linePaint);
    }
  }

  @override
  bool shouldRepaint(_SeriesPainter old) =>
      old.values != values ||
      old.color != color ||
      old.targetValue != targetValue ||
      old.mode != mode ||
      old.axisColor != axisColor ||
      old.targetColor != targetColor;
}
