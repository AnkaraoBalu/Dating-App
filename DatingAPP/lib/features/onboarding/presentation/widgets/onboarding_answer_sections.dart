part of '../screens/onboarding_questions_screen.dart';

extension _OnboardingAnswerSections on _OnboardingQuestionsScreenState {
  Widget _vibeChoice() => ListView.separated(
    itemCount: OnboardingQuestionOptions.vibes.length,
    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
    itemBuilder: (context, index) {
      final (value, label, description) =
          OnboardingQuestionOptions.vibes[index];
      return OnboardingChoiceTile(
        label: label,
        description: description,
        dark: true,
        leading: _vibeLeading(value),
        selected: _vibeType == value,
        enabled: !_busy,
        onTap: () => _refresh(() => _vibeType = value),
      );
    },
  );

  Widget _vibeLeading(String value) {
    final icon = switch (value) {
      'golden_retriever' => Icons.pets_rounded,
      'black_cat' => Icons.nightlight_round,
      'social_butterfly' => Icons.flutter_dash_rounded,
      'chill_and_balanced' => Icons.spa_rounded,
      'ambitious_energy' => Icons.bolt_rounded,
      _ => Icons.auto_awesome_rounded,
    };
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.peachSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: AppColors.forestDark),
    );
  }

  Widget _fridayChoice() => LayoutBuilder(
    builder: (context, constraints) {
      final width = (constraints.maxWidth - 10) / 2;
      return GridView.builder(
        itemCount: OnboardingQuestionOptions.idealFridays.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: constraints.maxWidth > 540 ? 3 : 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          mainAxisExtent: width.clamp(110.0, 145.0),
        ),
        itemBuilder: (context, index) {
          final (value, label, icon) =
              OnboardingQuestionOptions.idealFridays[index];
          final selected = _idealFriday == value;
          final image = switch (value) {
            'rooftop' => AppAssets.welcomeBackground,
            'movie_and_food' => AppAssets.welcomeConnection,
            'club' || 'house_party' || 'live_music' => AppAssets.loginAmbient,
            'long_drive' =>
              'assets/images/boys-images/sunset_jacket_portrait.png',
            'cafe_hopping' =>
              'assets/images/girls-images/cafe_coffee_portrait.png',
            'quiet_evening' || 'cozy_night_in' => AppAssets.welcomeNewChapter,
            _ => AppAssets.welcomeEnergy,
          };
          return Material(
            color: Colors.transparent,
            child: InkWell(
              splashFactory: NoSplash.splashFactory,
              overlayColor: const WidgetStatePropertyAll(Colors.transparent),
              onTap: _busy ? null : () => _refresh(() => _idealFriday = value),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected ? AppColors.coral : Colors.white54,
                    width: selected ? 2.5 : 1,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: AppColors.coral.withValues(alpha: 0.45),
                            blurRadius: 12,
                          ),
                        ]
                      : null,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(image, fit: BoxFit.cover),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Color(0xDD081714)],
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(icon, color: Colors.white, size: 17),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  label,
                                  maxLines: 2,
                                  textAlign: TextAlign.center,
                                  style: AppTypography.caption.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (selected)
                        const Positioned(
                          right: 7,
                          top: 7,
                          child: Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.success,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );

  Widget _eraChoice() => ListView.separated(
    itemCount: OnboardingQuestionOptions.currentEras.length,
    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
    itemBuilder: (context, index) {
      final (value, label, icon) = OnboardingQuestionOptions.currentEras[index];
      return OnboardingChoiceTile(
        label: label,
        icon: icon,
        dark: true,
        selected: _currentEra == value,
        enabled: !_busy,
        onTap: () => _refresh(() => _currentEra = value),
      );
    },
  );

  Widget _singleChoice(
    List<(String, String, IconData)> options,
    String? selected,
    ValueChanged<String> onSelected,
  ) => ListView.separated(
    itemCount: options.length,
    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
    itemBuilder: (context, index) {
      final (value, label, icon) = options[index];
      return OnboardingChoiceTile(
        label: label,
        icon: icon,
        dark: _step >= _OnboardingQuestionsScreenState._basicsSteps,
        selected: selected == value,
        enabled: !_busy,
        onTap: () => onSelected(value),
      );
    },
  );

  Widget _multiChoice(
    List<(String, String, IconData)> options,
    Set<String> selected,
    ValueChanged<String> onToggle,
  ) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth > 520 ? 3 : 2;
      return GridView.builder(
        itemCount: options.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
          mainAxisExtent: 54,
        ),
        itemBuilder: (context, index) {
          final (value, label, icon) = options[index];
          final selectionLimit = switch (_step) {
            6 => 5,
            7 => 5 - _selectedArtists.length,
            9 => 8,
            _ => null,
          };
          return OnboardingOptionChip(
            label: label,
            icon: icon,
            dark: _step >= _OnboardingQuestionsScreenState._basicsSteps,
            selected: selected.contains(value),
            enabled:
                !_busy &&
                (selectionLimit == null ||
                    selected.contains(value) ||
                    selected.length < selectionLimit),
            onTap: () => onToggle(value),
          );
        },
      );
    },
  );

  Widget _musicChoice() => OnboardingMusicQuestion(
    genres: _selectedGenres,
    artists: _selectedArtists,
    enabled: !_busy,
    dark: true,
    onChanged: (selection) => _refresh(() {
      _selectedGenres = selection.genres;
      _selectedArtists = selection.artists;
    }),
  );

  Widget _dealbreakerChoice() => _multiChoice(
    OnboardingQuestionOptions.dealbreakers,
    _dealbreakers,
    (value) => _refresh(() => _toggleDealbreaker(value)),
  );

  Widget _locationPreferences() => OnboardingLocationQuestion(
    distanceKm: _preferredDistanceKm,
    onlyNearby: _onlyShowPeopleNearby,
    enabled: !_busy,
    dark: true,
    onDistanceChanged: (distance) =>
        _refresh(() => _preferredDistanceKm = distance),
    onNearbyChanged: (value) => _refresh(() => _onlyShowPeopleNearby = value),
  );
}
