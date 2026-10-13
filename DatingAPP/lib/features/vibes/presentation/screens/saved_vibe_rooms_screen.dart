import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../data/vibe_rooms_api.dart';
import '../../data/vibe_room_store.dart';
import '../../models/vibe_room.dart';
import 'room_detail_screen.dart';
import '../widgets/vibe_room_list_widgets.dart';
import '../widgets/vibe_room_widgets.dart';

class SavedVibeRoomsScreen extends StatefulWidget {
  const SavedVibeRoomsScreen({super.key, this.api});

  final VibeRoomsApi? api;

  @override
  State<SavedVibeRoomsScreen> createState() => _SavedVibeRoomsScreenState();
}

class _SavedVibeRoomsScreenState extends State<SavedVibeRoomsScreen> {
  static const _tabs = ['Saved', 'Upcoming', 'History'];
  String _tab = 'Saved';

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: VibeRoomStore.instance,
    builder: (context, _) {
      final store = VibeRoomStore.instance;
      final rooms = _tab == 'Upcoming'
          ? store.rooms.where((room) => !room.isLive).toList()
          : _tab == 'History'
          ? store.history
          : store.saved;
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textPrimary,
          title: Text(
            'Saved rooms',
            style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
          ),
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 3, 16, 11),
                child: SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: [
                    for (final tab in _tabs)
                      ButtonSegment(value: tab, label: Text(tab)),
                  ],
                  selected: {_tab},
                  onSelectionChanged: (selection) =>
                      setState(() => _tab = selection.first),
                ),
              ),
              Expanded(
                child: rooms.isEmpty
                    ? VibeRoomEmptyState(
                        title: _tab == 'Saved'
                            ? 'No saved rooms yet'
                            : 'Nothing here yet',
                        message: _tab == 'Saved'
                            ? 'Bookmark a room to find it here later.'
                            : 'Rooms you join will show up here.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: rooms.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) => _SavedRoomTile(
                          room: rooms[index],
                          tab: _tab,
                          api: widget.api,
                        ),
                      ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _SavedRoomTile extends StatelessWidget {
  const _SavedRoomTile({
    required this.room,
    required this.tab,
    required this.api,
  });
  final VibeRoom room;
  final String tab;
  final VibeRoomsApi? api;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(17),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: VibeCoverImage(image: room.coverImage, width: 74, height: 78),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                room.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.label.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                tab == 'Upcoming'
                    ? room.scheduledFor ?? 'Upcoming room'
                    : '${room.participantCount} people · ${room.city}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                room.tags.take(2).join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: tab == 'Saved' ? 'Remove bookmark' : 'Open room',
          onPressed: () async {
            if (tab == 'Saved') {
              if (api == null) {
                VibeRoomStore.instance.toggleSaved(room);
                return;
              }
              try {
                await api!.setSaved(room.id, false);
                room.isSaved = false;
                VibeRoomStore.instance.cacheRoom(room);
              } catch (error) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Could not unsave room: $error')),
                );
              }
            } else {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => RoomDetailScreen(room: room, api: api),
                ),
              );
            }
          },
          icon: Icon(
            tab == 'Saved'
                ? Icons.bookmark_rounded
                : Icons.chevron_right_rounded,
            color: tab == 'Saved' ? AppColors.coral : AppColors.textSecondary,
          ),
        ),
      ],
    ),
  );
}
