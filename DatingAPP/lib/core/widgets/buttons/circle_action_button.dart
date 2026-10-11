import 'package:flutter/material.dart';
import '../../theme/theme.dart';

enum CircleAction { reject, like, vibe, next }

class CircleActionButton extends StatelessWidget {
  const CircleActionButton({
    super.key,
    required this.action,
    required this.onPressed,
    required this.tooltip,
  });
  final CircleAction action;
  final VoidCallback? onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final like = action == CircleAction.like;
    final brand = action == CircleAction.vibe || action == CircleAction.next;
    return IconButton.filled(
      onPressed: onPressed,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        minimumSize: Size.square(
          like ? AppSizes.likeAction : AppSizes.circleAction,
        ),
        backgroundColor: like
            ? AppColors.coral
            : brand
            ? AppColors.forest
            : scheme.surface,
        foregroundColor: like
            ? AppColors.forestDeep
            : brand
            ? AppColors.peach
            : scheme.onSurface,
        side: BorderSide(color: scheme.outlineVariant),
      ),
      icon: Icon(switch (action) {
        CircleAction.reject => Icons.close_rounded,
        CircleAction.like => Icons.favorite_rounded,
        CircleAction.vibe => Icons.star_outline_rounded,
        CircleAction.next => Icons.arrow_forward_rounded,
      }),
    );
  }
}
