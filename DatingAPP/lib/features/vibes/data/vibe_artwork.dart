import '../../../core/constants/app_assets.dart';

/// Bundled scene photography. These images must never stand in for a member.
abstract final class VibeArtwork {
  static const covers = <({String asset, String label})>[
    (asset: AppAssets.vibeCoffee, label: 'Coffee & Chats'),
    (asset: AppAssets.vibeNight, label: 'Late Night Talks'),
    (asset: AppAssets.vibeMusic, label: 'Live Music'),
    (asset: AppAssets.vibeFood, label: 'Food Adventures'),
    (asset: AppAssets.vibeMountains, label: 'Mountain Travel'),
    (asset: AppAssets.vibeBeach, label: 'Beach Getaway'),
    (asset: AppAssets.vibeCity, label: 'City Exploration'),
    (asset: AppAssets.vibeRomantic, label: 'Romantic Dinner'),
    (asset: AppAssets.vibeBoardGames, label: 'Board Games'),
    (asset: AppAssets.vibeArcade, label: 'Arcade Games'),
    (asset: AppAssets.vibeStudy, label: 'Study Dates'),
    (asset: AppAssets.vibeMovie, label: 'Movie Night'),
  ];

  static String forCategory(String categoryId) => switch (categoryId) {
    'coffee_chats' => AppAssets.vibeCoffee,
    'late_night_talks' => AppAssets.vibeNight,
    'music_chill' => AppAssets.vibeMusic,
    'food_adventures' => AppAssets.vibeFood,
    'travel_buddies' => AppAssets.vibeMountains,
    'feeling_romantic' => AppAssets.vibeRomantic,
    'gaming_together' => AppAssets.vibeBoardGames,
    'study_dates' => AppAssets.vibeStudy,
    _ => AppAssets.vibeCity,
  };

  /// Old rooms stored bundled portraits as covers. Resolve those at display
  /// time, preserving the original server value and any new/custom cover.
  static String roomCover(String asset, {required String categoryId}) {
    if (asset == 'assets/images/girls-images/cozy_headphones_portrait.png' &&
        categoryId == 'gaming_together') {
      return AppAssets.vibeMovie;
    }
    if (asset.isEmpty ||
        asset.startsWith('assets/images/boys-images/') ||
        asset.startsWith('assets/images/girls-images/')) {
      return forCategory(categoryId);
    }
    return asset;
  }

  // Match whole choices, never the question number: rounds may be reordered.
  // Both choices need imagery, so one side never gets extra visual emphasis.
  static List<String>? forChoices(String gameType, List<String> options) {
    if (gameType != 'this_or_that' && gameType != 'would_you_rather') {
      return null;
    }
    const images = {
      'Beach getaway': AppAssets.vibeBeach,
      'City exploration': AppAssets.vibeCity,
      'Live music': AppAssets.vibeMusic,
      'Movie night': AppAssets.vibeMovie,
      'Mountains': AppAssets.vibeMountains,
      'Ocean': AppAssets.vibeBeach,
      'Board games': AppAssets.vibeBoardGames,
      'Arcade games': AppAssets.vibeArcade,
    };
    final result = <String>[];
    for (final option in options) {
      final asset = images[option];
      if (asset == null) return null;
      result.add(asset);
    }
    return result.isEmpty ? null : result;
  }
}
