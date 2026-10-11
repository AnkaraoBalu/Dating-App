import 'package:flutter/material.dart';
import '../../theme/theme.dart';

/// Static loading placeholder; avoids continuous motion in accessibility modes.
class AppSkeleton extends StatelessWidget {
  const AppSkeleton({
    super.key,
    this.width,
    this.height = AppSpacing.md,
    this.radius = AppRadius.sm,
  });
  final double? width;
  final double height;
  final double radius;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(radius),
      ),
    ),
  );
}
