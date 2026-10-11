import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A compact multicolor G rendered without network or an image dependency.
class GoogleMark extends StatelessWidget {
  const GoogleMark({super.key});
  @override
  Widget build(BuildContext context) => const ExcludeSemantics(
    child: SizedBox.square(
      dimension: 24,
      child: CustomPaint(painter: _GoogleMarkPainter()),
    ),
  );
}

class _GoogleMarkPainter extends CustomPainter {
  const _GoogleMarkPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final circle = Rect.fromLTWH(3, 3, size.width - 6, size.height - 6);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5;
    for (final sector in [
      (0.15, 0.65, const Color(0xFF4285F4)),
      (0.8, 1.8, const Color(0xFF34A853)),
      (2.6, 1.0, const Color(0xFFFBBC05)),
      (3.6, 1.85, const Color(0xFFEA4335)),
    ]) {
      paint.color = sector.$3;
      canvas.drawArc(circle, sector.$1, sector.$2, false, paint);
    }
    paint.color = const Color(0xFF4285F4);
    canvas.drawLine(
      Offset(size.width / 2, size.height / 2),
      Offset(size.width - 1, size.height / 2),
      paint,
    );
    canvas.drawArc(circle, 0, math.pi / 5, false, paint);
  }

  @override
  bool shouldRepaint(covariant _GoogleMarkPainter oldDelegate) => false;
}
