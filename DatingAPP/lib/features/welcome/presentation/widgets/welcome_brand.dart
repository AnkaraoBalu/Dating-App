import 'package:flutter/material.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/theme.dart';

class WelcomeBrand extends StatelessWidget {
  const WelcomeBrand({super.key});

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Image.asset(
        AppAssets.logoStackedLight,
        width: 164,
        height: 164,
        fit: BoxFit.contain,
        semanticLabel: AppConstants.name,
        filterQuality: FilterQuality.high,
      ),
      const SizedBox(height: AppSpacing.md),
      Text(
        AppConstants.welcomeTitle,
        textAlign: TextAlign.center,
        style: AppTypography.welcomeBody.copyWith(
          color: AppColors.textOnDark,
          height: 1.45,
        ),
      ),
    ],
  );
}
