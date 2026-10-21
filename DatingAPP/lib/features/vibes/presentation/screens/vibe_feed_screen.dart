import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../home/data/discover_api.dart';
import '../../../home/data/home_discover_data.dart';
import '../../../home/presentation/screens/discover_filters_screen.dart';
import '../../../home/presentation/screens/profile_detail_screen.dart';
import '../../../home/presentation/screens/profile_quick_preview_screen.dart';
import '../../../home/presentation/widgets/home_discover_sections.dart';
import '../../../chat/data/chat_api.dart';
import '../../../matches/presentation/navigation/match_navigation.dart';
import '../../data/vibe_categories.dart';
import '../../models/vibe_category.dart';
import '../../../home/presentation/widgets/home_person_photo.dart';

class VibeFeedScreen extends StatefulWidget {
  const VibeFeedScreen({
    super.key,
    required this.category,
    required this.api,
    required this.selectedVibeIds,
    required this.filters,
    this.onFiltersChanged,
    required this.location,
    required this.currentUserImage,
    required this.currentUserName,
    this.onMatch,
  });

  final VibeCategory category;
  final DiscoverApi? api;
  final Set<String> selectedVibeIds;
  final DiscoverFilterOptions filters;
  final ValueChanged<DiscoverFilterOptions>? onFiltersChanged;
  final String? location;
  final String? currentUserImage;
  final String currentUserName;
  final VoidCallback? onMatch;

  @override
  State<VibeFeedScreen> createState() => _VibeFeedScreenState();
}

class _VibeFeedScreenState extends State<VibeFeedScreen> {
  static const _modes = <(String, String)>[
    ('nearby', 'Nearby'),
    ('new', 'New'),
    ('trending', 'Trending'),
  ];

  late DiscoverFilterOptions _filters;
  String _mode = 'nearby';
  List<HomePerson> _people = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _filters = widget.filters;
    _load();
  }

  Future<void> _load() async {
    final api = widget.api;
    if (api == null) {
      setState(() {
        _loading = false;
        _error = 'Discover is not available right now.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final categories = VibeCategories.all
          .where((vibe) => widget.selectedVibeIds.contains(vibe.id))
          .toList();
      final interests = <String>{
        ...widget.category.interests,
        for (final vibe in categories) ...vibe.interests,
        ..._filters.interests,
      }.toList();
      final people = await api.discover(
        mode: _mode,
        minAge: _filters.minAge,
        maxAge: _filters.maxAge,
        gender: _filters.gender,
        location: widget.location,
        interest: _filters.interest,
        interests: interests,
        radiusKm: _filters.radiusKm,
        onlineOnly: _filters.onlineOnly,
        verifiedOnly: _filters.verifiedOnly,
      );
      if (!mounted) return;
      setState(() {
        _people = people;
        _loading = false;
      });
    } catch (error) {
      debugPrint('[Vibes] Could not load ${widget.category.id}: $error');
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openFilters() async {
    final filters = await Navigator.of(context).push<DiscoverFilterOptions>(
      MaterialPageRoute<DiscoverFilterOptions>(
        builder: (_) => DiscoverFiltersScreen(initial: _filters),
      ),
    );
    if (filters == null || !mounted) return;
    setState(() => _filters = filters);
    widget.onFiltersChanged?.call(filters);
    await _load();
  }

  void _removeTop(HomePerson person) {
    if (!mounted || _people.isEmpty || _people.first.id != person.id) return;
    setState(() => _people = _people.skip(1).toList());
  }

  Future<void> _pass(HomePerson person) async {
    _removeTop(person);
    try {
      await widget.api?.pass(person.id);
    } catch (error) {
      if (!mounted) return;
      _notice('Could not pass this profile: $error');
      unawaited(_load());
    }
  }

  Future<void> _like(HomePerson person) async {
    final api = widget.api;
    if (api == null || person.id.isEmpty) {
      _notice('Unable to send this like right now.');
      return;
    }
    _removeTop(person);
    try {
      final isMatch = await api.like(person.id);
      if (!mounted) return;
      if (isMatch) {
        await MatchNavigation.celebrate(
          context,
          person: person,
          chatApi: ChatApi(
            baseUrl: api.baseUrl,
            getSessionToken: api.getSessionToken,
          ),
          currentUserImage: widget.currentUserImage,
          currentUserName: widget.currentUserName,
        );
        widget.onMatch?.call();
      }
    } catch (error) {
      if (!mounted) return;
      _notice('Could not send like: $error');
      unawaited(_load());
    }
  }

  void _notice(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      titleSpacing: 18,
      title: Row(
        children: [
          Text(widget.category.emoji, style: const TextStyle(fontSize: 23)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.category.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.title.copyWith(
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'Filters',
          onPressed: _openFilters,
          icon: const Icon(Icons.tune_rounded),
        ),
      ],
    ),
    body: SafeArea(
      top: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 5, 18, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.category.description,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                if (widget.location?.isNotEmpty == true)
                  Text(
                    widget.location!,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 2, 18, 8),
            child: SegmentedButton<String>(
              showSelectedIcon: false,
              segments: [
                for (final mode in _modes)
                  ButtonSegment<String>(value: mode.$1, label: Text(mode.$2)),
              ],
              selected: {_mode},
              onSelectionChanged: (selection) {
                setState(() => _mode = selection.first);
                unawaited(_load());
              },
            ),
          ),
          Expanded(child: _feedBody()),
        ],
      ),
    ),
  );

  Widget _feedBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.coral),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: AppColors.textTertiary,
              ),
              const SizedBox(height: 9),
              Text(
                'Could not load this vibe.',
                style: AppTypography.label.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(onPressed: _load, child: const Text('Try again')),
            ],
          ),
        ),
      );
    }
    if (_people.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.category.emoji, style: const TextStyle(fontSize: 42)),
              const SizedBox(height: 10),
              Text(
                'No profiles in this vibe yet',
                textAlign: TextAlign.center,
                style: AppTypography.label.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Try another vibe or adjust your filters.',
                textAlign: TextAlign.center,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final person = _people.first;
    final nextPerson = _people.length > 1 ? _people[1] : null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (nextPerson != null)
                  Positioned.fill(
                    left: 8,
                    right: 8,
                    top: 9,
                    bottom: 0,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(27),
                      child: HomePersonPhoto.imageFor(
                        nextPerson.image,
                        personName: nextPerson.name,
                      ),
                    ),
                  ),
                HomeDiscoverSections.leadCard(
                  key: ValueKey(person.id),
                  person: person,
                  onMore: () => Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          ProfileDetailScreen(person: person, api: widget.api),
                    ),
                  ),
                  onPass: () => unawaited(_pass(person)),
                  onLike: () => unawaited(_like(person)),
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => ProfileQuickPreviewScreen(
                        person: person,
                        api: widget.api,
                      ),
                    ),
                  ),
                  liked: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Swipe to pass or like · tap a profile to preview',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
