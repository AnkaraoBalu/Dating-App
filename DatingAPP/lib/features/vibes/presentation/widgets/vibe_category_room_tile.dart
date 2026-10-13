part of '../screens/vibe_category_rooms_screen.dart';

class _CategoryRoomTile extends StatelessWidget {
  const _CategoryRoomTile({
    required this.room,
    required this.onTap,
    required this.onSave,
    required this.isSaving,
  });

  final VibeRoom room;
  final VoidCallback onTap;
  final VoidCallback onSave;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    final saved =
        room.isSaved || VibeRoomStore.instance.savedIds.contains(room.id);
    final joined =
        room.isJoined || VibeRoomStore.instance.joinedIds.contains(room.id);
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(17),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(17),
                child: Padding(
                  padding: const EdgeInsets.all(9),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 88,
                          height: 92,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              VibeCoverImage(image: room.coverImage),
                              Align(
                                alignment: Alignment.topLeft,
                                child: Container(
                                  margin: const EdgeInsets.all(5),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: room.isLive
                                        ? AppColors.coral
                                        : AppColors.surface.withValues(
                                            alpha: .95,
                                          ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    room.isLive ? 'LIVE' : 'UPCOMING',
                                    style: AppTypography.caption.copyWith(
                                      color: room.isLive
                                          ? Colors.white
                                          : AppColors.textPrimary,
                                      fontSize: 8,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                              if (joined)
                                Align(
                                  alignment: Alignment.topRight,
                                  child: Container(
                                    margin: const EdgeInsets.all(5),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface.withValues(
                                        alpha: .95,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'JOINED',
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.forest,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              room.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.label.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              room.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Row(
                              children: [
                                const Icon(
                                  Icons.people_alt_outlined,
                                  size: 14,
                                  color: AppColors.coral,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '${room.participantCount} in room',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 13,
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
                            const SizedBox(height: 6),
                            Text(
                              room.tags.take(3).join(' · '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textTertiary,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: saved ? 'Remove saved room' : 'Save room',
              onPressed: isSaving ? null : onSave,
              icon: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      saved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      color: saved ? AppColors.coral : AppColors.textSecondary,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
