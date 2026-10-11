import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:dating_app/features/demo_auth/data/demo_session.dart';
import '../../../../core/widgets/distance_slider.dart';
import '../../data/profile_controller.dart';
import '../../models/member_profile.dart';
import '../widgets/profile_widgets.dart';
import 'profile_edit_screen.dart';
import 'profile_privacy_screen.dart';
import 'profile_verification_screen.dart';

class ProfileSettingsScreen extends StatelessWidget {
  const ProfileSettingsScreen({super.key, required this.controller});
  final ProfileController controller;
  Future<void> _preference(
    BuildContext context,
    String key,
    List<Object> choices,
  ) async {
    final current = controller.profile!.onboarding[key];
    final value = await showModalBottomSheet<Object>(
      context: context,
      backgroundColor: profileSurface,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: choices
                .map(
                  (choice) => ListTile(
                    title: Text(
                      choice is int
                          ? '$choice km'
                          : displayValue(choice.toString()),
                      style: const TextStyle(color: profileTextPrimary),
                    ),
                    trailing: current == choice
                        ? const Icon(Icons.check, color: profileAccent)
                        : null,
                    onTap: () => Navigator.pop(context, choice),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
    if (value != null && context.mounted) {
      await profileAction(
        context,
        () => controller.updateOnboarding({key: value}),
      );
    }
  }

  Future<void> _distancePreference(BuildContext context) async {
    final storedValue = controller.profile!.onboarding['preferredDistanceKm'];
    var distance = (storedValue is num ? storedValue.toDouble() : 25.0)
        .clamp(DistanceSlider.minKm, DistanceSlider.maxKm)
        .toDouble();
    final selectedDistance = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: profileSurface,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Preferred distance',
                      style: TextStyle(
                        color: profileTextPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${distance.round()} km',
                      style: const TextStyle(
                        color: profileAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DistanceSlider(
                  value: distance,
                  onChanged: (value) => setSheetState(() => distance = value),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '1 km',
                        style: TextStyle(color: profileTextSecondary),
                      ),
                      Text(
                        '100 km',
                        style: TextStyle(color: profileTextSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () =>
                      Navigator.pop(sheetContext, distance.round()),
                  style: FilledButton.styleFrom(
                    backgroundColor: profileAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Save distance'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (selectedDistance != null && context.mounted) {
      await profileAction(
        context,
        () => controller.updateOnboarding({
          'preferredDistanceKm': selectedDistance,
        }),
      );
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (_, _) => ProfilePage(
      title: 'Settings',
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const ProfileSection('Account'),
          ProfileTile(
            title: 'Edit profile',
            icon: Icons.edit_outlined,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                settings: const RouteSettings(name: '/profile/edit'),
                builder: (_) => ProfileEditScreen(controller: controller),
              ),
            ),
          ),
          ProfileTile(
            title: 'Verification',
            icon: Icons.verified_user_outlined,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) =>
                    ProfileVerificationScreen(controller: controller),
              ),
            ),
          ),
          ProfileTile(
            title: 'Privacy & safety',
            icon: Icons.lock_outline,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => ProfilePrivacyScreen(controller: controller),
              ),
            ),
          ),
          const ProfileSection('Dating preferences'),
          ProfileTile(
            title: 'Show me',
            value: displayValue(
              controller.profile!.onboardingText('interestedIn'),
            ),
            icon: Icons.favorite_outline,
            onTap: () => _preference(context, 'interestedIn', [
              'women',
              'men',
              'everyone',
            ]),
          ),
          ProfileTile(
            title: 'Distance',
            value:
                '${controller.profile!.onboarding['preferredDistanceKm'] ?? 25} km',
            icon: Icons.location_on_outlined,
            onTap: () => _distancePreference(context),
          ),
          const ProfileSection('Support'),
          ProfileTile(
            title: 'Help & support',
            icon: Icons.help_outline,
            onTap: () => showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Need a hand?'),
                content: const Text(
                  'You can update your information, manage photos, and pause discovery from your profile. Verification, blocking, reporting, and account deletion are not available in this version yet.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ),
          ProfileTile(
            title: 'Log out',
            icon: Icons.logout,
            onTap: () async {
              final logout = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Log out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Log out'),
                    ),
                  ],
                ),
              );
              if (logout != true || !context.mounted) return;
              final success = await profileAction(context, () async {
                if (DemoSession.current.value != null) {
                  DemoSession.clear();
                  return;
                }
                await ClerkAuth.of(context, listen: false).signOut();
              });
              if (success && context.mounted) {
                Navigator.popUntil(context, (route) => route.isFirst);
              }
            },
          ),
        ],
      ),
    ),
  );
}
