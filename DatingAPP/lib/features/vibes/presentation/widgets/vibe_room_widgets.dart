import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../models/vibe_room.dart';

class VibeRoomAvatar extends StatelessWidget {
  const VibeRoomAvatar({
    super.key,
    required this.image,
    this.size = 38,
    this.borderColor,
    this.online = false,
  });

  final String image;
  final double size;
  final Color? borderColor;
  final bool online;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    padding: EdgeInsets.all(borderColor == null ? 0 : 2),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: borderColor ?? AppColors.surface,
      border: borderColor == null ? null : Border.all(color: borderColor!),
    ),
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        ClipOval(
          child: Image(
            image: image.startsWith('http')
                ? NetworkImage(image)
                : AssetImage(image),
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              color: AppColors.peachSoft,
              alignment: Alignment.center,
              child: const Icon(Icons.person_rounded, color: AppColors.coral),
            ),
          ),
        ),
        if (online)
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surface, width: 1.5),
              ),
            ),
          ),
      ],
    ),
  );
}

class VibeRoomCover extends StatelessWidget {
  const VibeRoomCover({
    super.key,
    required this.asset,
    this.height = 156,
    this.borderRadius = 18,
    this.child,
  });

  final String asset;
  final double height;
  final double borderRadius;
  final Widget? child;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(borderRadius),
    child: SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            asset,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const ColoredBox(
              color: AppColors.forest,
              child: Icon(Icons.auto_awesome_rounded, color: Colors.white),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black12, Colors.transparent, Colors.black87],
                stops: [0, .35, 1],
              ),
            ),
          ),
          ?child,
        ],
      ),
    ),
  );
}

class VibeRoomCard extends StatelessWidget {
  const VibeRoomCard({
    super.key,
    required this.room,
    required this.onTap,
    this.onSave,
    this.saved = false,
    this.width,
  });

  final VibeRoom room;
  final VoidCallback onTap;
  final VoidCallback? onSave;
  final bool saved;
  final double? width;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VibeRoomCover(
              asset: room.coverAsset,
              height: width == null ? 174 : 142,
              borderRadius: 0,
              child: Stack(
                children: [
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _RoomTag(
                      label: room.isLive
                          ? '● LIVE'
                          : room.scheduledFor ?? 'SOON',
                      background: room.isLive
                          ? AppColors.coral
                          : AppColors.surface,
                      foreground: room.isLive
                          ? Colors.white
                          : AppColors.textPrimary,
                    ),
                  ),
                  if (onSave != null)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: IconButton.filledTonal(
                        visualDensity: VisualDensity.compact,
                        onPressed: onSave,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: .9),
                          foregroundColor: saved
                              ? AppColors.coral
                              : AppColors.textPrimary,
                        ),
                        icon: Icon(
                          saved
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          size: 19,
                        ),
                      ),
                    ),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 11,
                    child: Row(
                      children: [
                        Text(room.emoji, style: const TextStyle(fontSize: 21)),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            room.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.title.copyWith(
                              color: Colors.white,
                              fontSize: 14,
                              shadows: const [
                                Shadow(color: Colors.black54, blurRadius: 7),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: [
                      Icon(
                        Icons.people_alt_outlined,
                        size: 15,
                        color: AppColors.coralPressed,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${room.participantCount} ${room.isLive ? 'in room' : 'going'}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          room.city,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _RoomTag extends StatelessWidget {
  const _RoomTag({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: AppTypography.caption.copyWith(
        color: foreground,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}
