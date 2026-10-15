part of '../screens/home_screen.dart';

extension _HomeFeedLayout on _HomeScreenState {
  Widget _discover() => CustomScrollView(
    physics: const BouncingScrollPhysics(),
    slivers: [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
        sliver: SliverToBoxAdapter(child: _header()),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        sliver: SliverToBoxAdapter(child: _quickFilters()),
      ),
      if (_selectedTab == 0) ..._forYouSlivers(),
      if (_selectedTab == 1) ..._peopleSlivers(DiscoverPeopleMode.nearby),
      if (_selectedTab == 2) ..._peopleSlivers(DiscoverPeopleMode.trending),
    ],
  );

  List<Widget> _forYouSlivers() => [
    if (_loadingPeople || _peopleError != null || _people.isEmpty)
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(18, 36, 18, 24),
        sliver: SliverToBoxAdapter(child: _peopleState()),
      ),
    if (!_loadingPeople && _peopleError == null && _people.isNotEmpty)
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverToBoxAdapter(
          child: SizedBox(
            height: 500,
            child: PageView.builder(
              controller: _feedController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _feedPeople.length,
              onPageChanged: (index) => _refresh(() => _liked = false),
              itemBuilder: (context, index) {
                final person = _feedPeople[index];
                return HomeDiscoverSections.leadCard(
                  key: ValueKey(person.id),
                  person: person,
                  onMore: () => _showActions(person),
                  onTap: () => _openPreview(person),
                  onPass: () => _pass(person),
                  onLike: () => _like(person),
                  liked: _liked,
                );
              },
            ),
          ),
        ),
      ),
    if (!_loadingPeople && _peopleError == null && _people.isNotEmpty)
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
        sliver: SliverToBoxAdapter(
          child: _sectionHeading(
            'People near you',
            () => _openPeople(DiscoverPeopleMode.nearby),
          ),
        ),
      ),
    if (!_loadingPeople && _peopleError == null && _people.isNotEmpty)
      SliverToBoxAdapter(child: _nearbyPeople()),
    SliverPadding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
      sliver: SliverToBoxAdapter(
        child: _sectionHeading('Explore your interests', _openCategories),
      ),
    ),
    SliverToBoxAdapter(child: _exploreModes()),
    SliverPadding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
      sliver: SliverToBoxAdapter(child: _upgradeBanner()),
    ),
  ];

  List<Widget> _peopleSlivers(DiscoverPeopleMode mode) {
    final people = _people;
    return [
      if (_loadingPeople || _peopleError != null || people.isEmpty)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 40, 18, 20),
          sliver: SliverToBoxAdapter(child: _peopleState()),
        ),
      if (!_loadingPeople && _peopleError == null && people.isNotEmpty)
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    mode == DiscoverPeopleMode.nearby
                        ? 'Within ${_filters.radiusKm} km · ${_travelLocation ?? _memberLocation ?? 'Your city'}'
                        : 'Most active & popular profiles',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      if (!_loadingPeople && _peopleError == null && people.isNotEmpty)
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
                onTap: () => _openPreview(person),
              );
            },
          ),
        ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
        sliver: SliverToBoxAdapter(child: _exploreModes()),
      ),
    ];
  }
}
