import 'dart:math' as math;

import 'package:flutter/material.dart';

class MatchSparklePainter extends CustomPainter {
  MatchSparklePainter(this.progress);
  final double progress;
  static const _points = <Offset>[
    Offset(.14, .20),
    Offset(.82, .19),
    Offset(.22, .35),
    Offset(.76, .36),
    Offset(.10, .47),
    Offset(.91, .43),
    Offset(.37, .13),
    Offset(.64, .13),
    Offset(.08, .68),
    Offset(.92, .72),
    Offset(.31, .52),
    Offset(.71, .54),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < _points.length; i++) {
      final phase = (progress + i * .137) % 1;
      final fade = (.35 + .65 * (math.sin(phase * math.pi * 2).abs()));
      final point = _points[i];
      final center = Offset(point.dx * size.width, point.dy * size.height);
      final paint = Paint()
        ..color = const Color(0xFFFF536E).withValues(alpha: fade * .7);
      final radius = i % 3 == 0 ? 5.0 : 3.0;
      canvas.drawCircle(
        center,
        radius + math.sin(phase * math.pi * 2) * 1.2,
        paint,
      );
      if (i % 2 == 0) {
        final path = Path()
          ..moveTo(center.dx, center.dy - radius * 2)
          ..quadraticBezierTo(
            center.dx + 2,
            center.dy - 2,
            center.dx + radius * 2,
            center.dy,
          )
          ..quadraticBezierTo(
            center.dx + 2,
            center.dy + 2,
            center.dx,
            center.dy + radius * 2,
          )
          ..quadraticBezierTo(
            center.dx - 2,
            center.dy + 2,
            center.dx - radius * 2,
            center.dy,
          )
          ..quadraticBezierTo(
            center.dx - 2,
            center.dy - 2,
            center.dx,
            center.dy - radius * 2,
          );
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant MatchSparklePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
