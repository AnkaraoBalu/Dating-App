import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import '../../models/welcome_slide.dart';

class WelcomeSlideArtwork extends StatelessWidget {
  const WelcomeSlideArtwork({super.key, required this.slide});
  final WelcomeSlide slide;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: LayoutBuilder(
      builder: (context, constraints) => Stack(
        fit: StackFit.expand,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Image.asset(slide.image, fit: BoxFit.contain),
          ),
          for (var i = 0; i < slide.notes.length; i++)
            Align(
              alignment: const [
                Alignment(-1, -0.25),
                Alignment(0.85, -0.92),
                Alignment(-0.4, 0.96),
                Alignment(1, 0.65),
              ][i],
              child: Transform.rotate(
                angle: (i.isEven ? -1 : 1) * math.pi / 24,
                child: Text(
                  slide.notes[i],
                  style: AppTypography.welcomeHandwriting.copyWith(
                    fontSize: (constraints.maxWidth * 0.075).clamp(20, 28),
                    color: AppColors.textSecondary,
                  ),
                  textScaler: TextScaler.noScaling,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
