import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/theme.dart';
import '../../data/home_discover_data.dart';
import '../../data/discover_api.dart';
import '../widgets/profile_like_button.dart';
import '../widgets/home_person_photo.dart';

class ProfileDetailScreen extends StatelessWidget {
  const ProfileDetailScreen({super.key, required this.person, this.api});

  final HomePerson person;
  final DiscoverApi? api;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light.copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: AppColors.background,
    ),
    child: Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 470,
            pinned: true,
            backgroundColor: AppColors.darkBackground,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  HomePersonPhoto.imageFor(
                    person.image,
                    personName: person.name,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x33000000),
                          Colors.transparent,
                          Color(0xF5000000),
                        ],
                        stops: [0, .35, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 22,
                    right: 22,
                    bottom: 22,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${person.name}, ${person.age}',
                          style: AppTypography.title.copyWith(
                            color: Colors.white,
                            fontSize: 27,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          [person.distance, person.education]
                              .whereType<String>()
                              .where((value) => value.isNotEmpty)
                              .join('  ·  '),
                          style: AppTypography.body.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        if (person.online)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  radius: 5,
                                  backgroundColor: AppColors.success,
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  'Online now',
                                  style: AppTypography.caption.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 30),
            sliver: SliverList.list(
              children: [
                Text(
                  'A little about ${person.name}',
                  style: AppTypography.h3.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  person.bio,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                if (person.photos.length > 1) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 104,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: person.photos.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 9),
                      itemBuilder: (context, index) => ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          width: 82,
                          child: HomePersonPhoto.imageFor(
                            person.photos[index],
                            personName: person.name,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Text(
                  'Things I enjoy',
                  style: AppTypography.h3.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: person.tags
                      .map(
                        (tag) => Chip(
                          label: Text(tag),
                          backgroundColor: AppColors.surfaceSecondary,
                          labelStyle: AppTypography.caption.copyWith(
                            color: AppColors.textPrimary,
                          ),
                          side: BorderSide.none,
                        ),
                      )
                      .toList(),
                ),
                if (person.prompts.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'A little more about ${person.name}',
                    style: AppTypography.h3.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final prompt in person.prompts) ...[
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            prompt['question'] ?? '',
                            style: AppTypography.label.copyWith(
                              color: AppColors.coralPressed,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            prompt['answer'] ?? '',
                            style: AppTypography.body.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 24),
                if (person.education != null)
                  _InfoRow(
                    icon: Icons.school_outlined,
                    label: 'Education',
                    value: person.education!,
                  ),
                if (person.jobTitle != null)
                  _InfoRow(
                    icon: Icons.work_outline_rounded,
                    label: 'Work',
                    value: [
                      person.jobTitle,
                      person.company,
                    ].whereType<String>().join(' · '),
                  ),
                if (person.heightCm != null)
                  _InfoRow(
                    icon: Icons.height_rounded,
                    label: 'Height',
                    value: '${person.heightCm} cm',
                  ),
                if (person.zodiac != null)
                  _InfoRow(
                    icon: Icons.auto_awesome_outlined,
                    label: 'Zodiac',
                    value: person.zodiac!,
                  ),
                if (person.languages.isNotEmpty)
                  _InfoRow(
                    icon: Icons.language_rounded,
                    label: 'Languages',
                    value: person.languages.join(', '),
                  ),
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  label: 'Location',
                  value: person.distance,
                ),
                const SizedBox(height: 24),
                ProfileLikeButton(person: person, api: api),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 20),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
