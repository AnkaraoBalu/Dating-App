import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../home/data/discover_api.dart';
import '../../../home/presentation/screens/discover_filters_screen.dart';
import '../../../home/presentation/screens/discover_people_screen.dart';
import '../../../profile/presentation/widgets/profile_widgets.dart'
    show ProfilePhotoView;
import '../../data/vibe_categories.dart';
import '../../models/vibe_category.dart';
import '../widgets/vibe_category_tile.dart';
import 'trending_vibes_screen.dart';
import 'vibe_feed_screen.dart';
import 'vibe_search_screen.dart';
import 'vibe_selection_screen.dart';

class VibeExploreScreen extends StatelessWidget {
  const VibeExploreScreen({
    super.key,
    required this.api,
    required this.filters,
    required this.onFiltersChanged,
    required this.location,
    required this.selectedVibeIds,
    required this.onSelectionChanged,
    required this.onOpenLikes,
    required this.onOpenProfile,
    required this.onMatch,
    required this.currentUserImage,
    required this.currentUserName,
  });

  final DiscoverApi? api;
  final DiscoverFilterOptions filters;
  final ValueChanged<DiscoverFilterOptions> onFiltersChanged;
  final String? location;
  final Set<String> selectedVibeIds;
  final ValueChanged<Set<String>> onSelectionChanged;
  final VoidCallback onOpenLikes;
  final VoidCallback onOpenProfile;
  final VoidCallback onMatch;
  final String? currentUserImage;
  final String currentUserName;

  VibeCategory? get _mainVibe => selectedVibeIds.isEmpty
      ? null
      : VibeCategories.byId(selectedVibeIds.first);

  Future<void> _openSelection(BuildContext context) async {
    final selection = await Navigator.of(context).push<Set<String>>(
      MaterialPageRoute<Set<String>>(
        builder: (_) => VibeSelectionScreen(initialSelection: selectedVibeIds),
      ),
    );
    if (selection != null) onSelectionChanged(selection);
  }

  Future<void> _openFeed(BuildContext context, VibeCategory category) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => VibeFeedScreen(
          api: api,
          category: category,
          selectedVibeIds: selectedVibeIds,
          filters: filters,
          onFiltersChanged: onFiltersChanged,
          location: location,
          currentUserImage: currentUserImage,
          currentUserName: currentUserName,
          onMatch: onMatch,
        ),
      ),
    );
  }

  Future<void> _openTrending(BuildContext context) =>
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => TrendingVibesScreen(
            api: api,
            filters: filters,
            onFiltersChanged: onFiltersChanged,
            location: location,
            currentUserImage: currentUserImage,
            currentUserName: currentUserName,
            onMatch: onMatch,
          ),
        ),
      );

  Future<void> _openSearch(BuildContext context) =>
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => VibeSearchScreen(
            api: api,
            filters: filters,
            onFiltersChanged: onFiltersChanged,
            location: location,
            currentUserImage: currentUserImage,
            currentUserName: currentUserName,
            onMatch: onMatch,
          ),
        ),
      );

  Future<void> _openPeople(BuildContext context, DiscoverPeopleMode mode) =>
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => DiscoverPeopleScreen(
            mode: mode,
            api: api,
            location: location,
            filters: filters,
            interest: _mainVibe?.interests.firstOrNull,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final selectedVibes = VibeCategories.all
        .where((vibe) => selectedVibeIds.contains(vibe.id))
        .toList();
    final featured = selectedVibes.isNotEmpty
        ? selectedVibes
        : VibeCategories.all.take(4).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 26),
        children: [
          Row(
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: AppTypography.h3.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -.7,
                    ),
                    children: const [
                      TextSpan(text: 'matchify'),
                      TextSpan(
                        text: '✦',
                        style: TextStyle(color: AppColors.coral, fontSize: 26),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Search vibes and people',
                onPressed: () => _openSearch(context),
                icon: const Icon(Icons.search_rounded),
              ),
              IconButton(
                tooltip: 'Likes received',
                onPressed: onOpenLikes,
                icon: const Icon(
                  Icons.favorite_border_rounded,
                  color: AppColors.coralPressed,
                ),
              ),
              GestureDetector(
                onTap: onOpenProfile,
                child: Container(
                  width: 36,
                  height: 36,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.coral, width: 1.4),
                  ),
                  child: ClipOval(child: ProfilePhotoView(currentUserImage)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.coralSoft, AppColors.peachSoft],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.coral.withValues(alpha: .2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: Colors.white70,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.coralPressed,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'What’s your vibe today?',
                        style: AppTypography.label.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Find people who share your current mood ✨',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Explore by vibe',
                  style: AppTypography.h3.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => _openSearch(context),
                icon: const Icon(Icons.search_rounded, size: 17),
                label: const Text('Search'),
                style: TextButton.styleFrom(foregroundColor: AppColors.coral),
              ),
            ],
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: VibeCategories.all.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.sizeOf(context).width < 340 ? 2 : 3,
              mainAxisSpacing: 9,
              crossAxisSpacing: 9,
              childAspectRatio: .82,
            ),
            itemBuilder: (context, index) {
              final category = VibeCategories.all[index];
              return VibeCategoryTile(
                category: category,
                selected: selectedVibeIds.contains(category.id),
                compact: true,
                onTap: () => _openFeed(context, category),
              );
            },
          ),
          const SizedBox(height: 13),
          FilledButton.icon(
            onPressed: () => _openSelection(context),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.coral,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
            ),
            icon: const Icon(Icons.auto_awesome_rounded, size: 18),
            label: Text(
              selectedVibes.isEmpty ? 'Set my vibe' : 'Edit my vibes',
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Explore more',
                  style: AppTypography.h3.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _openTrending(context),
                child: const Text('Trending vibes'),
              ),
            ],
          ),
          SizedBox(
            height: 132,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: featured.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final category = featured[index];
                return SizedBox(
                  width: 146,
                  child: VibeCategoryTile(
                    category: category,
                    selected: selectedVibeIds.contains(category.id),
                    compact: true,
                    onTap: () => _openFeed(context, category),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _shortcut(
                context,
                Icons.location_on_outlined,
                'Nearby',
                () => _openPeople(context, DiscoverPeopleMode.nearby),
              ),
              _shortcut(
                context,
                Icons.circle,
                'Online now',
                () => _openPeople(context, DiscoverPeopleMode.online),
              ),
              _shortcut(
                context,
                Icons.fiber_new_rounded,
                'New faces',
                () => _openPeople(context, DiscoverPeopleMode.newFaces),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _shortcut(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) => ActionChip(
    avatar: Icon(icon, size: 16, color: AppColors.coralPressed),
    label: Text(label),
    onPressed: onTap,
    backgroundColor: AppColors.surface,
    side: const BorderSide(color: AppColors.border),
    labelStyle: AppTypography.caption.copyWith(color: AppColors.textPrimary),
  );
}
