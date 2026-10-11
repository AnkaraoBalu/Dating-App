import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/theme.dart';
import '../../data/vibe_rooms_api.dart';
import '../../data/vibe_room_store.dart';
import '../../models/vibe_room.dart';
import '../widgets/room_detail_widgets.dart';
import '../widgets/vibe_room_widgets.dart';
import 'live_vibe_room_screen.dart';
import 'vibe_room_people_screen.dart';
import '../widgets/vibe_room_list_widgets.dart';

class RoomDetailScreen extends StatefulWidget {
  const RoomDetailScreen({super.key, required this.room, this.api});

  final VibeRoom room;
  final VibeRoomsApi? api;

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  final _store = VibeRoomStore.instance;
  bool _joining = false;

  void _openPeople() => Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => VibeRoomPeopleScreen(room: widget.room),
    ),
  );

  Future<VibeRoom?> _joinRoom() async {
    if (_joining) return null;
    setState(() => _joining = true);
    try {
      final room = widget.api == null
          ? widget.room
          : await widget.api!.joinRoom(widget.room.id);
      if (widget.api == null) {
        _store.join(room);
      } else {
        _store.cacheRoom(room);
      }
      return room;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not join this room: $error')),
        );
      }
      return null;
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  Future<void> _enterRoom({bool voice = false}) async {
    final room = await _joinRoom();
    if (room == null || !mounted) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            LiveVibeRoomScreen(room: room, api: widget.api, voiceMode: voice),
      ),
    );
  }

  Future<void> _saveSpot() async {
    final room = await _joinRoom();
    if (room == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('You saved a spot in ${room.title}.')),
    );
  }

  Future<void> _toggleSaved() async {
    final room = widget.room;
    final shouldSave = widget.api == null
        ? !_store.savedIds.contains(room.id)
        : !room.isSaved;
    if (widget.api == null) {
      _store.toggleSaved(room);
      return;
    }

    try {
      await widget.api!.setSaved(room.id, shouldSave);
      if (!mounted) return;
      setState(() => room.isSaved = shouldSave);
      VibeRoomStore.instance.cacheRoom(room);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update saved room: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _store,
    builder: (context, _) {
      final room = widget.room;
      final saved = widget.api == null
          ? _store.savedIds.contains(room.id)
          : room.isSaved;
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          top: false,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                backgroundColor: AppColors.background,
                foregroundColor: AppColors.textPrimary,
                flexibleSpace: FlexibleSpaceBar(
                  background: VibeRoomCover(
                    asset: room.coverAsset,
                    height: 250,
                    borderRadius: 0,
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                        child: Text(
                          '${room.emoji} ${room.title}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.h2.copyWith(
                            color: Colors.white,
                            fontSize: 24,
                            shadows: const [
                              Shadow(color: Colors.black54, blurRadius: 8),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                actions: [
                  IconButton(
                    tooltip: saved ? 'Remove from saved' : 'Save room',
                    onPressed: _toggleSaved,
                    icon: Icon(
                      saved
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Share room',
                    onPressed: () => _share(context, room),
                    icon: const Icon(Icons.ios_share_rounded),
                  ),
                  const SizedBox(width: 6),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(19, 18, 19, 100),
                sliver: SliverList.list(
                  children: [
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: [
                        VibeRoomMetaChip(
                          icon: room.isLive
                              ? Icons.circle
                              : Icons.schedule_rounded,
                          label: room.isLive
                              ? 'Live now'
                              : room.scheduledFor ?? 'Upcoming',
                          color: room.isLive
                              ? AppColors.coral
                              : AppColors.forest,
                        ),
                        VibeRoomMetaChip(
                          icon: Icons.people_alt_outlined,
                          label: '${room.participantCount} people in room',
                        ),
                        VibeRoomMetaChip(
                          icon: Icons.location_on_outlined,
                          label: room.city,
                        ),
                      ],
                    ),
                    const SizedBox(height: 17),
                    Text(
                      room.description,
                      style: AppTypography.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: room.tags
                          .map(
                            (tag) => Chip(
                              label: Text(tag),
                              visualDensity: VisualDensity.compact,
                              backgroundColor: AppColors.surfaceSecondary,
                              side: BorderSide.none,
                              labelStyle: AppTypography.caption.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 22),
                    VibeRoomSectionTitle(
                      title: 'Hosted by',
                      actionLabel: 'View people',
                      onAction: _openPeople,
                    ),
                    const SizedBox(height: 9),
                    VibeRoomHostCard(room: room),
                    const SizedBox(height: 14),
                    InkWell(
                      onTap: _openPeople,
                      borderRadius: BorderRadius.circular(17),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(17),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            VibeRoomAvatarStack(
                              members: room.members.take(5).toList(),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Text(
                                '${room.participantCount} people are in this room',
                                style: AppTypography.label.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Room guidelines',
                      style: AppTypography.h3.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...room.guidelines.map(
                      (line) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.favorite_rounded,
                              size: 17,
                              color: AppColors.coral,
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                line,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _joining
                                ? null
                                : () => _enterRoom(voice: true),
                            icon: const Icon(Icons.headphones_rounded),
                            label: const Text('Voice room'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _joining ? null : () => _enterRoom(),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.coral,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.chat_bubble_outline_rounded),
                            label: const Text('Preview room'),
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
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
            child: FilledButton(
              onPressed: _joining
                  ? null
                  : room.isLive
                  ? () => _enterRoom()
                  : _saveSpot,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.coral,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
              ),
              child: Text(
                _joining
                    ? 'Joining…'
                    : room.isLive
                    ? 'Join this vibe'
                    : 'Save a spot',
              ),
            ),
          ),
        ),
      );
    },
  );

  Future<void> _share(BuildContext context, VibeRoom room) async {
    await Clipboard.setData(
      ClipboardData(text: 'Join ${room.title} on Matchify · Room ${room.id}'),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Room invite copied.')));
  }
}
