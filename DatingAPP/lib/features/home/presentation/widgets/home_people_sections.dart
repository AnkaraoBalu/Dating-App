part of '../screens/home_screen.dart';

extension _HomePeopleSections on _HomeScreenState {
  Widget _sectionHeading(String title, VoidCallback onSeeAll) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
        ),
      ),
      TextButton(
        onPressed: onSeeAll,
        child: Text(
          'See all',
          style: AppTypography.label.copyWith(color: AppColors.coral),
        ),
      ),
    ],
  );

  // Kept while the "People near you" row is hidden in home_feed_layout.dart.
  // ignore: unused_element
  Widget _nearbyPeople() {
    final people = _nearby;
    if (people.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: Text(
          'More people are joining nearby. Check back soon.',
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      );
    }
    return SizedBox(
      height: 230,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        scrollDirection: Axis.horizontal,
        itemCount: people.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) => HomePersonCard(
          person: people[index],
          onTap: () => _openPreview(people[index]),
        ),
      ),
    );
  }

  Widget _peopleState() {
    if (_loadingPeople) {
      return const Padding(
        padding: EdgeInsets.all(36),
        child: Center(child: CircularProgressIndicator(color: AppColors.coral)),
      );
    }
    final message = _peopleError != null
        ? 'Could not load profiles. Check your connection and try again.'
        : switch (_emptyReason) {
            'distance' =>
              'No new profiles are available within ${_filters.radiusKm} km. Expand your distance to discover more people.',
            'filters' =>
              'No new profiles match your filters. Try a wider age range or fewer filters.',
            'exhausted' =>
              'You’re caught up with the available profiles matching your preferences. Check back for new people.',
            'no_profiles' =>
              'More people are joining. Check back soon for profiles matching your preferences.',
            _ =>
              'No new profiles are available right now. Adjust your filters or check back later.',
          };
    return Column(
      children: [
        Icon(
          _peopleError == null
              ? Icons.people_outline_rounded
              : Icons.cloud_off_rounded,
          size: 42,
          color: AppColors.textTertiary,
        ),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        if (_peopleError != null) ...[
          const SizedBox(height: 12),
          TextButton(onPressed: _loadPeople, child: const Text('Retry')),
        ] else ...[
          const SizedBox(height: 12),
          if (_emptyReason == 'exhausted' && _nextReplayBefore != null)
            FilledButton(
              onPressed:
                  _pendingPassIds.isNotEmpty || _pendingLikeIds.isNotEmpty
                  ? null
                  : _replayPassedProfiles,
              child: const Text('View profiles again'),
            ),
          if (_emptyReason == 'distance' && _filters.nearbyOnly)
            FilledButton(
              onPressed: _expandingDistance ? null : _expandDiscoveryDistance,
              child: Text(
                _expandingDistance
                    ? 'Updating distance...'
                    : nextDiscoveryRadius(_filters.radiusKm) != null
                    ? 'Expand to ${nextDiscoveryRadius(_filters.radiusKm)} km'
                    : 'Show people further away',
              ),
            ),
          if (_emptyReason == 'distance' || _emptyReason == 'filters')
            TextButton(
              onPressed: _expandingDistance ? null : _openFilters,
              child: const Text('Edit filters'),
            ),
          TextButton(
            onPressed: _expandingDistance ? null : _loadPeople,
            child: const Text('Refresh'),
          ),
        ],
      ],
    );
  }
}
