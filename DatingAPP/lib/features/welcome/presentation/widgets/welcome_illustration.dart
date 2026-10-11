import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/theme.dart';

/// Full-bleed artwork, with contrast kept separate from the original photo.
class WelcomeIllustration extends StatelessWidget {
  const WelcomeIllustration({super.key});

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          AppAssets.welcomeBackground,
          fit: BoxFit.cover,
          alignment: const Alignment(0, -0.35),
          errorBuilder: (context, error, stackTrace) => const DecoratedBox(
            decoration: BoxDecoration(gradient: AppGradients.forest),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0, 0.25, 0.48, 0.72, 1],
              colors: [
                Color(0x18081714),
                Color(0x33081714),
                Color(0x99081714),
                Color(0x55081714),
                Color(0xF2081714),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
