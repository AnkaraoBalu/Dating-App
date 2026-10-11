import 'package:flutter/material.dart';

import '../../theme/theme.dart';

enum AppButtonVariant { primary, love, secondary, text }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final callback = isLoading ? null : onPressed;
    final foreground = callback == null
        ? scheme.onSurface.withValues(alpha: 0.5)
        : variant == AppButtonVariant.love
        ? AppColors.forestDeep
        : variant == AppButtonVariant.primary
        ? scheme.onPrimary
        : scheme.primary;
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: AppSizes.inputIcon,
            height: AppSizes.inputIcon,
            child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
          ),
          const SizedBox(width: AppSpacing.xs),
        ] else if (icon != null) ...[
          Icon(icon, size: AppSizes.inputIcon),
          const SizedBox(width: AppSpacing.xs),
        ],
        Flexible(child: Text(label, textAlign: TextAlign.center)),
      ],
    );
    Widget button = switch (variant) {
      AppButtonVariant.primary => FilledButton(
        onPressed: callback,
        child: content,
      ),
      AppButtonVariant.secondary => OutlinedButton(
        onPressed: callback,
        child: content,
      ),
      AppButtonVariant.text => TextButton(onPressed: callback, child: content),
      AppButtonVariant.love => DecoratedBox(
        decoration: BoxDecoration(
          gradient: callback == null ? null : AppGradients.match,
          color: callback == null ? scheme.surfaceContainerHighest : null,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: callback == null ? null : AppShadows.love,
        ),
        child: FilledButton(
          onPressed: callback,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            foregroundColor: foreground,
          ),
          child: content,
        ),
      ),
    };
    if (fullWidth) button = SizedBox(width: double.infinity, child: button);
    return Semantics(
      button: true,
      enabled: callback != null,
      value: isLoading ? 'Loading' : null,
      child: button,
    );
  }
}
