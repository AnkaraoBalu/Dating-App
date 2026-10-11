import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';

class LoginHeading extends StatelessWidget {
  const LoginHeading({super.key, required this.title, required this.subtitle});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Semantics(
        header: true,
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: AppTypography.h2,
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      Text(
        subtitle,
        textAlign: TextAlign.center,
        style: AppTypography.body.copyWith(color: AppColors.textSecondary),
      ),
    ],
  );
}
