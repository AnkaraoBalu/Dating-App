import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../widgets/profile_hero.dart';
import '../../data/profile_controller.dart';
import '../../models/member_profile.dart';
import '../widgets/profile_widgets.dart';
import '../widgets/profile_options_sheet.dart';
import 'profile_edit_screen.dart';
import 'profile_insights_screen.dart';
import 'profile_photo_gallery_screen.dart';
import 'profile_preview_screen.dart';
import 'profile_settings_screen.dart';
// Restore with the hidden Verification tile below.
// import 'profile_verification_screen.dart';

class ProfileMainScreen extends StatelessWidget {
  const ProfileMainScreen({super.key, required this.controller});
  final ProfileController? controller;
  @override
  Widget build(BuildContext context) {
    final controller = this.controller;
    if (controller == null) {
      return const Center(
        child: Text(
          'Profile service is unavailable.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    return AnimatedBuilder(
      animation: controller,
      builder: (_, _) {
        final p = controller.profile;
        if (p == null) {
          if (controller.loading) {
            return const Center(
              child: CircularProgressIndicator(color: profileAccent),
            );
          }
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Could not load your profile.',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                TextButton(
                  onPressed: controller.load,
                  child: const Text('Try again'),
                ),
              ],
            ),
          );
        }
        void open(Widget screen) => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => screen),
        );
        return ColoredBox(
          color: profileBackground,
          child: RefreshIndicator(
            onRefresh: controller.load,
            color: profileAccent,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                ProfileHero(
                  profile: p,
                  onOptions: () => showProfileOptions(context, controller),
                  onSettings: () =>
                      open(ProfileSettingsScreen(controller: controller)),
                  onPhotos: () =>
                      open(ProfilePhotoGalleryScreen(controller: controller)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${p.name.isEmpty ? 'Your profile' : p.name}${p.age == null ? '' : ', ${p.age}'}',
                              style: const TextStyle(
                                color: profileTextPrimary,
                                fontSize: 28,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (p.verified)
                            const Icon(
                              Icons.verified,
                              color: Colors.blue,
                              size: 22,
                            ),
                        ],
                      ),
                      if (p.text('education').isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.school_outlined,
                                color: profileTextSecondary,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  [
                                    p.text('education'),
                                    p.text('fieldOfStudy'),
                                  ].where((s) => s.isNotEmpty).join(', '),
                                  style: const TextStyle(
                                    color: profileTextSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (p.text('location').isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 7),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                color: profileTextSecondary,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  p.text('location'),
                                  style: const TextStyle(
                                    color: profileTextSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (!p.flag('showProfile')) ...[
                        const SizedBox(height: 12),
                        const Text(
                          'Your profile is paused in Discover',
                          style: TextStyle(color: profileAccent),
                        ),
                      ],
                      const SizedBox(height: 18),
                      if (p.text('bio').isNotEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: profileSurface,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: profileBorder),
                          ),
                          child: Text(
                            '“${p.text('bio')}”',
                            style: const TextStyle(
                              color: profileTextPrimary,
                              height: 1.5,
                            ),
                          ),
                        ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: p.interests
                            .take(5)
                            .map(
                              (s) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: profileSurface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: profileBorder),
                                ),
                                child: Text(
                                  displayValue(s),
                                  style: const TextStyle(
                                    color: profileTextPrimary,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _stat(
                              controller.insights['matches']?.toString() ?? '—',
                              'Matches',
                              () => open(
                                ProfileInsightsScreen(controller: controller),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _stat(
                              controller.insights['likesReceived']
                                      ?.toString() ??
                                  '—',
                              'Likes',
                              () => open(
                                ProfileInsightsScreen(controller: controller),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _stat(
                              '${p.strength}%',
                              'Complete',
                              () => open(
                                ProfileInsightsScreen(controller: controller),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ProfileButton(
                        label: 'Edit profile',
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            settings: const RouteSettings(
                              name: '/profile/edit',
                            ),
                            builder: (_) =>
                                ProfileEditScreen(controller: controller),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ProfileTile(
                        title: 'Preview profile',
                        icon: Icons.visibility_outlined,
                        onTap: () =>
                            open(ProfilePreviewScreen(controller: controller)),
                      ),
                      // Verification is hidden until the selfie check has a
                      // production backend; the screen is a developer test.
                      // ProfileTile(
                      //   title: p.verified
                      //       ? 'Verified profile'
                      //       : 'Verify your profile',
                      //   icon: Icons.verified_user_outlined,
                      //   onTap: () => open(
                      //     ProfileVerificationScreen(controller: controller),
                      //   ),
                      // ),
                      ProfileTile(
                        title: 'Profile insights',
                        icon: Icons.insights_outlined,
                        onTap: () =>
                            open(ProfileInsightsScreen(controller: controller)),
                      ),
                      if (controller.error != null)
                        const Text(
                          'Connection statistics could not refresh. Pull down to try again.',
                          style: TextStyle(color: profileTextSecondary),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _stat(String value, String label, VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: profileSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: profileBorder),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: profileTextPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(color: profileTextSecondary, fontSize: 12),
          ),
        ],
      ),
    ),
  );
}
