import 'package:flutter/material.dart';
import '../../data/profile_controller.dart';
import '../../models/member_profile.dart';
import '../widgets/profile_widgets.dart';
import 'profile_preview_screen.dart';

class ProfileMoreDetailsScreen extends StatefulWidget {
  const ProfileMoreDetailsScreen({super.key, required this.controller});
  final ProfileController controller;
  @override
  State<ProfileMoreDetailsScreen> createState() =>
      _ProfileMoreDetailsScreenState();
}

class _ProfileMoreDetailsScreenState extends State<ProfileMoreDetailsScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _height, _zodiac, _religion;
  late String? _smoking, _drinking, _diet;
  late final Set<String> _intentions;
  @override
  void initState() {
    super.initState();
    final p = widget.controller.profile!;
    _height = TextEditingController(text: p.text('heightCm'));
    _zodiac = TextEditingController(text: p.text('zodiac'));
    _religion = TextEditingController(text: p.text('religion'));
    _smoking = p.text('smoking').isEmpty ? null : p.text('smoking');
    _drinking = p.text('drinking').isEmpty ? null : p.text('drinking');
    _diet = p.text('diet').isEmpty ? null : p.text('diet');
    _intentions = p.values('datingIntentions', fromOnboarding: true).toSet();
  }

  @override
  void dispose() {
    _height.dispose();
    _zodiac.dispose();
    _religion.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    await widget.controller.update({
      'heightCm': int.tryParse(_height.text),
      'zodiac': _zodiac.text.trim(),
      'religion': _religion.text.trim(),
      'smoking': _smoking,
      'drinking': _drinking,
      'diet': _diet,
    });
    await widget.controller.updateOnboarding({
      'datingIntentions': _intentions.toList(),
    });
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ProfilePreviewScreen(
          controller: widget.controller,
          afterEdit: true,
        ),
      ),
    );
  }

  Widget _choice(
    String title,
    String? value,
    List<String> options,
    ValueChanged<String?> changed,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: DropdownButtonFormField<String>(
      isExpanded: true,
      dropdownColor: profileSurface,
      style: const TextStyle(color: profileTextPrimary, fontSize: 15),
      iconEnabledColor: profileTextSecondary,
      initialValue: value,
      decoration: InputDecoration(labelText: title),
      items: [
        const DropdownMenuItem<String>(
          value: '',
          child: Text(
            'Not added',
            style: TextStyle(color: profileTextSecondary),
          ),
        ),
        ...options.map(
          (s) => DropdownMenuItem(
            value: s,
            child: Text(
              displayValue(s),
              style: const TextStyle(color: profileTextPrimary),
            ),
          ),
        ),
      ],
      onChanged: (s) => changed(s == '' ? null : s),
    ),
  );
  @override
  Widget build(BuildContext context) => ProfilePage(
    title: 'Edit Profile',
    step: 5,
    bottom: ProfileSaveButton(
      controller: widget.controller,
      onSave: _save,
      label: 'Save & preview',
    ),
    child: Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          const ProfileSection('More About You'),
          TextFormField(
            controller: _height,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Height (cm)'),
            validator: (s) {
              if (s == null || s.isEmpty) return null;
              final height = int.tryParse(s);
              return height == null || height < 90 || height > 250
                  ? 'Enter a height between 90 and 250 cm.'
                  : null;
            },
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: _zodiac,
            maxLength: 40,
            decoration: const InputDecoration(labelText: 'Zodiac'),
          ),
          const ProfileSection('Relationship goals'),
          Wrap(
            spacing: 8,
            children:
                [
                      'something_serious',
                      'open_to_anything',
                      'casual',
                      'friendship',
                      'not_sure_yet',
                    ]
                    .map(
                      (s) => FilterChip(
                        label: Text(displayValue(s)),
                        selected: _intentions.contains(s),
                        onSelected: (v) => setState(
                          () => v ? _intentions.add(s) : _intentions.remove(s),
                        ),
                      ),
                    )
                    .toList(),
          ),
          const SizedBox(height: 18),
          _choice('Smoking', _smoking, [
            'no',
            'sometimes',
            'yes',
            'prefer_not_to_say',
          ], (s) => _smoking = s),
          _choice('Drinking', _drinking, [
            'never',
            'socially',
            'regularly',
            'prefer_not_to_say',
          ], (s) => _drinking = s),
          _choice('Diet', _diet, [
            'vegetarian',
            'vegan',
            'non_vegetarian',
            'pescatarian',
            'other',
          ], (s) => _diet = s),
          TextFormField(
            controller: _religion,
            maxLength: 80,
            decoration: const InputDecoration(labelText: 'Religion'),
          ),
        ],
      ),
    ),
  );
}
