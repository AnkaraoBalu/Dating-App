import 'package:flutter/material.dart';

import '../../../onboarding/data/onboarding_question_options.dart';
import '../../data/profile_controller.dart';
import '../../models/member_profile.dart';
import '../widgets/profile_widgets.dart';
import 'profile_photo_gallery_screen.dart';

part '../widgets/profile_edit_basic_sheets.dart';
part '../widgets/profile_edit_more_sheet.dart';
part '../widgets/profile_edit_prompts_interests_sheets.dart';
part '../widgets/profile_edit_sheet.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key, required this.controller});

  final ProfileController controller;

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  ProfileController get _controller => widget.controller;

  @override
  Widget build(BuildContext context) => ProfilePage(
    title: 'Edit Profile',
    child: AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final profile = _controller.profile;
        if (profile == null) {
          return const Center(child: Text('Your profile is unavailable.'));
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 14),
              child: Text(
                'Choose a section to update. Your changes save individually.',
                style: TextStyle(color: profileTextSecondary, height: 1.45),
              ),
            ),
            _section(
              title: 'Photos',
              subtitle: '${profile.photos.length} of 6 photos',
              icon: Icons.photo_library_outlined,
              onEdit: () => Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) =>
                      ProfilePhotoGalleryScreen(controller: _controller),
                ),
              ),
            ),
            _section(
              title: 'Basic information',
              subtitle: _summary([
                profile.name,
                profile.age == null ? '' : '${profile.age} years old',
                displayValue(profile.onboardingText('genderIdentity')),
                profile.text('location'),
                profile.values('languages').join(', '),
              ]),
              icon: Icons.person_outline_rounded,
              onEdit: () => _editBasic(context, profile),
            ),
            _section(
              title: 'Education & work',
              subtitle: _summary([
                profile.text('education'),
                profile.text('fieldOfStudy'),
                profile.text('jobTitle'),
                profile.text('company'),
                profile.text('industry'),
              ]),
              icon: Icons.work_outline_rounded,
              onEdit: () => _editWork(context, profile),
            ),
            _section(
              title: 'About me',
              subtitle: profile.text('bio'),
              icon: Icons.notes_rounded,
              onEdit: () => _editBio(context, profile),
            ),
            _section(
              title: 'Prompts',
              subtitle: profile.prompts.isEmpty
                  ? 'Add answers to start conversations'
                  : '${profile.prompts.length} conversation prompts',
              icon: Icons.chat_bubble_outline_rounded,
              onEdit: () => _editPrompts(context, profile),
            ),
            _section(
              title: 'Interests & lifestyle',
              subtitle: _summary(
                profile.interests.map(displayValue).toList()..addAll([
                  ...profile.lifestyleChoices('vibeTypes').map(displayValue),
                  ...profile.lifestyleChoices('idealFridays').map(displayValue),
                  ...profile.lifestyleChoices('currentEras').map(displayValue),
                  ...profile
                      .values('musicGenres', fromOnboarding: true)
                      .map(displayValue),
                  ...profile.values('favoriteArtists', fromOnboarding: true),
                ]),
              ),
              icon: Icons.auto_awesome_outlined,
              onEdit: () => _editInterests(context, profile),
            ),
            _section(
              title: 'More about you',
              subtitle: _summary([
                profile.text('heightCm').isEmpty
                    ? ''
                    : '${profile.text('heightCm')} cm',
                profile.text('zodiac'),
                displayValue(profile.text('smoking')),
                displayValue(profile.text('drinking')),
                displayValue(profile.text('diet')),
                profile.text('religion'),
                ...profile
                    .values('datingIntentions', fromOnboarding: true)
                    .map(displayValue),
              ]),
              icon: Icons.tune_rounded,
              onEdit: () => _editMore(context, profile),
            ),
          ],
        );
      },
    ),
  );

  Widget _section({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onEdit,
  }) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: profileSurface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: profileBorder),
    ),
    child: ListTile(
      contentPadding: const EdgeInsets.fromLTRB(16, 8, 10, 8),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: profileAccent.withValues(alpha: .13),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, color: profileAccent, size: 21),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: profileTextPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Text(
          subtitle.isEmpty ? 'Not added yet' : subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: profileTextSecondary, height: 1.35),
        ),
      ),
      trailing: IconButton.filledTonal(
        tooltip: 'Edit $title',
        onPressed: onEdit,
        style: IconButton.styleFrom(
          backgroundColor: profileAccentSoft,
          foregroundColor: profileAccent,
        ),
        icon: const Icon(Icons.edit_outlined, size: 19),
      ),
    ),
  );

  String _summary(Iterable<String> values) => values
      .where((value) => value.trim().isNotEmpty && value != 'Not added')
      .join(' · ');

  Future<void> _showEditor(
    BuildContext context, {
    required String title,
    required Widget fields,
    required Future<bool> Function(BuildContext sheetContext) onSave,
  }) async {
    final navigator = Navigator.of(context);
    final route = ModalBottomSheetRoute<void>(
      capturedThemes: InheritedTheme.capture(
        from: context,
        to: navigator.context,
      ),
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: profileSurface,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .86,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) => _ProfileEditSheet(
        title: title,
        fields: fields,
        onSave: () => onSave(sheetContext),
      ),
    );
    navigator.push(route);
    // Callers dispose their field controllers afterwards, so wait for the
    // exit animation rather than the pop, while the sheet still builds them.
    await route.completed;
  }

  String _dateLabel(DateTime? date) =>
      date == null ? '' : '${date.day}/${date.month}/${date.year}';
}
