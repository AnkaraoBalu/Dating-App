import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import 'google_mark.dart';

enum LoginProvider { google, phone, email }

class SocialLoginButton extends StatelessWidget {
  const SocialLoginButton({
    super.key,
    required this.provider,
    required this.onPressed,
  });
  final LoginProvider provider;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: provider == LoginProvider.google
                ? const GoogleMark()
                : Icon(
                    provider == LoginProvider.phone
                        ? Icons.phone_iphone_rounded
                        : Icons.email_outlined,
                    size: 26,
                  ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Continue with ${switch (provider) {
                LoginProvider.google => 'Google',
                LoginProvider.phone => 'Phone',
                LoginProvider.email => 'Email',
              }}',
              style: AppTypography.button,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    ),
  );
}
