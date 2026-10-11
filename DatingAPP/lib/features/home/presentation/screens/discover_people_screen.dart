import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../data/discover_api.dart';
import '../../data/home_discover_data.dart';
import 'discover_filters_screen.dart';
import 'discover_map_screen.dart';
import 'profile_quick_preview_screen.dart';
import '../widgets/home_person_card.dart';

enum DiscoverPeopleMode { nearby, trending, online, newFaces }

class DiscoverPeopleScreen extends StatefulWidget {
  const DiscoverPeopleScreen({
    super.key,
    required this.mode,
    this.api,
    this.location,
    this.filters = const DiscoverFilterOptions(),
    this.interest,
  });

  final DiscoverPeopleMode mode;
  final DiscoverApi? api;
  final String? location;
  final DiscoverFilterOptions filters;
  final String? interest;

  @override
  State<DiscoverPeopleScreen> createState() => _DiscoverPeopleScreenState();
}

class _DiscoverPeopleScreenState extends State<DiscoverPeopleScreen> {
  late Future<List<HomePerson>> _people;

  @override
  void initState() {
    super.initState();
    _people = _load();
  }

  Future<List<HomePerson>> _load() {
    final api = widget.api;
    if (api == null) {
      return Future.error(Exception('Discover service is unavailable.'));
    }
    final mode = switch (widget.mode) {
      DiscoverPeopleMode.nearby => 'nearby',
      DiscoverPeopleMode.trending => 'trending',
      DiscoverPeopleMode.online => 'online',
      DiscoverPeopleMode.newFaces => 'new',
    };
    return api.discover(
      mode: mode,
      minAge: widget.filters.minAge,
      maxAge: widget.filters.maxAge,
      gender: widget.filters.gender,
      location: widget.location,
      interest: widget.interest ?? widget.filters.interest,
      interests: [
        ...widget.filters.interests,
        if (widget.interest != null) widget.interest!,
      ],
      radiusKm: widget.filters.radiusKm,
      onlineOnly:
          widget.filters.onlineOnly || widget.mode == DiscoverPeopleMode.online,
      verifiedOnly: widget.filters.verifiedOnly,
    );
  }

  String get _title => switch (widget.mode) {
    DiscoverPeopleMode.nearby => 'People nearby',
    DiscoverPeopleMode.trending => 'Trending',
    DiscoverPeopleMode.online => 'Online now',
    DiscoverPeopleMode.newFaces => 'New to Matchify',
  };

  String get _subtitle => switch (widget.mode) {
    DiscoverPeopleMode.nearby =>
      'Within ${widget.filters.radiusKm} km · ${widget.location ?? 'Your area'}',
    DiscoverPeopleMode.trending =>
      'Profiles with the strongest shared interests',
    DiscoverPeopleMode.online => 'People recently active and ready to connect',
    DiscoverPeopleMode.newFaces => 'Recently created profiles to meet',
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      title: Text(
        _title,
        style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
      ),
      actions: [
        if (widget.mode == DiscoverPeopleMode.nearby)
          IconButton(
            tooltip: 'Map view',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      DiscoverMapScreen(peopleFuture: _people, api: widget.api),
                ),
              );
            },
            icon: const Icon(Icons.map_outlined),
          ),
      ],
    ),
    body: SafeArea(
      top: false,
      child: FutureBuilder<List<HomePerson>>(
        future: _people,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off_rounded,
                      color: AppColors.textTertiary,
                      size: 42,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Could not load profiles.',
                      style: AppTypography.body.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _people = _load()),
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.coral),
            );
          }
          final people = snapshot.data!;
          if (people.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Text(
                  'No profiles match this view yet. Try another tab or widen your filters.',
                  textAlign: TextAlign.center,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    _subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid.builder(
                  itemCount: people.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: .68,
                  ),
                  itemBuilder: (context, index) {
                    final person = people[index];
                    return HomePersonCard(
                      person: person,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ProfileQuickPreviewScreen(
                            person: person,
                            api: widget.api,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 26)),
            ],
          );
        },
      ),
    ),
  );
}
