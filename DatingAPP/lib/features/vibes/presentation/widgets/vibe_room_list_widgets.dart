import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import '../../models/vibe_room.dart';
import 'vibe_room_widgets.dart';

class VibeRoomSectionTitle extends StatelessWidget {
  const VibeRoomSectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 3),
              Text(
                subtitle!,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
      if (actionLabel != null)
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(foregroundColor: AppColors.coralPressed),
          child: Text(actionLabel!),
        ),
    ],
  );
}

class VibeRoomEmptyState extends StatelessWidget {
  const VibeRoomEmptyState({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 50),
    child: Column(
      children: [
        const Icon(Icons.forum_outlined, size: 48, color: AppColors.coral),
        const SizedBox(height: 14),
        Text(
          title,
          style: AppTypography.title.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 5),
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    ),
  );
}

class VibeRoomMemberTile extends StatelessWidget {
  const VibeRoomMemberTile({
    super.key,
    required this.member,
    required this.onTap,
    this.trailing,
  });

  final VibeRoomMember member;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
    leading: VibeRoomAvatar(
      image: member.avatar,
      size: 48,
      online: member.online,
    ),
    title: Text(
      '${member.name}, ${member.age}',
      style: AppTypography.label.copyWith(color: AppColors.textPrimary),
    ),
    subtitle: Text(
      '${member.role} · ${member.tags.take(2).join(' · ')}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
    ),
    trailing: trailing,
  );
}
