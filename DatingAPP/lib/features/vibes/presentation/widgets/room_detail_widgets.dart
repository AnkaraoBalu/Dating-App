import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../models/vibe_room.dart';
import 'vibe_room_widgets.dart';

class VibeRoomMetaChip extends StatelessWidget {
  const VibeRoomMetaChip({
    super.key,
    required this.icon,
    required this.label,
    this.color = AppColors.textSecondary,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: AppColors.surfaceSecondary,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: AppTypography.caption.copyWith(color: AppColors.textPrimary),
        ),
      ],
    ),
  );
}

class VibeRoomHostCard extends StatelessWidget {
  const VibeRoomHostCard({super.key, required this.room});

  final VibeRoom room;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(13),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        VibeRoomAvatar(image: room.hostAvatar, size: 48),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                room.hostName,
                style: AppTypography.label.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'Room host · ${room.city}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.verified_rounded, size: 20, color: AppColors.verified),
      ],
    ),
  );
}

class VibeRoomAvatarStack extends StatelessWidget {
  const VibeRoomAvatarStack({super.key, required this.members});

  final List<VibeRoomMember> members;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: members.length > 3 ? 90 : members.length * 22.0 + 18,
    height: 34,
    child: Stack(
      children: [
        for (var index = 0; index < members.take(4).length; index++)
          Positioned(
            left: index * 20.0,
            child: VibeRoomAvatar(
              image: members[index].avatar,
              size: 34,
              borderColor: AppColors.surface,
            ),
          ),
      ],
    ),
  );
}
