import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';

class WelcomePageIndicator extends StatelessWidget {
  const WelcomePageIndicator({
    super.key,
    required this.index,
    required this.count,
    required this.onSelected,
  });
  final int index;
  final int count;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (var i = 0; i < count; i++)
        Semantics(
          label: 'Page ${i + 1} of $count',
          selected: i == index,
          button: true,
          child: InkResponse(
            onTap: () => onSelected(i),
            radius: AppSpacing.lg,
            child: SizedBox.square(
              dimension: AppSizes.touchTarget,
              child: Center(
                child: AnimatedContainer(
                  duration: AppMotion.duration(context, AppMotion.normal),
                  curve: AppMotion.curve,
                  width: i == index ? 14 : 6,
                  height: i == index ? 14 : 6,
                  decoration: BoxDecoration(
                    color: i == index
                        ? AppColors.forestDeep
                        : AppColors.textSecondary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ),
    ],
  );
}
