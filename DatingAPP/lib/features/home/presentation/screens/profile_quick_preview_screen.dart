import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/theme.dart';
import '../../data/home_discover_data.dart';
import '../../data/discover_api.dart';
import '../widgets/profile_like_button.dart';
import 'profile_detail_screen.dart';
import '../widgets/home_person_photo.dart';

class ProfileQuickPreviewScreen extends StatelessWidget {
  const ProfileQuickPreviewScreen({super.key, required this.person, this.api});
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
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => Stack(
            fit: StackFit.expand,
            children: [
              HomePersonPhoto.imageFor(person.image, personName: person.name),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x22000000),
                      Colors.transparent,
                      Color(0xF0000000),
                    ],
                    stops: [0, .32, 1],
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: IconButton.filledTonal(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black45,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              Positioned(
                left: 18,
                right: 18,
                bottom: 20,
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: (constraints.maxHeight - 84).clamp(
                      0.0,
                      double.infinity,
                    ),
                  ),
                  padding: const EdgeInsets.all(19),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${person.name}, ${person.age}',
                                style: AppTypography.title.copyWith(
                                  color: AppColors.textPrimary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            if (person.verified)
                              const Icon(
                                Icons.verified_rounded,
                                color: AppColors.verified,
                              ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Icon(
                              person.online
                                  ? Icons.circle
                                  : Icons.location_on_rounded,
                              size: 14,
                              color: person.online
                                  ? AppColors.success
                                  : AppColors.forest,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                person.online ? 'Online now' : person.distance,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '“${person.bio}”',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textPrimary,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 11),
                        Wrap(
                          spacing: 6,
                          children: person.tags
                              .take(3)
                              .map(
                                (tag) => Chip(
                                  label: Text(tag),
                                  visualDensity: VisualDensity.compact,
                                  backgroundColor: AppColors.surfaceSecondary,
                                  side: BorderSide.none,
                                  labelStyle: AppTypography.caption.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 6),
                        OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  ProfileDetailScreen(person: person, api: api),
                            ),
                          ),
                          icon: const Icon(Icons.person_outline_rounded),
                          label: const Text('View full profile'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.forest,
                            minimumSize: const Size.fromHeight(44),
                            side: const BorderSide(
                              color: AppColors.borderStrong,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ProfileLikeButton(
                                person: person,
                                api: api,
                              ),
                            ),
                            const SizedBox(width: 10),
                            IconButton.filledTonal(
                              onPressed: () =>
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Profile menu opened'),
                                    ),
                                  ),
                              icon: const Icon(Icons.more_horiz),
                              style: IconButton.styleFrom(
                                minimumSize: const Size(48, 46),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
