part of '../screens/profile_edit_screen.dart';

// Editor for lifestyle and relationship details.
extension _ProfileEditMoreSheet on _ProfileEditScreenState {
  Future<void> _editMore(BuildContext context, MemberProfile profile) async {
    final height = TextEditingController(text: profile.text('heightCm'));
    final zodiac = TextEditingController(text: profile.text('zodiac'));
    final religion = TextEditingController(text: profile.text('religion'));
    final formKey = GlobalKey<FormState>();
    var smoking = profile.text('smoking');
    var drinking = profile.text('drinking');
    var diet = profile.text('diet');
    final intentions = profile
        .values('datingIntentions', fromOnboarding: true)
        .toSet();
    const smokingOptions = [
      ('no', 'No'),
      ('sometimes', 'Sometimes'),
      ('yes', 'Yes'),
      ('prefer_not_to_say', 'Prefer not to say'),
    ];
    const drinkingOptions = [
      ('never', 'Never'),
      ('socially', 'Socially'),
      ('regularly', 'Regularly'),
      ('prefer_not_to_say', 'Prefer not to say'),
    ];
    const dietOptions = [
      ('vegetarian', 'Vegetarian'),
      ('vegan', 'Vegan'),
      ('non_vegetarian', 'Non-vegetarian'),
      ('pescatarian', 'Pescatarian'),
      ('other', 'Other'),
    ];
    try {
      await _showEditor(
        context,
        title: 'More about you',
        fields: Form(
          key: formKey,
          child: StatefulBuilder(
            builder: (context, setSheetState) => Column(
              children: [
                TextFormField(
                  controller: height,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Height (cm)'),
                  validator: (value) {
                    if (value == null || value.isEmpty) return null;
                    final parsed = int.tryParse(value);
                    return parsed == null || parsed < 90 || parsed > 250
                        ? 'Enter a height between 90 and 250 cm.'
                        : null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: zodiac,
                  maxLength: 40,
                  decoration: const InputDecoration(labelText: 'Zodiac'),
                ),
                TextFormField(
                  controller: religion,
                  maxLength: 80,
                  decoration: const InputDecoration(labelText: 'Religion'),
                ),
                const SizedBox(height: 8),
                _dropdownField(
                  label: 'Smoking',
                  value: smoking.isEmpty ? null : smoking,
                  items: smokingOptions,
                  onChanged: (value) =>
                      setSheetState(() => smoking = value ?? ''),
                ),
                const SizedBox(height: 12),
                _dropdownField(
                  label: 'Drinking',
                  value: drinking.isEmpty ? null : drinking,
                  items: drinkingOptions,
                  onChanged: (value) =>
                      setSheetState(() => drinking = value ?? ''),
                ),
                const SizedBox(height: 12),
                _dropdownField(
                  label: 'Diet',
                  value: diet.isEmpty ? null : diet,
                  items: dietOptions,
                  onChanged: (value) => setSheetState(() => diet = value ?? ''),
                ),
                const SizedBox(height: 18),
                _editorLabel('Relationship goals'),
                Wrap(
                  spacing: 7,
                  runSpacing: 3,
                  children: [
                    for (final option in OnboardingQuestionOptions.intentions)
                      FilterChip(
                        label: Text(option.$2),
                        selected: intentions.contains(option.$1),
                        selectedColor: profileAccent,
                        backgroundColor: profileBackground,
                        labelStyle: TextStyle(
                          color: intentions.contains(option.$1)
                              ? profileTextPrimary
                              : profileTextSecondary,
                        ),
                        onSelected: (selected) => setSheetState(() {
                          if (selected) {
                            intentions.add(option.$1);
                          } else {
                            intentions.remove(option.$1);
                          }
                        }),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        onSave: (sheetContext) {
          if (!formKey.currentState!.validate()) return Future.value(false);
          return profileAction(sheetContext, () async {
            await _controller.update({
              'heightCm': int.tryParse(height.text),
              'zodiac': zodiac.text.trim(),
              'religion': religion.text.trim(),
              'smoking': smoking.isEmpty ? null : smoking,
              'drinking': drinking.isEmpty ? null : drinking,
              'diet': diet.isEmpty ? null : diet,
            });
            await _controller.updateOnboarding({
              'datingIntentions': intentions.toList(),
            });
          });
        },
      );
    } finally {
      height.dispose();
      zodiac.dispose();
      religion.dispose();
    }
  }
}
