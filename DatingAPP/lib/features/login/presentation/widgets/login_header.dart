import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/theme.dart';

enum LoginHeaderKind { social, phone, verification }

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key, required this.kind, required this.height});
  final LoginHeaderKind kind;
  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    width: double.infinity,
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(AppAssets.loginAmbient, fit: BoxFit.cover),
        const ColoredBox(color: Color(0x22081714)),
        if (kind != LoginHeaderKind.social)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: AppMotion.duration(context, AppMotion.hero),
            curve: AppMotion.curve,
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, (1 - value) * 18),
                child: child,
              ),
            ),
            child: Center(
              child: Transform.rotate(
                angle: kind == LoginHeaderKind.phone
                    ? -math.pi / 10
                    : math.pi / 12,
                child: Container(
                  width: 100,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.peachSoft.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    border: Border.all(
                      color: AppColors.textOnDark.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Center(
                    child: kind == LoginHeaderKind.phone
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            child: Image.asset(
                              AppAssets.loginPortrait,
                              width: 58,
                              height: 72,
                              fit: BoxFit.cover,
                            ),
                          )
                        : const Icon(
                            Icons.lock_outline_rounded,
                            size: 48,
                            color: AppColors.forest,
                          ),
                  ),
                ),
              ),
            ),
          ),
        Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            height: 54,
            width: double.infinity,
            child: CustomPaint(painter: _LoginWavePainter()),
          ),
        ),
      ],
    ),
  );
}

class _LoginWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, size.height * 0.58)
      ..cubicTo(
        size.width * 0.2,
        size.height * 1.15,
        size.width * 0.65,
        -size.height * 0.48,
        size.width,
        size.height * 0.48,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = AppColors.background);
  }

  @override
  bool shouldRepaint(covariant _LoginWavePainter oldDelegate) => false;
}
