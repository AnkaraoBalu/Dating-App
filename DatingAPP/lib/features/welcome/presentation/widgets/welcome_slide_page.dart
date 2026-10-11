import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import '../../models/welcome_slide.dart';
import 'welcome_slide_artwork.dart';

class WelcomeSlidePage extends StatelessWidget {
  const WelcomeSlidePage({super.key, required this.slide});
  final WelcomeSlide slide;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, viewport) => SingleChildScrollView(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppSizes.contentMaxWidth),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: LayoutBuilder(
              builder: (context, content) => ConstrainedBox(
                constraints: BoxConstraints(minHeight: viewport.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: (content.maxWidth * 1.08).clamp(180, 420),
                      width: content.maxWidth,
                      child: WelcomeSlideArtwork(slide: slide),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Semantics(
                      header: true,
                      child: Text(
                        slide.title,
                        textAlign: TextAlign.center,
                        style: AppTypography.h1.copyWith(
                          fontStyle: FontStyle.italic,
                          height: 1.18,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      slide.description,
                      textAlign: TextAlign.center,
                      style: AppTypography.body.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
