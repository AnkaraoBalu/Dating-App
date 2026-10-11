part of '../screens/onboarding_questions_screen.dart';

class _BasicsHeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..lineTo(0, size.height - 42)
    ..quadraticBezierTo(
      size.width * 0.26,
      size.height + 12,
      size.width * 0.58,
      size.height - 36,
    )
    ..quadraticBezierTo(
      size.width * 0.82,
      size.height - 70,
      size.width,
      size.height - 38,
    )
    ..lineTo(size.width, 0)
    ..close();

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _BasicsBottomPainter extends CustomPainter {
  const _BasicsBottomPainter(this.step);

  final int step;

  @override
  void paint(Canvas canvas, Size size) {
    final back = Path()
      ..moveTo(0, size.height * 0.68)
      ..quadraticBezierTo(
        size.width * 0.38,
        -12,
        size.width,
        size.height * 0.53,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      back,
      Paint()
        ..color = step == 1 ? const Color(0x664F8A73) : const Color(0x77FFC4A8),
    );
    final front = Path()
      ..moveTo(0, size.height * 0.74)
      ..quadraticBezierTo(
        size.width * 0.55,
        size.height * 1.1,
        size.width,
        size.height * 0.31,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      front,
      Paint()
        ..color = step == 1 ? const Color(0x775A947F) : const Color(0x66FFD4BB),
    );
  }

  @override
  bool shouldRepaint(covariant _BasicsBottomPainter oldDelegate) =>
      oldDelegate.step != step;
}
