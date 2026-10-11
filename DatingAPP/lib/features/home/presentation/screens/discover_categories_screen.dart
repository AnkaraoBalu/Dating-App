import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';

class DiscoverCategoriesScreen extends StatelessWidget {
  const DiscoverCategoriesScreen({super.key});

  static const _categories = [
    (
      'All interests',
      '✦',
      'Clear the current interest filter',
      Color(0xFFF1EAE0),
      '',
    ),
    ('Coffee', '☕', 'Café dates & slow mornings', Color(0xFFFFE3D8), 'coffee'),
    ('Travel', '✈️', 'Weekend trips & new places', Color(0xFFE3F0F5), 'travel'),
    (
      'Music',
      '♫',
      'Artists, playlists & live shows',
      Color(0xFFEDE6F5),
      'music',
    ),
    ('Food', '🍜', 'Good food and new spots', Color(0xFFFFE9D8), 'food'),
    ('Gym', '🏋️', 'Fitness and active days', Color(0xFFE5EFE9), 'fitness'),
    ('Nature', '🌿', 'Outdoors and fresh air', Color(0xFFE2F0E4), 'nature'),
    (
      'Movies',
      '🎬',
      'Films and TV favorites',
      Color(0xFFE4EAF4),
      'movies_and_tv',
    ),
    ('Art', '🎨', 'Making and finding art', Color(0xFFF7E4E7), 'art'),
    ('Pets', '🐾', 'People who love animals', Color(0xFFF6ECD9), 'dogs'),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      title: Text(
        'Explore by interests',
        style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
      ),
    ),
    body: GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: .78,
      ),
      itemBuilder: (context, index) {
        final category = _categories[index];
        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => Navigator.of(context).pop(category.$5),
          child: Ink(
            decoration: BoxDecoration(
              color: category.$4,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  left: 11,
                  right: 8,
                  bottom: 11,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(category.$2, style: const TextStyle(fontSize: 25)),
                      const SizedBox(height: 4),
                      Text(
                        category.$1,
                        style: AppTypography.label.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        category.$3,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
