import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../home/data/discover_api.dart';
import '../../../home/data/home_discover_data.dart';
import '../../../home/presentation/screens/discover_filters_screen.dart';
import '../../../home/presentation/screens/discover_people_screen.dart';
import '../../../home/presentation/screens/discover_travel_screen.dart';
import '../../../home/presentation/screens/profile_quick_preview_screen.dart';
import '../../data/vibe_categories.dart';
import '../../models/vibe_category.dart';
import 'vibe_feed_screen.dart';
import '../../../home/presentation/widgets/home_person_photo.dart';

class VibeSearchScreen extends StatefulWidget {
  const VibeSearchScreen({
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
  State<VibeSearchScreen> createState() => _VibeSearchScreenState();
}

class _VibeSearchScreenState extends State<VibeSearchScreen> {
  static const _tabs = ['People', 'Vibes', 'Places'];
  final TextEditingController _search = TextEditingController();
  late Future<List<HomePerson>> _people;
  String _tab = 'People';

  @override
  void initState() {
    super.initState();
    _people = _loadPeople();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<List<HomePerson>> _loadPeople() {
    final api = widget.api;
    if (api == null) return Future.error(Exception('Discover is unavailable.'));
    return api.discover(
      mode: 'for_you',
      minAge: widget.filters.minAge,
      maxAge: widget.filters.maxAge,
      gender: widget.filters.gender,
      location: widget.location,
      interest: widget.filters.interest,
      interests: widget.filters.interests,
      radiusKm: widget.filters.radiusKm,
      onlineOnly: widget.filters.onlineOnly,
      verifiedOnly: widget.filters.verifiedOnly,
    );
  }

  bool _matchesPerson(HomePerson person, String query) {
    if (query.isEmpty) return true;
    final searchable = [
      person.name,
      person.bio,
      person.distance,
      person.location ?? '',
      ...person.tags,
    ].join(' ').toLowerCase();
    return searchable.contains(query);
  }

  bool _matchesVibe(VibeCategory vibe, String query) {
    if (query.isEmpty) return true;
    return <String>[
      vibe.title,
      vibe.description,
      ...vibe.interests,
    ].join(' ').toLowerCase().replaceAll('_', ' ').contains(query);
  }

  void _openVibe(VibeCategory vibe) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => VibeFeedScreen(
          api: widget.api,
          category: vibe,
          selectedVibeIds: {vibe.id},
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

  Future<void> _openPlaces() async {
    final selectedLocation = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(builder: (_) => const DiscoverTravelScreen()),
    );
    if (selectedLocation == null || !mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => DiscoverPeopleScreen(
          mode: DiscoverPeopleMode.nearby,
          api: widget.api,
          location: selectedLocation,
          filters: widget.filters,
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
        'Search discover',
        style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
      ),
    ),
    body: SafeArea(
      top: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 5, 16, 10),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search people, interests, or vibes…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          _search.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                filled: true,
                fillColor: AppColors.surfaceSecondary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SegmentedButton<String>(
              showSelectedIcon: false,
              segments: [
                for (final tab in _tabs)
                  ButtonSegment<String>(value: tab, label: Text(tab)),
              ],
              selected: {_tab},
              onSelectionChanged: (selected) =>
                  setState(() => _tab = selected.first),
            ),
          ),
          Expanded(child: _results()),
        ],
      ),
    ),
  );

  Widget _results() {
    final query = _search.text.trim().toLowerCase();
    if (_tab == 'Vibes') {
      final vibes = VibeCategories.all
          .where((vibe) => _matchesVibe(vibe, query))
          .toList();
      if (vibes.isEmpty) return _empty('No vibes match that search.');
      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        itemCount: vibes.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final vibe = vibes[index];
          return ListTile(
            onTap: () => _openVibe(vibe),
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            leading: CircleAvatar(
              backgroundColor: vibe.color,
              child: Text(vibe.emoji),
            ),
            title: Text(
              vibe.title,
              style: AppTypography.label.copyWith(color: AppColors.textPrimary),
            ),
            subtitle: Text(
              vibe.description,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
          );
        },
      );
    }
    if (_tab == 'Places') {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.flight_takeoff_rounded,
                color: AppColors.coral,
                size: 44,
              ),
              const SizedBox(height: 12),
              Text(
                'Looking for people in a place?',
                textAlign: TextAlign.center,
                style: AppTypography.label.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose a destination and explore people there.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: _openPlaces,
                icon: const Icon(Icons.map_outlined),
                label: const Text('Explore places'),
              ),
            ],
          ),
        ),
      );
    }

    return FutureBuilder<List<HomePerson>>(
      future: _people,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _empty(
            'Could not load people right now.',
            action: TextButton(
              onPressed: () => setState(() => _people = _loadPeople()),
              child: const Text('Try again'),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.coral),
          );
        }
        final people = snapshot.data!
            .where((person) => _matchesPerson(person, query))
            .toList();
        if (people.isEmpty) return _empty('No people match that search.');
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          itemCount: people.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final person = people[index];
            return ListTile(
              onTap: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => ProfileQuickPreviewScreen(
                    person: person,
                    api: widget.api,
                  ),
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
              leading: ClipOval(
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: HomePersonPhoto.imageFor(
                    person.image,
                    personName: person.name,
                  ),
                ),
              ),
              title: Text(
                '${person.name}, ${person.age}',
                style: AppTypography.label.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              subtitle: Text(
                person.online ? 'Online now' : person.distance,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
            );
          },
        );
      },
    );
  }

  Widget _empty(String message, {Widget? action}) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
          ?action,
        ],
      ),
    ),
  );
}
