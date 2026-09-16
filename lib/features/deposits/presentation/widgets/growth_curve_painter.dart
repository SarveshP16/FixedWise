import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/calculations/chart_point.dart';
import '../../../../core/theme/app_colors.dart';

/// Reproduces the mockup's Detail-screen SVG growth chart: a gradient-
/// filled area under a stroked curve, a dashed "today" line, and a marker
/// dot at the deposit's value-so-far.
class GrowthCurvePainter extends CustomPainter {
  GrowthCurvePainter({required this.points, required this.progressFraction}) : brightness = AppColors.brightness;

  /// Sampled points from `MaturityCalculator.growthCurvePoints`, oldest
  /// (opened) to newest (maturity).
  final List<ChartPoint> points;

  /// 0.0–1.0; the dashed "today" line and marker are only drawn strictly
  /// inside the term (not yet opened / already matured hide them).
  final double progressFraction;

  /// Captured at construction so [shouldRepaint] can tell a theme toggle
  /// apart from a no-op rebuild — every color this paints with comes from
  /// [AppColors], which [shouldRepaint] can't otherwise see since they
  /// aren't stored as fields here.
  final Brightness brightness;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2 || size.width <= 0 || size.height <= 0) return;

    final values = points.map((p) => p.value).toList();
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final range = (maxValue - minValue).abs() < 1e-9 ? 1.0 : maxValue - minValue;

    Offset pointAt(int i) {
      final x = size.width * i / (points.length - 1);
      final normalized = (values[i] - minValue) / range;
      // A little vertical padding so the curve never touches the edges.
      final y = size.height * (0.92 - normalized * 0.84);
      return Offset(x, y);
    }

    final line = Path()..moveTo(pointAt(0).dx, pointAt(0).dy);
    for (var i = 1; i < points.length; i++) {
      line.lineTo(pointAt(i).dx, pointAt(i).dy);
    }

    final fill = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.brass.withValues(alpha: 0.35), AppColors.brass.withValues(alpha: 0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    canvas.drawPath(
      line,
      Paint()
        ..color = AppColors.brassDeep
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );

    if (progressFraction > 0 && progressFraction < 1) {
      final todayX = size.width * progressFraction;
      _drawDashedLine(canvas, Offset(todayX, 0), Offset(todayX, size.height));

      final idxFloat = progressFraction * (points.length - 1);
      final i0 = idxFloat.floor().clamp(0, points.length - 1);
      final i1 = (i0 + 1).clamp(0, points.length - 1);
      final t = idxFloat - i0;
      final p0 = pointAt(i0);
      final p1 = pointAt(i1);
      final markerY = p0.dy + (p1.dy - p0.dy) * t;
      canvas.drawCircle(Offset(todayX, markerY), 3.5, Paint()..color = AppColors.brassDeep);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end) {
    const dashWidth = 3.0;
    const dashSpace = 3.0;
    final totalDistance = (end - start).distance;
    if (totalDistance == 0) return;
    final direction = (end - start) / totalDistance;
    final paint = Paint()
      ..color = AppColors.line
      ..strokeWidth = 1;
    var distance = 0.0;
    while (distance < totalDistance) {
      final from = start + direction * distance;
      final segmentEnd = math.min(distance + dashWidth, totalDistance);
      final to = start + direction * segmentEnd;
      canvas.drawLine(from, to, paint);
      distance += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant GrowthCurvePainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.progressFraction != progressFraction ||
        oldDelegate.brightness != brightness;
  }
}
