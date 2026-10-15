import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';

/// Rounded photo card with a soft bottom fade and a small badge icon, used in
/// place of plain icons on the setup intro and completion screens.
class SetupImageHero extends StatelessWidget {
  const SetupImageHero({
    super.key,
    required this.image,
    required this.icon,
    this.height = 260,
    this.fade = true,
  });

  final String image;
  final IconData icon;
  final double height;

  /// Darkens the bottom edge; off for light artwork such as polaroids.
  final bool fade;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height + 28,
    child: Stack(
      alignment: Alignment.topCenter,
      children: [
        Container(
          height: height,
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1F271C12),
                blurRadius: 22,
                offset: Offset(0, 9),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ExcludeSemantics(
                child: Image.asset(
                  image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      const ColoredBox(color: AppColors.coralSoft),
                ),
              ),
              if (fade)
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.55, 1],
                      colors: [Colors.transparent, Color(0x66000000)],
                    ),
                  ),
                ),
            ],
          ),
        ),
        Positioned(
          bottom: 0,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.coral,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.background, width: 4),
            ),
            child: Icon(icon, color: Colors.white, size: 26),
          ),
        ),
      ],
    ),
  );
}
