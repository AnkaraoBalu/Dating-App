import 'package:flutter/material.dart';
import '../../theme/theme.dart';

class AppProgressBar extends StatelessWidget {
  const AppProgressBar({super.key, required this.value, this.semanticLabel})
    : assert(value >= 0 && value <= 1);
  final double value;
  final String? semanticLabel;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: value),
    duration: AppMotion.duration(context, AppMotion.navigation),
    curve: AppMotion.curve,
    builder: (context, progress, _) => LinearProgressIndicator(
      value: progress,
      minHeight: AppSpacing.xxs,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      semanticsLabel: semanticLabel,
      semanticsValue: '${(value * 100).round()}%',
    ),
  );
}
