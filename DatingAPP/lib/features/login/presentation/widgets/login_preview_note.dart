import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';

class LoginPreviewNote extends StatelessWidget {
  const LoginPreviewNote({super.key, this.code});
  final String? code;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.sm),
    decoration: BoxDecoration(
      color: AppColors.peachSoft.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(AppRadius.sm),
    ),
    child: Text(
      code == null
          ? 'UI preview • No account is created.'
          : 'No SMS sent. Use preview code $code.',
      textAlign: TextAlign.center,
      style: AppTypography.bodySmall.copyWith(color: AppColors.forest),
    ),
  );
}
