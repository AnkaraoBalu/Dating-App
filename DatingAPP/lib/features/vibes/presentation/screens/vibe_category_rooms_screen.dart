import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../data/vibe_rooms_api.dart';
import '../../data/vibe_room_store.dart';
import '../../models/vibe_category.dart';
import '../../models/vibe_room.dart';
import 'create_vibe_room_screen.dart';
import 'room_detail_screen.dart';
import '../widgets/vibe_room_list_widgets.dart';
import '../widgets/vibe_room_widgets.dart';

part '../widgets/vibe_category_room_tile.dart';

class VibeCategoryRoomsScreen extends StatefulWidget {
  const VibeCategoryRoomsScreen({super.key, required this.category, this.api});

  final VibeCategory category;
  final VibeRoomsApi? api;

  @override
  State<VibeCategoryRoomsScreen> createState() =>
      _VibeCategoryRoomsScreenState();
}

class _VibeCategoryRoomsScreenState extends State<VibeCategoryRoomsScreen> {
  static const _filters = ['Popular', 'Live now', 'Upcoming', 'Nearby'];

  final _searchController = TextEditingController();
  final Set<String> _savingRoomIds = {};
  List<VibeRoom> _databaseRooms = const [];
  bool _loadingRooms = false;
  String? _loadError;
  String _filter = _filters.first;

  @override
  void initState() {
    super.initState();
    if (widget.api != null) _loadRooms();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: VibeRoomStore.instance,
    builder: (context, _) {
      final allRooms = VibeRoomStore.instance.rooms
          .where((room) => room.categoryId == widget.category.id)
          .toList();
      final roomsFromSource = widget.api == null ? allRooms : _databaseRooms;
      final rooms = _visibleRooms(roomsFromSource);

      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textPrimary,
          title: Text(
            '${widget.category.emoji} ${widget.category.title}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
          ),
        ),
        body: SafeArea(
          top: false,
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(17, 0, 17, 13),
                child: Text(
                  '${roomsFromSource.length} ${roomsFromSource.length == 1 ? 'room' : 'rooms'} to explore',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 17),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search rooms in ${widget.category.title}…',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                    filled: true,
                    fillColor: AppColors.surfaceSecondary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(17),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 39,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 17),
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final filter = _filters[index];
                    final selected = filter == _filter;
                    return ChoiceChip(
                      label: Text(filter),
                      selected: selected,
                      onSelected: (_) => setState(() => _filter = filter),
                      showCheckmark: false,
                      selectedColor: AppColors.coral,
                      backgroundColor: AppColors.surfaceSecondary,
                      side: BorderSide.none,
                      labelStyle: AppTypography.caption.copyWith(
                        color: selected ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _loadingRooms
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.coral,
                        ),
                      )
                    : _loadError != null
                    ? _errorState()
                    : rooms.isEmpty
                    ? _emptyState(roomsFromSource.isEmpty)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(17, 0, 17, 24),
                        itemCount: rooms.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) => _CategoryRoomTile(
                          room: rooms[index],
                          onTap: () => _openRoom(rooms[index]),
                          onSave: () => _toggleSaved(rooms[index]),
                          isSaving: _savingRoomIds.contains(rooms[index].id),
                        ),
                      ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(17, 7, 17, 10),
            child: FilledButton.icon(
              onPressed: _openCreateRoom,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.coral,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(49),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create a room'),
            ),
          ),
        ),
      );
    },
  );

  List<VibeRoom> _visibleRooms(List<VibeRoom> allRooms) {
    final query = _searchController.text.trim().toLowerCase();
    final results = allRooms.where((room) {
      final matchesQuery =
          query.isEmpty ||
          '${room.title} ${room.description} ${room.hostName} ${room.city} ${room.tags.join(' ')}'
              .toLowerCase()
              .contains(query);
      if (!matchesQuery) return false;

      return switch (_filter) {
        'Live now' => room.isLive,
        'Upcoming' => !room.isLive,
        // Room locations are currently city labels in the local room data.
        'Nearby' => room.city.toLowerCase() == 'hyderabad',
        _ => true,
      };
    }).toList();

    if (_filter == 'Popular') {
      results.sort((a, b) => b.participantCount.compareTo(a.participantCount));
    } else {
      results.sort((a, b) {
        if (a.isLive != b.isLive) return a.isLive ? -1 : 1;
        return b.participantCount.compareTo(a.participantCount);
      });
    }
    return results;
  }

  Widget _errorState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const VibeRoomEmptyState(
            title: 'Could not load rooms',
            message: 'Check your connection and try again.',
          ),
          TextButton.icon(
            onPressed: _loadRooms,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      ),
    ),
  );

  Future<void> _loadRooms() async {
    final api = widget.api;
    if (api == null) return;
    setState(() {
      _loadingRooms = true;
      _loadError = null;
    });
    try {
      final rooms = await api.listRooms(categoryId: widget.category.id);
      if (!mounted) return;
      setState(() {
        _databaseRooms = rooms;
        _loadingRooms = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingRooms = false;
        _loadError = error.toString();
      });
    }
  }

  Future<void> _toggleSaved(VibeRoom room) async {
    final api = widget.api;
    if (api == null) {
      VibeRoomStore.instance.toggleSaved(room);
      return;
    }
    if (_savingRoomIds.contains(room.id)) return;
    final save = !room.isSaved;
    setState(() => _savingRoomIds.add(room.id));
    try {
      await api.setSaved(room.id, save);
      if (!mounted) return;
      setState(() {
        room.isSaved = save;
        _savingRoomIds.remove(room.id);
      });
      VibeRoomStore.instance.cacheRoom(room);
    } catch (error) {
      if (!mounted) return;
      setState(() => _savingRoomIds.remove(room.id));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save room: $error')));
    }
  }

  Future<void> _openCreateRoom() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CreateVibeRoomScreen(
          api: widget.api,
          initialCategoryId: widget.category.id,
        ),
      ),
    );
    if (widget.api != null && mounted) await _loadRooms();
  }

  Widget _emptyState(bool categoryHasNoRooms) {
    final query = _searchController.text.trim();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: VibeRoomEmptyState(
          title: categoryHasNoRooms
              ? 'No rooms in this vibe yet'
              : query.isNotEmpty
              ? 'No matching rooms'
              : 'No rooms in this filter',
          message: categoryHasNoRooms
              ? 'Try another vibe or check back later.'
              : query.isNotEmpty
              ? 'Try another room name, host, or interest.'
              : 'Choose another filter to see more rooms.',
        ),
      ),
    );
  }

  void _openRoom(VibeRoom room) => Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => RoomDetailScreen(room: room, api: widget.api),
    ),
  );
}
