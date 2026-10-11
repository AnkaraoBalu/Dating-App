import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../data/vibe_categories.dart';
import '../../data/vibe_rooms_api.dart';
import '../../data/vibe_room_store.dart';
import '../../models/vibe_category.dart';
import '../../models/vibe_room.dart';
import 'vibe_category_rooms_screen.dart';
import '../widgets/vibe_room_list_widgets.dart';

class VibeRoomCategoriesScreen extends StatefulWidget {
  const VibeRoomCategoriesScreen({super.key, this.api});

  final VibeRoomsApi? api;

  @override
  State<VibeRoomCategoriesScreen> createState() =>
      _VibeRoomCategoriesScreenState();
}

class _VibeRoomCategoriesScreenState extends State<VibeRoomCategoriesScreen> {
  final TextEditingController _search = TextEditingController();
  List<VibeRoom> _databaseRooms = const [];
  bool _loadingRoomCounts = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.api != null) _loadRoomCounts();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final categories = VibeCategories.all.where((category) {
      final matches =
          '${category.title} ${category.description} ${category.interests.join(' ')}'
              .toLowerCase()
              .contains(query);
      return matches;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        title: Text(
          'Explore vibe rooms',
          style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(17, 5, 17, 10),
              child: TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search rooms, moods, interests…',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: AppColors.surfaceSecondary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(17, 0, 17, 24),
                children: [
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: categories.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.04,
                    ),
                    itemBuilder: (context, index) => _CategoryCard(
                      category: categories[index],
                      participantCount: _participantCount(categories[index]),
                      isLoading: _loadingRoomCounts,
                      onTap: () => _openCategory(categories[index]),
                    ),
                  ),
                  if (categories.isEmpty)
                    const VibeRoomEmptyState(
                      title: 'No categories found',
                      message: 'Try a different room name or interest.',
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _participantCount(VibeCategory category) {
    final rooms = widget.api == null
        ? VibeRoomStore.instance.rooms
        : _databaseRooms;
    return rooms
        .where((room) => room.categoryId == category.id)
        .fold<int>(0, (count, room) => count + room.participantCount);
  }

  Future<void> _loadRoomCounts() async {
    final api = widget.api;
    if (api == null) return;
    setState(() => _loadingRoomCounts = true);
    try {
      final rooms = await api.listRooms();
      if (!mounted) return;
      setState(() {
        _databaseRooms = rooms;
        _loadingRoomCounts = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadingRoomCounts = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load room counts: $error')),
      );
    }
  }

  Future<void> _openCategory(VibeCategory category) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) =>
            VibeCategoryRoomsScreen(category: category, api: widget.api),
      ),
    );
    if (widget.api != null && mounted) await _loadRoomCounts();
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.participantCount,
    required this.isLoading,
    required this.onTap,
  });

  final VibeCategory category;
  final int participantCount;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: category.color,
    borderRadius: BorderRadius.circular(19),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(19),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(category.emoji, style: const TextStyle(fontSize: 35)),
            const SizedBox(height: 8),
            Text(
              category.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.label.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              category.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isLoading ? 'Loading rooms…' : '$participantCount people',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
