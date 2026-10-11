import 'package:flutter/material.dart';
import '../../../onboarding/data/onboarding_question_options.dart';
import '../../data/profile_controller.dart';
import '../../models/member_profile.dart';
import '../widgets/profile_widgets.dart';
import 'profile_more_details_screen.dart';

class ProfileInterestsScreen extends StatefulWidget {
  const ProfileInterestsScreen({super.key, required this.controller});
  final ProfileController controller;
  @override
  State<ProfileInterestsScreen> createState() => _ProfileInterestsScreenState();
}

class _ProfileInterestsScreenState extends State<ProfileInterestsScreen> {
  static final _choices = OnboardingQuestionOptions.interests
      .map((o) => o.$1)
      .toList();
  late final Set<String> _selected;
  late final Set<String> _genres, _artists, _dealbreakers;
  String? _vibe, _friday, _era;
  @override
  void initState() {
    super.initState();
    _selected = widget.controller.profile!.interests.toSet();
    final p = widget.controller.profile!;
    _genres = p.values('musicGenres', fromOnboarding: true).toSet();
    _artists = p.values('favoriteArtists', fromOnboarding: true).toSet();
    _dealbreakers = p.values('dealbreakers', fromOnboarding: true).toSet();
    _vibe = p.onboarding['vibeType'] as String?;
    _friday = p.onboarding['idealFriday'] as String?;
    _era = p.onboarding['currentEra'] as String?;
  }

  Future<void> _save() async {
    await widget.controller.updateOnboarding({
      'interests': _selected.toList(),
      'vibeType': _vibe,
      'idealFriday': _friday,
      'currentEra': _era,
      'musicGenres': _genres.toList(),
      'favoriteArtists': _artists.toList(),
      'dealbreakers': _dealbreakers.toList(),
    });
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ProfileMoreDetailsScreen(controller: widget.controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ProfilePage(
    title: 'Edit Profile',
    step: 4,
    bottom: ProfileSaveButton(controller: widget.controller, onSave: _save),
    child: ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        ProfileSection(
          'Interests',
          subtitle: 'Select up to 5 things you’re into · ${_selected.length}/5',
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _choices
              .map(
                (value) => FilterChip(
                  label: Text(displayValue(value)),
                  selected: _selected.contains(value),
                  selectedColor: profileAccentSoft,
                  backgroundColor: profileSurface,
                  labelStyle: TextStyle(
                    color: _selected.contains(value)
                        ? profileTextPrimary
                        : profileTextSecondary,
                  ),
                  onSelected: (selected) {
                    if (selected && _selected.length >= 5) {
                      profileNotice(context, 'Choose up to 5 interests.');
                      return;
                    }
                    setState(
                      () => selected
                          ? _selected.add(value)
                          : _selected.remove(value),
                    );
                  },
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 24),
        const ProfileSection('Lifestyle & energy'),
        _choice('My vibe', _vibe, [
          for (final o in OnboardingQuestionOptions.vibes) (o.$1, o.$2),
        ], (v) => _vibe = v),
        _choice('My ideal Friday', _friday, [
          for (final o in OnboardingQuestionOptions.idealFridays) (o.$1, o.$2),
        ], (v) => _friday = v),
        _choice('My current era', _era, [
          for (final o in OnboardingQuestionOptions.currentEras) (o.$1, o.$2),
        ], (v) => _era = v),
        ExpansionTile(
          title: const Text('Music & artists'),
          subtitle: Text('${_genres.length + _artists.length}/5 selected'),
          children: [
            Wrap(
              spacing: 8,
              children: [
                for (final genre in OnboardingQuestionOptions.musicGenres)
                  FilterChip(
                    label: Text(genre.$2),
                    selected: _genres.contains(genre.$1),
                    onSelected: (selected) =>
                        _music(genre.$1, selected, artist: false),
                  ),
              ],
            ),
            const ProfileSection('Favorite artists'),
            Wrap(
              spacing: 8,
              children: [
                for (final artist in OnboardingQuestionOptions.favoriteArtists)
                  FilterChip(
                    label: Text(artist),
                    selected: _artists.contains(artist),
                    onSelected: (selected) =>
                        _music(artist, selected, artist: true),
                  ),
              ],
            ),
          ],
        ),
        ExpansionTile(
          title: const Text('What matters to me'),
          subtitle: Text('${_dealbreakers.length}/8 selected'),
          children: [
            Wrap(
              spacing: 8,
              children: [
                for (final item in OnboardingQuestionOptions.dealbreakers)
                  FilterChip(
                    label: Text(item.$2),
                    selected: _dealbreakers.contains(item.$1),
                    onSelected: (selected) {
                      if (selected &&
                          item.$1 != 'no_hard_dealbreakers' &&
                          _dealbreakers.length >= 8) {
                        profileNotice(context, 'Choose up to 8 values.');
                        return;
                      }
                      setState(() {
                        if (!selected) {
                          _dealbreakers.remove(item.$1);
                        } else if (item.$1 == 'no_hard_dealbreakers') {
                          _dealbreakers
                            ..clear()
                            ..add(item.$1);
                        } else {
                          _dealbreakers
                            ..remove('no_hard_dealbreakers')
                            ..add(item.$1);
                        }
                      });
                    },
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    ),
  );
  Widget _choice(
    String title,
    String? value,
    List<(String, String)> options,
    ValueChanged<String?> changed,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      dropdownColor: profileSurface,
      style: const TextStyle(color: profileTextPrimary, fontSize: 15),
      iconEnabledColor: profileTextSecondary,
      decoration: InputDecoration(labelText: title),
      items: [
        const DropdownMenuItem<String>(
          value: '',
          child: Text(
            'Not added',
            style: TextStyle(color: profileTextSecondary),
          ),
        ),
        for (final o in options)
          DropdownMenuItem(
            value: o.$1,
            child: Text(
              o.$2,
              style: const TextStyle(color: profileTextPrimary),
            ),
          ),
      ],
      onChanged: (v) => changed(v == '' ? null : v),
    ),
  );
  void _music(String value, bool selected, {required bool artist}) {
    const general = ['a_bit_of_everything', 'not_big_on_music'];
    final set = artist ? _artists : _genres;
    if (!selected) {
      setState(() => set.remove(value));
      return;
    }
    if (!artist && general.contains(value)) {
      setState(() {
        _genres
          ..clear()
          ..add(value);
        _artists.clear();
      });
      return;
    }
    if (_genres.length + _artists.length >= 5) {
      profileNotice(context, 'Choose up to 5 artists and genres combined.');
      return;
    }
    setState(() {
      _genres.removeAll(general);
      set.add(value);
    });
  }
}
