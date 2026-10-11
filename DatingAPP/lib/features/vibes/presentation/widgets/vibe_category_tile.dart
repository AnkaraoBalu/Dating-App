import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../models/vibe_category.dart';

class VibeCategoryTile extends StatelessWidget {
  const VibeCategoryTile({
    super.key,
    required this.category,
    required this.onTap,
    this.selected = false,
    this.compact = false,
  });

  final VibeCategory category;
  final VoidCallback onTap;
  final bool selected;
  final bool compact;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Ink(
        decoration: BoxDecoration(
          color: category.color,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: selected ? AppColors.coral : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.all(compact ? 9 : 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    category.emoji,
                    style: TextStyle(fontSize: compact ? 25 : 30),
                  ),
                  SizedBox(height: compact ? 4 : 7),
                  Text(
                    category.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.label.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: compact ? 11 : 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (!compact) ...[
                    const SizedBox(height: 3),
                    Text(
                      category.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (selected)
              const Positioned(
                top: 8,
                right: 8,
                child: Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.coralPressed,
                  size: 19,
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
