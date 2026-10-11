import 'package:flutter/material.dart';
import '../../data/profile_controller.dart';
import '../widgets/profile_widgets.dart';

class ProfileInsightsScreen extends StatelessWidget {
  const ProfileInsightsScreen({super.key, required this.controller});
  final ProfileController controller;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (_, _) {
      final p = controller.profile!;
      return ProfilePage(
        title: 'Profile Insights',
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const ProfileSection(
              'Profile completeness',
              subtitle: 'Based on the information you’ve added',
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: profileSurface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: profileBorder),
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox.expand(
                          child: CircularProgressIndicator(
                            value: p.strength / 100,
                            strokeWidth: 10,
                            backgroundColor: profileBorder,
                            color: profileSuccess,
                          ),
                        ),
                        Text(
                          '${p.strength}%',
                          style: const TextStyle(
                            color: profileTextPrimary,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  for (final item in p.completion)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Row(
                        children: [
                          Icon(
                            item.done
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: item.done
                                ? profileSuccess
                                : profileTextTertiary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.label,
                              style: const TextStyle(color: profileTextPrimary),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const ProfileSection('Connections'),
            for (final item in [
              ('likesReceived', 'Likes received', Icons.favorite),
              ('likesSent', 'Likes sent', Icons.favorite_border),
              ('matches', 'Mutual matches', Icons.people_outline),
            ])
              ProfileTile(
                title: item.$2,
                value:
                    controller.insights[item.$1]?.toString() ?? 'Unavailable',
                icon: item.$3,
              ),
            const SizedBox(height: 12),
            const Text(
              'Completeness reflects your saved profile fields. Verification is separate and does not affect this score.',
              style: TextStyle(color: profileTextSecondary, height: 1.5),
            ),
          ],
        ),
      );
    },
  );
}
