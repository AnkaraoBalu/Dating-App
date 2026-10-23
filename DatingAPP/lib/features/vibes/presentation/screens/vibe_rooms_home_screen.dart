import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/brand_logo.dart';
import '../../../profile/presentation/widgets/profile_widgets.dart'
    show ProfilePhotoView;
import '../../data/vibe_categories.dart';
import '../../data/vibe_rooms_api.dart';
import '../../data/vibe_room_store.dart';
import '../../models/vibe_room.dart';
import '../widgets/vibe_room_widgets.dart';
import 'create_vibe_room_screen.dart';
import 'my_vibe_rooms_screen.dart';
import 'room_detail_screen.dart';
import 'saved_vibe_rooms_screen.dart';
import 'vibe_room_categories_screen.dart';
import '../widgets/vibe_room_list_widgets.dart';

part '../widgets/vibe_rooms_home_sections.dart';

class VibeRoomsHomeScreen extends StatefulWidget {
  const VibeRoomsHomeScreen({
    super.key,
    this.api,
    required this.onOpenLikes,
    required this.onOpenProfile,
    required this.currentUserImage,
    required this.onExplorePeople,
  });

  final VibeRoomsApi? api;
  final VoidCallback onOpenLikes;
  final VoidCallback onOpenProfile;
  final String? currentUserImage;
  final VoidCallback onExplorePeople;

  @override
  State<VibeRoomsHomeScreen> createState() => _VibeRoomsHomeScreenState();
}

class _VibeRoomsHomeScreenState extends State<VibeRoomsHomeScreen> {
  final _store = VibeRoomStore.instance;
  String _category = 'All';
  Timer? _roomRefresh;
  bool _refreshingRooms = false;
  // Until the first load, an empty list means "loading", not "no rooms".
  late bool _loadingRooms = widget.api != null && _store.rooms.isEmpty;
  String? _roomsError;
  final Set<String> _savingRoomIds = {};

  @override
  void initState() {
    super.initState();
    if (widget.api != null) {
      unawaited(_loadDatabaseRooms());
      _roomRefresh = Timer.periodic(const Duration(seconds: 10), (_) {
        if (mounted &&
            ModalRoute.of(context)?.isCurrent == true &&
            WidgetsBinding.instance.lifecycleState ==
                AppLifecycleState.resumed) {
          unawaited(_loadDatabaseRooms(silent: true));
        }
      });
    }
  }

  @override
  void dispose() {
    _roomRefresh?.cancel();
    super.dispose();
  }

  Future<void> _loadDatabaseRooms({bool silent = false}) async {
    if (!mounted || widget.api == null || _refreshingRooms) return;
    _refreshingRooms = true;
    try {
      final rooms = await widget.api!.listRooms();
      if (!mounted) return;
      _store.replaceRooms(rooms);
      setState(() {
        _loadingRooms = false;
        _roomsError = null;
      });
    } catch (error) {
      if (!mounted) return;
      if (_loadingRooms || _store.rooms.isEmpty) {
        setState(() {
          _loadingRooms = false;
          _roomsError = 'Could not load rooms. Check your connection.';
        });
      }
      if (silent) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not sync vibe rooms: $error')),
      );
    } finally {
      _refreshingRooms = false;
    }
  }

  Future<void> _toggleSaved(VibeRoom room) async {
    final api = widget.api;
    if (api == null) {
      _store.toggleSaved(room);
      return;
    }
    if (!_savingRoomIds.add(room.id)) return;
    final save = !_store.savedIds.contains(room.id);
    try {
      await api.setSaved(room.id, save);
      room.isSaved = save;
      _store.cacheRoom(room);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save room: $error')));
    } finally {
      _savingRoomIds.remove(room.id);
    }
  }

  Widget _liveRoomsPlaceholder() {
    if (_loadingRooms) {
      return const Center(child: CircularProgressIndicator());
    }
    final error = _roomsError;
    if (error != null && _store.rooms.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error, textAlign: TextAlign.center),
            TextButton(
              onPressed: () {
                setState(() {
                  _loadingRooms = true;
                  _roomsError = null;
                });
                unawaited(_loadDatabaseRooms());
              },
              child: const Text('Try again'),
            ),
          ],
        ),
      );
    }
    return const Center(child: Text('No live rooms in this vibe yet.'));
  }

  List<VibeRoom> get _liveRooms => _store.rooms.where((room) {
    final matchesCategory = _category == 'All' || room.categoryId == _category;
    return room.isLive && matchesCategory;
  }).toList();

  List<VibeRoom> get _upcomingRooms =>
      _store.rooms.where((room) => !room.isLive).take(4).toList();

  void _openRoom(VibeRoom room) => Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => RoomDetailScreen(room: room, api: widget.api),
    ),
  );

  void _openCategories() => Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => VibeRoomCategoriesScreen(api: widget.api),
    ),
  );

  void _createRoom() => Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => CreateVibeRoomScreen(api: widget.api),
    ),
  );

  void _openMyRooms() => Navigator.of(context).push<void>(
    MaterialPageRoute<void>(builder: (_) => MyVibeRoomsScreen(api: widget.api)),
  );

  void _openSaved() => Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => SavedVibeRoomsScreen(api: widget.api),
    ),
  );

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _store,
    builder: (context, _) => Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 7, 18, 26),
          children: [
            _header(),
            const SizedBox(height: 14),
            Text(
              'Find your people',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'What’s your vibe today?',
                    style: AppTypography.h2.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: _openCategories,
                  tooltip: 'Search vibe rooms',
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.surfaceSecondary,
                    foregroundColor: AppColors.textPrimary,
                  ),
                  icon: const Icon(Icons.search_rounded),
                ),
              ],
            ),
            const SizedBox(height: 11),
            _categoryFilters(),
            const SizedBox(height: 15),
            _featuredRoom(),
            const SizedBox(height: 21),
            VibeRoomSectionTitle(
              title: 'Live right now',
              subtitle: 'Drop into a room and say hello',
              actionLabel: 'See all',
              onAction: _openCategories,
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 252,
              child: _liveRooms.isEmpty
                  ? _liveRoomsPlaceholder()
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _liveRooms.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 11),
                      itemBuilder: (context, index) {
                        final room = _liveRooms[index];
                        return VibeRoomCard(
                          room: room,
                          width: 232,
                          saved: _store.savedIds.contains(room.id),
                          onTap: () => _openRoom(room),
                          onSave: () => _toggleSaved(room),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 19),
            VibeRoomSectionTitle(
              title: 'For you',
              subtitle: 'Rooms that match your energy',
              actionLabel: 'Explore',
              onAction: _openCategories,
            ),
            const SizedBox(height: 10),
            if (_upcomingRooms.isNotEmpty)
              SizedBox(
                height: 252,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _upcomingRooms.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 11),
                  itemBuilder: (context, index) {
                    final room = _upcomingRooms[index];
                    return VibeRoomCard(
                      room: room,
                      width: 232,
                      saved: _store.savedIds.contains(room.id),
                      onTap: () => _openRoom(room),
                      onSave: () => _toggleSaved(room),
                    );
                  },
                ),
              ),
            const SizedBox(height: 18),
            _roomActions(),
            const SizedBox(height: 22),
            VibeRoomSectionTitle(
              title: 'Explore people by vibe',
              subtitle: 'Find a one-to-one connection through shared interests',
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: widget.onExplorePeople,
              icon: const Icon(Icons.favorite_border_rounded),
              label: const Text('Discover people by vibe'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.coralPressed,
                side: const BorderSide(color: AppColors.coral),
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _header() => Row(
    children: [
      Expanded(
        child: const Align(
          alignment: Alignment.centerLeft,
          child: BrandLogo(),
        ),
      ),
      IconButton(
        tooltip: 'Likes received',
        onPressed: widget.onOpenLikes,
        icon: const Icon(
          Icons.favorite_border_rounded,
          color: AppColors.coralPressed,
        ),
      ),
      GestureDetector(
        onTap: widget.onOpenProfile,
        child: Container(
          width: 37,
          height: 37,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.coral, width: 1.4),
          ),
          child: ClipOval(child: ProfilePhotoView(widget.currentUserImage)),
        ),
      ),
    ],
  );

  Widget _categoryFilters() {
    final categories = <(String, String)>[
      ('All', '✨'),
      for (final category in VibeCategories.all.take(7))
        (category.id, category.emoji),
    ];
    return SizedBox(
      height: 43,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 7),
        itemBuilder: (context, index) {
          final category = categories[index];
          final selected = _category == category.$1;
          final label = category.$1 == 'All'
              ? 'All'
              : VibeCategories.byId(category.$1)?.title ?? category.$1;
          return ChoiceChip(
            label: Text('${category.$2} $label'),
            selected: selected,
            onSelected: (_) => setState(() => _category = category.$1),
            selectedColor: AppColors.coralSoft,
            backgroundColor: AppColors.surface,
            side: BorderSide(
              color: selected ? AppColors.coral : AppColors.border,
            ),
            labelStyle: AppTypography.caption.copyWith(
              color: selected ? AppColors.coralPressed : AppColors.textPrimary,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          );
        },
      ),
    );
  }
}
