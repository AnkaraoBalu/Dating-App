import 'package:flutter/material.dart';
import '../../theme/theme.dart';

class VibeBadge extends StatelessWidget {
  const VibeBadge({super.key, required this.percentage})
    : assert(percentage >= 0 && percentage <= 100);
  final int percentage;
  @override
  Widget build(BuildContext context) => Semantics(
    label: '$percentage percent vibe match',
    excludeSemantics: true,
    child: Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.forest,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.auto_awesome_outlined,
            size: AppSizes.metadataIcon,
            color: AppColors.peach,
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            '$percentage% vibe',
            style: AppTypography.label.copyWith(color: AppColors.textOnDark),
          ),
        ],
      ),
    ),
  );
}
