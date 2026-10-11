import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';

class WelcomeActions extends StatelessWidget {
  const WelcomeActions({
    super.key,
    required this.onGetStarted,
    required this.onSignIn,
  });
  final VoidCallback onGetStarted;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: onGetStarted,
          style: FilledButton.styleFrom(
            textStyle: AppTypography.welcomeButton,
            backgroundColor: AppColors.peach,
            foregroundColor: AppColors.forestDeep,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
          child: const Text('Get started'),
        ),
      ),
      const SizedBox(height: AppSpacing.xxs),
      TextButton(
        onPressed: onSignIn,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.peachSoft,
          textStyle: AppTypography.welcomeSignIn,
        ),
        child: const Text('I already have an account'),
      ),
    ],
  );
}
