import 'package:flutter/material.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/distance_slider.dart';

class OnboardingLocationQuestion extends StatelessWidget {
  const OnboardingLocationQuestion({
    super.key,
    required this.distanceKm,
    required this.onlyNearby,
    required this.enabled,
    required this.onDistanceChanged,
    required this.onNearbyChanged,
    this.dark = false,
  });

  final int distanceKm;
  final bool onlyNearby;
  final bool enabled;
  final bool dark;
  final ValueChanged<int> onDistanceChanged;
  final ValueChanged<bool> onNearbyChanged;

  @override
  Widget build(BuildContext context) => ListView(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: SizedBox(
          height: 180,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(AppAssets.locationBackground, fit: BoxFit.cover),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.forestDark.withValues(alpha: 0.22),
                ),
              ),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on_rounded, color: AppColors.coral),
                      SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          'Approximate area only',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              'Show people within',
              style: AppTypography.label.copyWith(
                color: dark ? Colors.white : null,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '$distanceKm km',
            style: AppTypography.label.copyWith(
              color: dark ? AppColors.peach : AppColors.coralPressed,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpacing.sm),
      DistanceSlider(
        value: distanceKm.toDouble(),
        enabled: enabled,
        dark: dark,
        onChanged: (value) => onDistanceChanged(value.round()),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '1 km',
              style: AppTypography.caption.copyWith(
                color: dark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
            Text(
              '100 km',
              style: AppTypography.caption.copyWith(
                color: dark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        value: onlyNearby,
        activeTrackColor: AppColors.forest,
        onChanged: enabled ? onNearbyChanged : null,
        title: Text(
          'Only show people nearby',
          style: TextStyle(color: dark ? Colors.white : null),
        ),
        subtitle: Text(
          'You can change this any time.',
          style: TextStyle(color: dark ? Colors.white70 : null),
        ),
      ),
      Text(
        'Your precise location is never shown on your profile.',
        style: AppTypography.caption.copyWith(
          color: dark ? Colors.white70 : AppColors.textSecondary,
        ),
      ),
    ],
  );
}
