import 'package:flutter/material.dart';
import '../../data/profile_controller.dart';
import '../widgets/profile_widgets.dart';

class ProfilePrivacyScreen extends StatelessWidget {
  const ProfilePrivacyScreen({super.key, required this.controller});
  final ProfileController controller;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (_, _) {
      final p = controller.profile!;
      return ProfilePage(
        title: 'Privacy & Safety',
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const ProfileSection(
              'You’re in control',
              subtitle: 'Choose what other people can see in Discover',
            ),
            for (final setting in [
              ('showProfile', 'Show my profile', Icons.person_outline),
              ('showDistance', 'Show my distance', Icons.location_on_outlined),
              (
                'showOnlineStatus',
                'Show my online status',
                Icons.circle_outlined,
              ),
            ])
              ProfileTile(
                title: setting.$2,
                icon: setting.$3,
                trailing: Switch(
                  value: p.flag(setting.$1),
                  activeTrackColor: profileAccent,
                  onChanged: controller.saving
                      ? null
                      : (v) => profileAction(
                          context,
                          () => controller.update({setting.$1: v}),
                        ),
                ),
              ),
            const SizedBox(height: 12),
            const Text(
              'Turning off your profile pauses your appearance in discovery. Hiding distance also hides your approximate position on the map. Online status is hidden from the Online view when disabled.',
              style: TextStyle(color: profileTextSecondary, height: 1.6),
            ),
            const ProfileSection('Safety'),
            const Text(
              'Never share passwords, verification codes, or financial information. If someone makes you uncomfortable, stop the conversation. Blocking and reporting tools are not available in this version yet.',
              style: TextStyle(color: profileTextSecondary, height: 1.6),
            ),
          ],
        ),
      );
    },
  );
}
