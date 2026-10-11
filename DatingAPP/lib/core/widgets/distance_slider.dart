import 'package:flutter/material.dart';

import '../theme/theme.dart';

class DistanceSlider extends StatelessWidget {
  const DistanceSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.dark = false,
  });

  static const minKm = 1.0;
  static const maxKm = 100.0;

  final double value;
  final ValueChanged<double> onChanged;
  final bool enabled;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final clampedValue = value.clamp(minKm, maxKm).toDouble();
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: AppColors.coral,
        inactiveTrackColor: dark ? Colors.white38 : AppColors.borderStrong,
        thumbColor: AppColors.coral,
        overlayColor: AppColors.coral.withValues(alpha: .18),
        valueIndicatorColor: AppColors.coralPressed,
        valueIndicatorTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
      ),
      child: Slider(
        value: clampedValue,
        min: minKm,
        max: maxKm,
        divisions: 99,
        label: '${clampedValue.round()} km',
        onChanged: enabled ? onChanged : null,
      ),
    );
  }
}
