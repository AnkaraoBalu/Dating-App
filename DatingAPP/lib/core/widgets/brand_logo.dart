import 'package:flutter/material.dart';

import '../constants/app_assets.dart';
import '../constants/app_constants.dart';

/// The approved Just2 wordmark; use the ivory version on dark surfaces.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.height = 48, this.onDark = false});

  final double height;
  final bool onDark;

  @override
  Widget build(BuildContext context) => Image.asset(
    onDark ? AppAssets.logoWordmarkLight : AppAssets.logoWordmark,
    width: height * 2,
    height: height,
    fit: BoxFit.contain,
    alignment: Alignment.centerLeft,
    semanticLabel: AppConstants.name,
    filterQuality: FilterQuality.high,
  );
}
