import 'package:flutter/material.dart';
import '../../theme/theme.dart';
import 'app_card.dart';

class VibeCard extends StatelessWidget {
  const VibeCard({
    super.key,
    required this.image,
    required this.author,
    required this.caption,
    this.footer,
    this.onTap,
  });
  final Widget image;
  final String author;
  final String caption;
  final Widget? footer;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => AppCard(
    padding: EdgeInsets.zero,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(author, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: AspectRatio(aspectRatio: 1.2, child: image),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(caption, style: Theme.of(context).textTheme.bodyMedium),
            if (footer != null) ...[
              const SizedBox(height: AppSpacing.sm),
              footer!,
            ],
          ],
        ),
      ),
    ),
  );
}
