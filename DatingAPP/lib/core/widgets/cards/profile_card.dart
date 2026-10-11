import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import '../common/verified_badge.dart';

/// Pass a fitted image widget; image loading and profile data belong to features.
class ProfileCard extends StatelessWidget {
  const ProfileCard({
    super.key,
    required this.image,
    required this.name,
    required this.details,
    this.bio,
    this.verified = false,
    this.onTap,
    this.interests = const [],
    this.aspectRatio = 0.7,
  });
  final Widget image;
  final String name;
  final String details;
  final String? bio;
  final bool verified;
  final VoidCallback? onTap;
  final List<Widget> interests;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    // Image area keeps its proportions, but content can grow with accessibility text.
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Material(
        color: AppColors.darkSurface,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: aspectRatio,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    image,
                    const IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppGradients.photoOverlay,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: text.headlineMedium?.copyWith(
                              color: AppColors.textOnDark,
                            ),
                          ),
                        ),
                        if (verified) const VerifiedBadge(),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      details,
                      style: text.bodySmall?.copyWith(
                        color: AppColors.peachSoft,
                      ),
                    ),
                    if (bio != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        bio!,
                        style: text.bodyMedium?.copyWith(
                          color: AppColors.textOnDark,
                        ),
                      ),
                    ],
                    if (interests.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xxs,
                        children: interests,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
