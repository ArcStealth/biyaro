import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/trip.dart';
import '../theme.dart';

/// Draws the ride as a line coloured by speed (green = slow, red = fast).
/// Works fully offline: no map tiles or API keys.
class RoutePainter extends CustomPainter {
  RoutePainter(this.pts);
  final List<RoutePoint> pts;

  @override
  void paint(Canvas canvas, Size size) {
    if (pts.length < 2) {
      final tp = TextPainter(
        text: const TextSpan(
          text: 'Your route shows up here once you move',
          style: TextStyle(color: BColors.muted, fontSize: 13),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: math.max(10.0, size.width - 20));
      tp.paint(canvas, Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2));
      return;
    }
    double minLat = 90, maxLat = -90, minLng = 180, maxLng = -180;
    for (final p in pts) {
      minLat = math.min(minLat, p.lat);
      maxLat = math.max(maxLat, p.lat);
      minLng = math.min(minLng, p.lng);
      maxLng = math.max(maxLng, p.lng);
    }
    final k = math.cos((minLat + maxLat) / 2 * math.pi / 180);
    final sx = math.max((maxLng - minLng) * k, 1e-6);
    final sy = math.max(maxLat - minLat, 1e-6);
    const pad = 20.0;
    final sc = math.min((size.width - 2 * pad) / sx, (size.height - 2 * pad) / sy);
    final ox = (size.width - sx * sc) / 2;
    final oy = (size.height - sy * sc) / 2;
    Offset o(RoutePoint p) => Offset(ox + (p.lng - minLng) * k * sc, size.height - oy - (p.lat - minLat) * sc);

    final paint = Paint()
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (var i = 1; i < pts.length; i++) {
      final hue = (150 - pts[i].speed * 5).clamp(0, 150).toDouble();
      paint.color = HSLColor.fromAHSL(1, hue, 0.85, 0.55).toColor();
      canvas.drawLine(o(pts[i - 1]), o(pts[i]), paint);
    }
    canvas.drawCircle(o(pts.first), 6, Paint()..color = const Color(0xFF2FD27A));
    canvas.drawCircle(o(pts.last), 6, Paint()..color = BColors.red);
  }

  @override
  bool shouldRepaint(covariant RoutePainter old) => true;
}
