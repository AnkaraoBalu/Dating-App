import 'package:flutter/material.dart';
import '../../data/profile_controller.dart';
import '../../models/member_profile.dart';
import '../widgets/profile_widgets.dart';

class ProfilePreviewScreen extends StatelessWidget {
  const ProfilePreviewScreen({
    super.key,
    required this.controller,
    this.afterEdit = false,
  });
  final ProfileController controller;
  final bool afterEdit;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (_, _) {
      final p = controller.profile!;
      return ProfilePage(
        title: 'Profile Preview',
        bottom: afterEdit
            ? ProfileButton(
                label: 'Looks good! ✨',
                onPressed: () {
                  Navigator.popUntil(
                    context,
                    (route) =>
                        route.settings.name == '/profile/edit' || route.isFirst,
                  );
                  if (Navigator.canPop(context)) Navigator.pop(context);
                },
              )
            : null,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: SizedBox(
                height: 380,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ProfilePhotoView(
                      p.photos.isEmpty ? null : p.photos.first.url,
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.center,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 18,
                      right: 18,
                      bottom: 18,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  '${p.name}${p.age == null ? '' : ', ${p.age}'}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (p.verified)
                                const Padding(
                                  padding: EdgeInsets.only(left: 6),
                                  child: Icon(
                                    Icons.verified,
                                    color: Colors.blue,
                                    size: 20,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            p.text('location'),
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            if (p.text('bio').isNotEmpty)
              Text(
                p.text('bio'),
                style: const TextStyle(height: 1.6, color: profileTextPrimary),
              ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: p.interests
                  .map((s) => Chip(label: Text(displayValue(s))))
                  .toList(),
            ),
            if (p.photos.length > 1) ...[
              const ProfileSection('My photos'),
              SizedBox(
                height: 140,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: p.photos.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (_, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: SizedBox(
                      width: 110,
                      child: ProfilePhotoView(p.photos[i].url),
                    ),
                  ),
                ),
              ),
            ],
            for (final prompt in p.prompts) ...[
              ProfileSection(prompt['question']!),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: profileSurface,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  prompt['answer']!,
                  style: const TextStyle(
                    color: profileTextPrimary,
                    height: 1.5,
                  ),
                ),
              ),
            ],
            const ProfileSection('A little more about me'),
            for (final field in {
              'education': 'Education',
              'fieldOfStudy': 'Field of study',
              'jobTitle': 'Work',
              'company': 'Company',
              'industry': 'Industry',
              'heightCm': 'Height (cm)',
              'zodiac': 'Zodiac',
              'smoking': 'Smoking',
              'drinking': 'Drinking',
              'diet': 'Diet',
              'religion': 'Religion',
            }.entries)
              if (p.text(field.key).isNotEmpty)
                ProfileTile(
                  title: field.value,
                  value: ['smoking', 'drinking', 'diet'].contains(field.key)
                      ? displayValue(p.text(field.key))
                      : p.text(field.key),
                  icon: Icons.person_outline,
                ),
            if (p.values('languages').isNotEmpty)
              ProfileTile(
                title: 'Languages',
                value: p.values('languages').join(', '),
                icon: Icons.language,
              ),
            if (p.values('datingIntentions', fromOnboarding: true).isNotEmpty)
              ProfileTile(
                title: 'Looking for',
                value: p
                    .values('datingIntentions', fromOnboarding: true)
                    .map(displayValue)
                    .join(', '),
                icon: Icons.favorite_outline,
              ),
            for (final field in {
              'vibeType': 'My vibe',
              'idealFriday': 'My ideal Friday',
              'currentEra': 'My current era',
            }.entries)
              if (p.onboardingText(field.key).isNotEmpty)
                ProfileTile(
                  title: field.value,
                  value: displayValue(p.onboardingText(field.key)),
                  icon: Icons.auto_awesome_outlined,
                ),
            for (final field in {
              'musicGenres': 'Music',
              'favoriteArtists': 'Favorite artists',
              'dealbreakers': 'What matters to me',
            }.entries)
              if (p.values(field.key, fromOnboarding: true).isNotEmpty)
                ProfileTile(
                  title: field.value,
                  value: p
                      .values(field.key, fromOnboarding: true)
                      .map(displayValue)
                      .join(', '),
                  icon: Icons.favorite_border,
                ),
          ],
        ),
      );
    },
  );
}
