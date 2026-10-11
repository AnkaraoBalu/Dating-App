import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';

class OnboardingChoiceTile extends StatelessWidget {
  const OnboardingChoiceTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.description,
    this.icon,
    this.leading,
    this.dark = false,
    this.enabled = true,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? description;
  final IconData? icon;
  final Widget? leading;
  final bool dark;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Material(
    color: dark
        ? selected
              ? AppColors.darkSurface2
              : AppColors.darkSurface.withValues(alpha: 0.76)
        : selected
        ? AppColors.selection
        : AppColors.surface,
    borderRadius: BorderRadius.circular(AppRadius.lg),
    child: InkWell(
      onTap: enabled ? onTap : null,
      splashFactory: NoSplash.splashFactory,
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        constraints: const BoxConstraints(minHeight: 58),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: selected
                ? (dark ? AppColors.peach : AppColors.forest)
                : (dark ? Colors.white38 : AppColors.border),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            if (leading != null || icon != null) ...[
              leading ??
                  Icon(
                    icon,
                    color: dark ? AppColors.peach : AppColors.forest,
                    size: 21,
                  ),
              const SizedBox(width: AppSpacing.sm),
            ],
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.label.copyWith(
                      color: dark
                          ? AppColors.textOnDark
                          : AppColors.textPrimary,
                    ),
                  ),
                  if (description != null)
                    Text(
                      description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: dark ? Colors.white70 : AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: selected
                  ? AppColors.success
                  : (dark ? Colors.white54 : AppColors.borderStrong),
              size: 21,
            ),
          ],
        ),
      ),
    ),
  );
}

class OnboardingOptionChip extends StatelessWidget {
  const OnboardingOptionChip({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.onTap,
    this.dark = false,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final bool dark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: selected
        ? (dark ? AppColors.darkSurface2 : AppColors.background)
        : dark
        ? AppColors.darkSurface.withValues(alpha: 0.76)
        : AppColors.surface,
    borderRadius: BorderRadius.circular(AppRadius.lg),
    child: InkWell(
      onTap: enabled ? onTap : null,
      splashFactory: NoSplash.splashFactory,
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: selected
                ? (dark ? AppColors.peach : AppColors.forest)
                : (dark ? Colors.white38 : AppColors.border),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: dark ? AppColors.peach : AppColors.forest,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  color: dark
                      ? (enabled ? AppColors.textOnDark : Colors.white54)
                      : enabled
                      ? AppColors.textPrimary
                      : AppColors.textTertiary,
                ),
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_rounded,
                color: AppColors.forest,
                size: 17,
              ),
          ],
        ),
      ),
    ),
  );
}

class OnboardingSelectionCount extends StatelessWidget {
  const OnboardingSelectionCount({
    super.key,
    required this.count,
    this.dark = false,
  });

  final int count;
  final bool dark;

  @override
  Widget build(BuildContext context) => Row(
    children: List.generate(5, (index) {
      final selected = index < count;
      return Expanded(
        child: Container(
          height: 5,
          margin: const EdgeInsets.only(right: AppSpacing.xxs),
          decoration: BoxDecoration(
            color: selected
                ? (dark ? AppColors.coral : AppColors.forest)
                : (dark ? Colors.white30 : AppColors.border),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
      );
    }),
  );
}
