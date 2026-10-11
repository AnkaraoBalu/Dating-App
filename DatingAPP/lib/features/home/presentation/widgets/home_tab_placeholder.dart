import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';

class HomeTabPlaceholder extends StatelessWidget {
  const HomeTabPlaceholder({super.key, required this.tab, required this.icon});

  final String tab;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 94,
            height: 94,
            decoration: BoxDecoration(
              color: AppColors.coral.withValues(alpha: .12),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.coral.withValues(alpha: .38)),
            ),
            child: Icon(icon, color: AppColors.coral, size: 42),
          ),
          const SizedBox(height: 20),
          Text(
            tab,
            style: AppTypography.h1.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'This space is ready for you. We’re bringing it to life next.',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    ),
  );
}
