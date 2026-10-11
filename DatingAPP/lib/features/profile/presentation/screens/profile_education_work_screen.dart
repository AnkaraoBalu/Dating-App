import 'package:flutter/material.dart';
import '../../data/profile_controller.dart';
import '../widgets/profile_widgets.dart';
import 'profile_about_me_screen.dart';

class ProfileEducationWorkScreen extends StatefulWidget {
  const ProfileEducationWorkScreen({super.key, required this.controller});
  final ProfileController controller;
  @override
  State<ProfileEducationWorkScreen> createState() =>
      _ProfileEducationWorkScreenState();
}

class _ProfileEducationWorkScreenState
    extends State<ProfileEducationWorkScreen> {
  static const _fields = {
    'education': 'Education',
    'fieldOfStudy': 'Field of study',
    'jobTitle': 'Job title',
    'company': 'Company',
    'industry': 'Industry',
  };
  late final Map<String, TextEditingController> _controllers;
  @override
  void initState() {
    super.initState();
    _controllers = _fields.map(
      (key, _) => MapEntry(
        key,
        TextEditingController(text: widget.controller.profile!.text(key)),
      ),
    );
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    await widget.controller.update(
      _controllers.map((k, c) => MapEntry(k, c.text.trim())),
    );
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ProfileAboutMeScreen(controller: widget.controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ProfilePage(
    title: 'Edit Profile',
    step: 2,
    bottom: ProfileSaveButton(controller: widget.controller, onSave: _save),
    child: ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        const ProfileSection(
          'Education & Work',
          subtitle: 'A little about what you do',
        ),
        for (final field in _fields.entries)
          TextField(
            controller: _controllers[field.key],
            maxLength: 120,
            decoration: InputDecoration(labelText: field.value),
          ),
      ],
    ),
  );
}
