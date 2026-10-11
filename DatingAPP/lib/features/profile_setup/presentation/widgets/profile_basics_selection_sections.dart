part of '../screens/profile_basics_screen.dart';

extension _ProfileBasicsSelectionSections on _ProfileBasicsScreenState {
  Widget _introSection() => Column(
    children: [
      const SizedBox(height: 26),
      Container(
        width: 142,
        height: 142,
        decoration: BoxDecoration(
          color: AppColors.coralSoft,
          borderRadius: BorderRadius.circular(34),
        ),
        child: const Icon(
          Icons.badge_outlined,
          color: AppColors.coral,
          size: 76,
        ),
      ),
      const SizedBox(height: 28),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: _basicsCardDecoration(),
        child: Column(
          children: [
            for (final line in [
              'This helps find better matches',
              'You can change it anytime',
              'Only shown to potential matches',
            ])
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.verified_user_outlined,
                      size: 18,
                      color: AppColors.forest,
                    ),
                    const SizedBox(width: 11),
                    Expanded(child: Text(line, style: AppTypography.bodySmall)),
                  ],
                ),
              ),
          ],
        ),
      ),
    ],
  );

  Widget _locationSection() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _searchBox(hint: 'Search your city'),
      _choiceTile(
        'Use my current location',
        icon: Icons.my_location_rounded,
        selected: _values['location'] == 'Current location',
        onTap: () => _choose('location', 'Current location'),
      ),
      const SizedBox(height: 8),
      _sectionLabel('Nearby cities'),
      _optionList(
        'location',
        ProfileBasicsOptions.locations,
        icon: Icons.location_on_outlined,
      ),
    ],
  );

  Widget _educationSection() => Column(
    children: [
      for (final item in ProfileBasicsOptions.education)
        _choiceTile(
          item,
          keyName: 'education',
          icon: Icons.school_outlined,
          selected: _values['education'] == item,
        ),
    ],
  );

  Widget _fieldSection() => Column(
    children: [
      _searchBox(hint: 'Search field (e.g. Computer Science)'),
      _optionList('fieldOfStudy', ProfileBasicsOptions.fieldsOfStudy),
    ],
  );

  Widget _jobSection() => Column(
    children: [
      _searchBox(hint: 'Search job title (e.g. Software Engineer)'),
      _optionList('jobTitle', ProfileBasicsOptions.jobTitles),
    ],
  );

  Widget _companySection() => Column(
    children: [
      _searchBox(hint: 'Search company (e.g. Google)'),
      _optionList('company', ProfileBasicsOptions.companies),
    ],
  );

  Widget _heightSection() => Column(
    children: [
      const SizedBox(height: 4),
      SegmentedButton<bool>(
        segments: const [
          ButtonSegment(value: false, label: Text('cm')),
          ButtonSegment(value: true, label: Text('ft')),
        ],
        selected: {_usingFeet},
        onSelectionChanged: (selected) =>
            _change(() => _usingFeet = selected.first),
      ),
      const SizedBox(height: 36),
      Text(
        _heightLabel(),
        style: AppTypography.h1.copyWith(color: AppColors.coralPressed),
      ),
      Slider(
        value: _heightCm.toDouble(),
        min: 120,
        max: 220,
        divisions: 100,
        activeColor: AppColors.coral,
        onChanged: (value) => _change(() {
          _heightCm = value.round();
          _heightTouched = true;
        }),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '120 cm',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            '220 cm',
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
      const SizedBox(height: 24),
      Text(
        'Drag to choose your height',
        style: AppTypography.body.copyWith(color: AppColors.textSecondary),
      ),
    ],
  );

  Widget _zodiacSection() => Column(
    children: [
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: ProfileBasicsOptions.zodiacSigns.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.sizeOf(context).width < 360 ? 2 : 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          mainAxisExtent: 60 + MediaQuery.textScalerOf(context).scale(40),
        ),
        itemBuilder: (context, index) {
          final sign = ProfileBasicsOptions.zodiacSigns[index];
          final glyphs = [
            '♈',
            '♉',
            '♊',
            '♋',
            '♌',
            '♍',
            '♎',
            '♏',
            '♐',
            '♑',
            '♒',
            '♓',
          ];
          final selected = _values['zodiac'] == sign;
          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _choose('zodiac', sign),
            child: Container(
              decoration:
                  _basicsCardDecoration(
                    color: selected
                        ? const Color(0xFFFFF0EC)
                        : AppColors.surface,
                  ).copyWith(
                    border: Border.all(
                      color: selected ? AppColors.coral : AppColors.border,
                    ),
                  ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    glyphs[index],
                    style: const TextStyle(
                      fontSize: 23,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sign,
                    style: AppTypography.bodySmall.copyWith(
                      color: selected
                          ? AppColors.coralPressed
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      const SizedBox(height: 8),
      _choiceTile(
        'Not sure',
        icon: Icons.help_outline_rounded,
        selected: _values['zodiac'] == 'Not sure',
        onTap: () => _choose('zodiac', 'Not sure'),
      ),
    ],
  );

  Widget _languagesSection() => Container(
    decoration: _basicsCardDecoration(),
    child: Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (
            var index = 0;
            index < ProfileBasicsOptions.languages.length;
            index++
          )
            CheckboxListTile(
              dense: true,
              value: _languages.contains(ProfileBasicsOptions.languages[index]),
              activeColor: AppColors.coral,
              title: Text(
                ProfileBasicsOptions.languages[index],
                style: AppTypography.body,
              ),
              onChanged: (value) => _change(() {
                final language = ProfileBasicsOptions.languages[index];
                value == true
                    ? _languages.add(language)
                    : _languages.remove(language);
                _values['languages'] = _languages.join(', ');
              }),
              secondary: const Icon(
                Icons.translate_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    ),
  );
}
