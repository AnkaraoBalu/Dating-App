import 'package:flutter/material.dart';
import '../../theme/theme.dart';

class InterestChip extends StatelessWidget {
  const InterestChip({
    super.key,
    required this.label,
    this.icon,
    this.romantic = false,
  });
  final String label;
  final IconData? icon;
  final bool romantic;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = romantic ? AppColors.forestDark : scheme.onSurface;
    return Chip(
      label: Text(label),
      labelStyle: Theme.of(
        context,
      ).textTheme.labelMedium?.copyWith(color: foreground),
      avatar: icon == null
          ? null
          : Icon(icon, size: AppSizes.chipIcon, color: foreground),
      backgroundColor: romantic ? AppColors.coralSoft : null,
      side: romantic ? const BorderSide(color: AppColors.coralSoft) : null,
    );
  }
}
