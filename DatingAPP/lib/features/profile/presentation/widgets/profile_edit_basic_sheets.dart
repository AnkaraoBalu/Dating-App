part of '../screens/profile_edit_screen.dart';

// Editors for basic information, education & work, and bio.
extension _ProfileEditBasicSheets on _ProfileEditScreenState {
  Future<void> _editBasic(BuildContext context, MemberProfile profile) async {
    final name = TextEditingController(text: profile.username);
    final city = TextEditingController(text: profile.text('location'));
    final languages = TextEditingController(
      text: profile.values('languages').join(', '),
    );
    final birthDate = profile.birthDate;
    final birthText = TextEditingController(text: _dateLabel(birthDate));
    final formKey = GlobalKey<FormState>();
    var gender = profile.onboardingText('genderIdentity');
    var selectedBirth = birthDate;
    try {
      await _showEditor(
        context,
        title: 'Basic information',
        fields: Form(
          key: formKey,
          child: StatefulBuilder(
            builder: (context, setSheetState) => Column(
              children: [
                TextFormField(
                  controller: name,
                  maxLength: 80,
                  decoration: const InputDecoration(labelText: 'Your name'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter your name.'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: birthText,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Date of birth',
                    suffixIcon: Icon(Icons.calendar_month_outlined),
                  ),
                  onTap: () async {
                    final now = DateTime.now();
                    final latest = DateTime(now.year - 18, now.month, now.day);
                    final initial =
                        selectedBirth == null || selectedBirth!.isAfter(latest)
                        ? latest
                        : selectedBirth!;
                    final value = await showDatePicker(
                      context: context,
                      initialDate: initial,
                      firstDate: DateTime(1900),
                      lastDate: latest,
                    );
                    if (value != null) {
                      setSheetState(() {
                        selectedBirth = value;
                        birthText.text = _dateLabel(value);
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                _dropdownField(
                  label: 'Gender',
                  value: gender.isEmpty ? null : gender,
                  items: OnboardingQuestionOptions.genders
                      .map((option) => (option.$1, option.$2))
                      .toList(),
                  onChanged: (value) =>
                      setSheetState(() => gender = value ?? ''),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: city,
                  maxLength: 120,
                  decoration: const InputDecoration(labelText: 'City'),
                ),
                TextFormField(
                  controller: languages,
                  decoration: const InputDecoration(
                    labelText: 'Languages',
                    helperText: 'Separate languages with commas',
                  ),
                ),
              ],
            ),
          ),
        ),
        onSave: (sheetContext) async {
          if (!formKey.currentState!.validate()) return false;
          final now = DateTime.now();
          if (selectedBirth == null ||
              selectedBirth!.isAfter(
                DateTime(now.year - 18, now.month, now.day),
              )) {
            profileNotice(sheetContext, 'You must be at least 18 years old.');
            return false;
          }
          if (gender.isEmpty) {
            profileNotice(sheetContext, 'Choose your gender.');
            return false;
          }
          final languageList = languages.text
              .split(',')
              .map((value) => value.trim())
              .where((value) => value.isNotEmpty)
              .toSet()
              .toList();
          if (languageList.length > 10 ||
              languageList.any((value) => value.length > 40)) {
            profileNotice(
              sheetContext,
              'Choose up to 10 languages, each under 40 characters.',
            );
            return false;
          }
          return profileAction(sheetContext, () async {
            if (name.text.trim() != profile.username) {
              await _controller.updateName(name.text.trim());
            }
            await _controller.update({
              'location': city.text.trim(),
              'languages': languageList,
            });
            await _controller.updateOnboarding({
              'genderIdentity': gender,
              'birthDate': selectedBirth!.toIso8601String().split('T').first,
            });
          });
        },
      );
    } finally {
      name.dispose();
      city.dispose();
      languages.dispose();
      birthText.dispose();
    }
  }

  Future<void> _editWork(BuildContext context, MemberProfile profile) async {
    const fields = {
      'education': 'Education',
      'fieldOfStudy': 'Field of study',
      'jobTitle': 'Job title',
      'company': 'Company',
      'industry': 'Industry',
    };
    final controllers = fields.map(
      (key, _) => MapEntry(key, TextEditingController(text: profile.text(key))),
    );
    try {
      await _showEditor(
        context,
        title: 'Education & work',
        fields: Column(
          children: [
            for (final field in fields.entries) ...[
              TextField(
                controller: controllers[field.key],
                maxLength: 120,
                decoration: InputDecoration(labelText: field.value),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
        onSave: (sheetContext) => profileAction(
          sheetContext,
          () => _controller.update(
            controllers.map((key, value) => MapEntry(key, value.text.trim())),
          ),
        ),
      );
    } finally {
      for (final controller in controllers.values) {
        controller.dispose();
      }
    }
  }

  Future<void> _editBio(BuildContext context, MemberProfile profile) async {
    final bio = TextEditingController(text: profile.text('bio'));
    try {
      await _showEditor(
        context,
        title: 'About me',
        fields: TextField(
          controller: bio,
          maxLength: 200,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'What do you enjoy? What would you like people to know?',
          ),
        ),
        onSave: (sheetContext) => profileAction(
          sheetContext,
          () => _controller.update({'bio': bio.text.trim()}),
        ),
      );
    } finally {
      bio.dispose();
    }
  }
}
