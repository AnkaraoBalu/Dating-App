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
      ExcludeSemantics(
        child: SizedBox.square(
          dimension: 88,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(AppAssets.logo, fit: BoxFit.cover),
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      Semantics(
        header: true,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                AppConstants.name,
                style: AppTypography.welcomeBrand.copyWith(
                  color: AppColors.textOnDark,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: AppSpacing.xxs),
            const ExcludeSemantics(
              child: Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.peach,
                size: AppSizes.inputIcon,
              ),
            ),
          ],
        ),
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
