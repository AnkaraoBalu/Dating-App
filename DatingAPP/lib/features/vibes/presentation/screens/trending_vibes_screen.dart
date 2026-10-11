import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../home/data/discover_api.dart';
import '../../../home/data/home_discover_data.dart';
import '../../../home/presentation/screens/discover_filters_screen.dart';
import '../../data/vibe_categories.dart';
import '../../models/vibe_category.dart';
import 'vibe_feed_screen.dart';

class TrendingVibesScreen extends StatefulWidget {
  const TrendingVibesScreen({
    super.key,
    required this.api,
    required this.filters,
    this.onFiltersChanged,
    required this.location,
    this.currentUserImage,
    this.currentUserName = 'You',
    this.onMatch,
  });

  final DiscoverApi? api;
  final DiscoverFilterOptions filters;
  final ValueChanged<DiscoverFilterOptions>? onFiltersChanged;
  final String? location;
  final String? currentUserImage;
  final String currentUserName;
  final VoidCallback? onMatch;

  @override
  State<TrendingVibesScreen> createState() => _TrendingVibesScreenState();
}

class _TrendingVibesScreenState extends State<TrendingVibesScreen> {
  late Future<List<HomePerson>> _people;

  @override
  void initState() {
    super.initState();
    _people = _load();
  }

  Future<List<HomePerson>> _load() {
    final api = widget.api;
    if (api == null) return Future.error(Exception('Discover is unavailable.'));
    return api.discover(
      mode: 'trending',
      minAge: widget.filters.minAge,
      maxAge: widget.filters.maxAge,
      gender: widget.filters.gender,
      location: widget.location,
      interests: widget.filters.interests,
      radiusKm: widget.filters.radiusKm,
      onlineOnly: widget.filters.onlineOnly,
      verifiedOnly: widget.filters.verifiedOnly,
    );
  }

  void _openVibe(BuildContext context, VibeCategory category) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => VibeFeedScreen(
          api: widget.api,
          category: category,
          selectedVibeIds: {category.id},
          filters: widget.filters,
          onFiltersChanged: widget.onFiltersChanged,
          location: widget.location,
          currentUserImage: widget.currentUserImage,
          currentUserName: widget.currentUserName,
          onMatch: widget.onMatch,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      title: Text(
        'Trending vibes',
        style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
      ),
    ),
    body: SafeArea(
      top: false,
      child: FutureBuilder<List<HomePerson>>(
        future: _people,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _message(
              'Could not load trending vibes.',
              action: TextButton(
                onPressed: () => setState(() => _people = _load()),
                child: const Text('Try again'),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.coral),
            );
          }

          final people = snapshot.data!;
          final categories = [...VibeCategories.all]
            ..sort((first, second) {
              final countDifference =
                  _count(second, people) - _count(first, people);
              if (countDifference != 0) return countDifference;
              return VibeCategories.all
                  .indexOf(first)
                  .compareTo(VibeCategories.all.indexOf(second));
            });

          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
            children: [
              Text(
                'Vibes showing up most in your suggestions',
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              for (var index = 0; index < categories.length; index++) ...[
                _trendingTile(context, categories[index], index, people),
                if (index < categories.length - 1)
                  const Divider(height: 1, color: AppColors.border),
              ],
            ],
          );
        },
      ),
    ),
  );

  int _count(VibeCategory category, List<HomePerson> people) {
    final tags = category.interests.map(_normalize).toSet();
    return people.where((person) {
      return person.tags.map(_normalize).any(tags.contains);
    }).length;
  }

  String _normalize(String value) =>
      value.trim().toLowerCase().replaceAll('_', ' ');

  Widget _trendingTile(
    BuildContext context,
    VibeCategory category,
    int rank,
    List<HomePerson> people,
  ) {
    final count = _count(category, people);
    return InkWell(
      onTap: () => _openVibe(context, category),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            SizedBox(
              width: 26,
              child: Text(
                '${rank + 1}',
                style: AppTypography.label.copyWith(
                  color: rank == 0
                      ? AppColors.coralPressed
                      : AppColors.textTertiary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            SizedBox(
              width: 50,
              height: 50,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: category.color,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: Text(
                    category.emoji,
                    style: const TextStyle(fontSize: 25),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.title,
                    style: AppTypography.label.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    category.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '$count profiles in your suggestions',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.trending_up_rounded,
              color: AppColors.coral,
              size: 19,
            ),
          ],
        ),
      ),
    );
  }

  Widget _message(String message, {Widget? action}) => Center(
    child: Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
          if (action != null) action,
        ],
      ),
    ),
  );
}
