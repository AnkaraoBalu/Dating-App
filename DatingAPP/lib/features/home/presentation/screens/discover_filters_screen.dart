import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/distance_slider.dart';

class DiscoverFilterOptions {
  const DiscoverFilterOptions({
    this.minAge = 21,
    this.maxAge = 34,
    this.radiusKm = 25,
    this.gender = 'everyone',
    this.interest,
    this.interests = const [],
    this.onlineOnly = false,
    this.verifiedOnly = false,
  });

  final int minAge;
  final int maxAge;
  final int radiusKm;
  final String gender;
  final String? interest;
  final List<String> interests;
  final bool onlineOnly;
  final bool verifiedOnly;
}

class DiscoverFiltersScreen extends StatefulWidget {
  const DiscoverFiltersScreen({
    super.key,
    this.initial = const DiscoverFilterOptions(),
  });

  final DiscoverFilterOptions initial;

  @override
  State<DiscoverFiltersScreen> createState() => _DiscoverFiltersScreenState();
}

class _DiscoverFiltersScreenState extends State<DiscoverFiltersScreen> {
  late RangeValues _ages;
  late double _distance;
  late String _gender;
  late bool _online;
  late bool _verified;
  final Set<String> _interests = {};
  static const _choices = [
    'Coffee',
    'Travel',
    'Music',
    'Movies',
    'Food',
    'Gym',
    'Nature',
    'Art',
  ];

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _ages = RangeValues(initial.minAge.toDouble(), initial.maxAge.toDouble());
    _distance = initial.radiusKm.toDouble();
    _gender = switch (initial.gender) {
      'man' => 'Men',
      'woman' => 'Women',
      _ => 'Everyone',
    };
    _online = initial.onlineOnly;
    _verified = initial.verifiedOnly;
    final interest = initial.interest;
    if (interest != null) {
      _interests.add(switch (interest) {
        'fitness' => 'Gym',
        'movies_and_tv' => 'Movies',
        _ => interest[0].toUpperCase() + interest.substring(1),
      });
    }
    _interests.addAll(initial.interests.map(_interestLabel));
  }

  static String _interestLabel(String interest) => switch (interest) {
    'fitness' => 'Gym',
    'movies_and_tv' => 'Movies',
    _ =>
      interest.isEmpty
          ? interest
          : interest[0].toUpperCase() + interest.substring(1),
  };

  static String _interestValue(String interest) => switch (interest) {
    'Gym' => 'fitness',
    'Movies' => 'movies_and_tv',
    _ => interest.toLowerCase(),
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      title: Text(
        'Filters',
        style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
      ),
      actions: [
        TextButton(
          onPressed: () => setState(() {
            _ages = const RangeValues(21, 34);
            _distance = 25;
            _gender = 'Everyone';
            _interests.clear();
            _online = false;
            _verified = false;
          }),
          child: Text(
            'Reset',
            style: AppTypography.label.copyWith(color: AppColors.coral),
          ),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      children: [
        _label('Location', '${_distance.round()} km'),
        DistanceSlider(
          value: _distance,
          onChanged: (value) => setState(() => _distance = value),
        ),
        const SizedBox(height: 12),
        _label('Age range', '${_ages.start.round()} – ${_ages.end.round()}'),
        RangeSlider(
          values: _ages,
          min: 18,
          max: 70,
          divisions: 52,
          activeColor: AppColors.coral,
          onChanged: (value) => setState(() => _ages = value),
        ),
        const SizedBox(height: 12),
        _label('Show me', ''),
        Wrap(
          spacing: 8,
          children: ['Men', 'Women', 'Everyone']
              .map(
                (value) => ChoiceChip(
                  label: Text(value),
                  selected: _gender == value,
                  onSelected: (_) => setState(() => _gender = value),
                  selectedColor: AppColors.coral,
                  backgroundColor: AppColors.surfaceSecondary,
                  labelStyle: AppTypography.caption.copyWith(
                    color: _gender == value
                        ? Colors.white
                        : AppColors.textPrimary,
                  ),
                  side: const BorderSide(color: AppColors.border),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 20),
        _label('Interests', 'Choose a few'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _choices
              .map(
                (value) => FilterChip(
                  label: Text(value),
                  selected: _interests.contains(value),
                  onSelected: (selected) => setState(
                    () => selected
                        ? _interests.add(value)
                        : _interests.remove(value),
                  ),
                  selectedColor: AppColors.coralPressed,
                  backgroundColor: AppColors.surfaceSecondary,
                  labelStyle: AppTypography.caption.copyWith(
                    color: _interests.contains(value)
                        ? Colors.white
                        : AppColors.textPrimary,
                  ),
                  side: const BorderSide(color: AppColors.border),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 14),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Online now',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          value: _online,
          activeTrackColor: AppColors.coral,
          onChanged: (value) => setState(() => _online = value),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Verified profiles only',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          value: _verified,
          activeTrackColor: AppColors.coral,
          onChanged: (value) => setState(() => _verified = value),
        ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            DiscoverFilterOptions(
              minAge: _ages.start.round(),
              maxAge: _ages.end.round(),
              radiusKm: _distance.round(),
              gender: switch (_gender) {
                'Men' => 'man',
                'Women' => 'woman',
                _ => 'everyone',
              },
              interests: _interests.map(_interestValue).toList(),
              onlineOnly: _online,
              verifiedOnly: _verified,
            ),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.coral,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
          ),
          child: const Text('Show results'),
        ),
      ],
    ),
  );

  Widget _label(String title, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 5),
    child: Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: AppTypography.label.copyWith(color: AppColors.textPrimary),
          ),
        ),
        Text(
          value,
          style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
        ),
      ],
    ),
  );
}
