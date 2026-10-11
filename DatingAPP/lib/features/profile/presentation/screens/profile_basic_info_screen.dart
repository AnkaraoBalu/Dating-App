import 'package:flutter/material.dart';
import '../../data/profile_controller.dart';
import '../../models/member_profile.dart';
import '../widgets/profile_widgets.dart';
import 'profile_education_work_screen.dart';

class ProfileBasicInfoScreen extends StatefulWidget {
  const ProfileBasicInfoScreen({super.key, required this.controller});
  final ProfileController controller;
  @override
  State<ProfileBasicInfoScreen> createState() => _ProfileBasicInfoScreenState();
}

class _ProfileBasicInfoScreenState extends State<ProfileBasicInfoScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name, _location, _languages;
  late String _gender;
  DateTime? _birth;
  @override
  void initState() {
    super.initState();
    final p = widget.controller.profile!;
    _name = TextEditingController(text: p.username);
    _location = TextEditingController(text: p.text('location'));
    _languages = TextEditingController(text: p.values('languages').join(', '));
    _gender = p.onboardingText('genderIdentity');
    _birth = p.birthDate;
  }

  @override
  void dispose() {
    for (final c in [_name, _location, _languages]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final p = widget.controller.profile!;
    final now = DateTime.now();
    if (_birth == null ||
        _birth!.isAfter(DateTime(now.year - 18, now.month, now.day))) {
      profileNotice(context, 'You must be at least 18 years old.');
      return;
    }
    final languages = _languages.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
    if (languages.length > 10 || languages.any((s) => s.length > 40)) {
      profileNotice(
        context,
        'Choose up to 10 languages, each under 40 characters.',
      );
      return;
    }
    if (_name.text.trim() != p.username) {
      await widget.controller.updateName(_name.text.trim());
    }
    await widget.controller.update({
      'location': _location.text.trim(),
      'languages': languages,
    });
    await widget.controller.updateOnboarding({
      'genderIdentity': _gender,
      'birthDate': _birth!.toIso8601String().split('T').first,
    });
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) =>
            ProfileEducationWorkScreen(controller: widget.controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ProfilePage(
    title: 'Edit Profile',
    step: 1,
    bottom: ProfileSaveButton(controller: widget.controller, onSave: _save),
    child: Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          const ProfileSection('Basic Information'),
          TextFormField(
            controller: _name,
            maxLength: 80,
            decoration: const InputDecoration(
              labelText: 'Your name',
              hintText: 'Enter your name',
            ),
            validator: (s) =>
                s == null || s.trim().isEmpty ? 'Enter your name' : null,
          ),
          ProfileTile(
            title: 'Date of birth',
            value: _birth == null
                ? ''
                : '${_birth!.day}/${_birth!.month}/${_birth!.year}',
            icon: Icons.cake_outlined,
            onTap: () async {
              final now = DateTime.now();
              final latest = DateTime(now.year - 18, now.month, now.day);
              final birth = await showDatePicker(
                context: context,
                initialDate: _birth == null || _birth!.isAfter(latest)
                    ? latest
                    : _birth!,
                firstDate: DateTime(1900),
                lastDate: latest,
              );
              if (birth != null && mounted) setState(() => _birth = birth);
            },
          ),
          DropdownButtonFormField<String>(
            isExpanded: true,
            dropdownColor: profileSurface,
            style: const TextStyle(color: profileTextPrimary, fontSize: 15),
            iconEnabledColor: profileTextSecondary,
            initialValue: _gender.isEmpty ? null : _gender,
            decoration: const InputDecoration(labelText: 'Gender'),
            items: ['man', 'woman', 'non_binary', 'prefer_not_to_say']
                .map(
                  (s) => DropdownMenuItem(
                    value: s,
                    child: Text(
                      displayValue(s),
                      style: const TextStyle(color: profileTextPrimary),
                    ),
                  ),
                )
                .toList(),
            onChanged: (s) => _gender = s!,
            validator: (s) => s == null ? 'Choose your gender' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _location,
            maxLength: 120,
            decoration: const InputDecoration(labelText: 'City'),
          ),
          TextFormField(
            controller: _languages,
            decoration: const InputDecoration(
              labelText: 'Languages',
              helperText: 'Separate languages with commas',
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    ),
  );
}
