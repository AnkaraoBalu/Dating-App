part of '../screens/vibe_rooms_home_screen.dart';

// Featured room, member stack, room actions and their small widgets.
extension _VibeRoomsHomeSections on _VibeRoomsHomeScreenState {
  Widget _featuredRoom() {
    final room =
        _store.rooms.where((room) => room.isLive).firstOrNull ??
        _store.rooms.firstOrNull;
    if (room == null) {
      return Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          constraints: const BoxConstraints(minHeight: 168),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.coralSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.forum_rounded, color: AppColors.coral),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No vibe rooms yet',
                      style: AppTypography.h3.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Start a room and invite people to join the conversation.',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _createRoom,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.coral,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Create a room'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    final isJoined = room.isJoined || _store.joinedIds.contains(room.id);

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openRoom(room),
        child: SizedBox(
          height: 194,
          child: VibeRoomCover(
            asset: room.coverImage,
            height: 194,
            borderRadius: 0,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _Badge(label: room.isLive ? '✦ LIVE' : 'OPEN'),
                      const SizedBox(width: 7),
                      _Badge(label: '♟ ${room.participantCount} in room'),
                      const Spacer(),
                      IconButton.filledTonal(
                        onPressed: () => _toggleSaved(room),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: .91),
                          foregroundColor: _store.savedIds.contains(room.id)
                              ? AppColors.coral
                              : AppColors.textPrimary,
                          visualDensity: VisualDensity.compact,
                        ),
                        icon: Icon(
                          _store.savedIds.contains(room.id)
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              room.title,
                              style: AppTypography.h3.copyWith(
                                color: Colors.white,
                                fontSize: 20,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              room.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption.copyWith(
                                color: Colors.white.withValues(alpha: .92),
                              ),
                            ),
                            const SizedBox(height: 8),
                            _memberStack(room),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        onPressed: () => _openRoom(room),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.coral,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                        ),
                        child: Text(isJoined ? 'Joined ✓' : 'Join room'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _memberStack(VibeRoom room) {
    final total = room.participantCount < 0 ? 0 : room.participantCount;
    final members = room.members.take(total < 3 ? total : 3).toList();
    final remaining = total - members.length;
    return SizedBox(
      height: 31,
      child: Row(
        children: [
          for (final member in members)
            Align(
              widthFactor: .78,
              child: VibeRoomAvatar(
                image: member.avatar,
                size: 31,
                borderColor: Colors.white,
              ),
            ),
          if (remaining > 0) ...[
            const SizedBox(width: 6),
            Text(
              '+$remaining',
              semanticsLabel: '$remaining more members',
              style: AppTypography.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _roomActions() => Row(
    children: [
      Expanded(
        child: _ActionCard(
          icon: Icons.add_rounded,
          title: 'Create a room',
          subtitle: 'Host your own vibe',
          onTap: _createRoom,
        ),
      ),
      const SizedBox(width: 9),
      Expanded(
        child: _ActionCard(
          icon: Icons.forum_outlined,
          title: 'My rooms',
          subtitle: 'Joined and hosting',
          onTap: _openMyRooms,
        ),
      ),
      const SizedBox(width: 9),
      Expanded(
        child: _ActionCard(
          icon: Icons.bookmark_border_rounded,
          title: 'Saved',
          subtitle: 'Your room list',
          onTap: _openSaved,
        ),
      ),
    ],
  );
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .92),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: AppTypography.caption.copyWith(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(17),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.coralPressed, size: 19),
            const SizedBox(height: 6),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                color: AppColors.textTertiary,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
