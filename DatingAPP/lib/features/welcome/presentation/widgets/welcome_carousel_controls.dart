import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import 'welcome_page_indicator.dart';

class WelcomeCarouselControls extends StatelessWidget {
  const WelcomeCarouselControls({
    super.key,
    required this.index,
    required this.count,
    required this.onSelected,
    required this.onNext,
  });

  final int index;
  final int count;
  final ValueChanged<int> onSelected;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final isLast = index == count - 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              WelcomePageIndicator(
                index: index,
                count: count,
                onSelected: onSelected,
              ),
              IconButton.filled(
                tooltip: isLast ? "Let's begin" : 'Next page',
                onPressed: onNext,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.forest,
                  foregroundColor: AppColors.textOnDark,
                  minimumSize: const Size.square(AppSizes.circleAction),
                ),
                icon: AnimatedSwitcher(
                  duration: AppMotion.duration(context, AppMotion.normal),
                  child: Icon(
                    isLast ? Icons.check_rounded : Icons.arrow_forward_rounded,
                    key: ValueKey(isLast),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
