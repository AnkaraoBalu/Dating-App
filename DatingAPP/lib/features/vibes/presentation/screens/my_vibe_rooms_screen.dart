import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../data/vibe_rooms_api.dart';
import '../../data/vibe_room_store.dart';
import '../../models/vibe_room.dart';
import 'live_vibe_room_screen.dart';
import 'room_detail_screen.dart';
import 'room_settings_screen.dart';
import '../widgets/vibe_room_list_widgets.dart';
import '../widgets/vibe_room_widgets.dart';

class MyVibeRoomsScreen extends StatefulWidget {
  const MyVibeRoomsScreen({super.key, this.initialTab = 'Joined', this.api});

  final String initialTab;
  final VibeRoomsApi? api;

  @override
  State<MyVibeRoomsScreen> createState() => _MyVibeRoomsScreenState();
}

class _MyVibeRoomsScreenState extends State<MyVibeRoomsScreen> {
  late String _tab = widget.initialTab;
  static const _tabs = ['Joined', 'Hosting', 'Saved'];

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: VibeRoomStore.instance,
    builder: (context, _) {
      final store = VibeRoomStore.instance;
      final rooms = _tab == 'Hosting'
          ? store.hosted
          : _tab == 'Saved'
          ? store.saved
          : store.joined;
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textPrimary,
          title: Text(
            'My vibe rooms',
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
                    ? const Center(
                        child: VibeRoomEmptyState(
                          title: 'No rooms here yet',
                          message: 'Join a room or save one to find it here.',
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
                        itemCount: rooms.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) => _MyRoomTile(
                          room: rooms[index],
                          hosting: _tab == 'Hosting',
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

class _MyRoomTile extends StatelessWidget {
  const _MyRoomTile({
    required this.room,
    required this.hosting,
    required this.api,
  });
  final VibeRoom room;
  final bool hosting;
  final VibeRoomsApi? api;

  /// Marks the room live for everyone, then opens it.
  Future<void> _goLive(BuildContext context) async {
    final api = this.api;
    var live = room;
    if (api == null) {
      VibeRoomStore.instance.goLive(room);
    } else {
      try {
        live = await api.updateRoom(room.id, isLive: true);
        VibeRoomStore.instance.cacheRoom(live);
      } catch (error) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not go live: $error')));
        return;
      }
    }
    if (!context.mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => LiveVibeRoomScreen(room: live, api: api),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.border),
    ),
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _openDetails(context),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: VibeCoverImage(
                image: room.coverImage,
                width: 76,
                height: 78,
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: GestureDetector(
              onTap: () => _openDetails(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  Row(
                    children: [
                      Icon(
                        room.isLive ? Icons.circle : Icons.schedule_rounded,
                        size: 11,
                        color: room.isLive
                            ? AppColors.success
                            : AppColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          room.isLive
                              ? '${room.participantCount} live now'
                              : room.scheduledFor ?? 'Room preview',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    room.tags.take(2).join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.coralPressed,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          if (hosting)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Room settings',
                  onPressed: () => Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => RoomSettingsScreen(room: room, api: api),
                    ),
                  ),
                  icon: const Icon(
                    Icons.settings_outlined,
                    color: AppColors.textSecondary,
                  ),
                ),
                TextButton(
                  onPressed: () => _goLive(context),
                  child: const Text('Go live'),
                ),
              ],
            )
          else
            IconButton(
              tooltip: 'Open room',
              onPressed: () => _openDetails(context),
              icon: const Icon(Icons.chevron_right_rounded),
            ),
        ],
      ),
    ),
  );

  void _openDetails(BuildContext context) => Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => RoomDetailScreen(room: room, api: api),
    ),
  );
}
