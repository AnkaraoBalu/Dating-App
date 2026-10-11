import 'package:flutter/material.dart';

/// Stored onboarding values and their user-facing labels/icons.
abstract final class OnboardingQuestionOptions {
  static String labelFor(String? value) {
    if (value == null) return 'Not set';
    final labels = <(String, String)>[
      for (final option in genders) (option.$1, option.$2),
      for (final option in attractions) (option.$1, option.$2),
      for (final option in intentions) (option.$1, option.$2),
      for (final option in vibes) (option.$1, option.$2),
      for (final option in idealFridays) (option.$1, option.$2),
      for (final option in interests) (option.$1, option.$2),
      for (final option in musicGenres) (option.$1, option.$2),
      for (final option in currentEras) (option.$1, option.$2),
      for (final option in dealbreakers) (option.$1, option.$2),
    ];
    return labels
            .where((option) => option.$1 == value)
            .map((option) => option.$2)
            .firstOrNull ??
        value.replaceAll('_', ' ');
  }

  static const genders = [
    ('man', 'Man', Icons.face_rounded),
    ('woman', 'Woman', Icons.face_3_rounded),
    ('non_binary', 'Non-binary', Icons.wc_rounded),
    ('prefer_not_to_say', 'Prefer not to say', Icons.more_horiz_rounded),
  ];

  static const attractions = [
    ('women', 'Women', Icons.female_rounded),
    ('men', 'Men', Icons.male_rounded),
    ('everyone', 'Everyone', Icons.diversity_3_rounded),
  ];

  static const intentions = [
    ('something_serious', 'Something serious', Icons.favorite_outline_rounded),
    ('open_to_anything', 'Open to anything', Icons.waves_rounded),
    ('casual', 'Casual dating', Icons.local_cafe_outlined),
    ('friendship', 'New friends first', Icons.people_outline_rounded),
    ('not_sure_yet', 'Not sure yet', Icons.help_outline_rounded),
  ];

  static const vibes = [
    ('golden_retriever', 'Golden retriever', 'Outgoing, warm, and friendly'),
    ('black_cat', 'Black cat', 'Calm, observant, a little mysterious'),
    ('social_butterfly', 'Social butterfly', 'Always up for a plan'),
    ('chill_and_balanced', 'Chill & balanced', 'Peaceful, easygoing energy'),
    ('ambitious_energy', 'Ambitious energy', 'Focused, curious, driven'),
    ('sunshine', 'Sunshine energy', 'Optimistic and easy to be around'),
    ('slow_burn', 'Slow burn', 'Thoughtful; connection takes time'),
    ('chaotic_good', 'Chaotic good', 'Spontaneous with a big heart'),
    ('somewhere_between', 'Somewhere between', 'A little bit of everything'),
    (
      'depends_who_im_with',
      'Depends who I’m with',
      'The right company sets the vibe',
    ),
    ('other', 'My own kind of energy', 'Hard to fit into one label'),
  ];

  static const idealFridays = [
    ('club', 'Out dancing', Icons.nightlife_rounded),
    ('movie_and_food', 'Movie + good food', Icons.movie_outlined),
    ('long_drive', 'A late-night drive', Icons.directions_car_outlined),
    ('gaming', 'Gaming night', Icons.sports_esports_outlined),
    ('rooftop', 'Rooftop conversations', Icons.apartment_rounded),
    ('house_party', 'House party', Icons.celebration_outlined),
    ('quiet_evening', 'A quiet evening', Icons.self_improvement_rounded),
    ('cafe_hopping', 'Cafe hopping', Icons.local_cafe_outlined),
    ('cozy_night_in', 'Cozy night in', Icons.weekend_outlined),
    ('live_music', 'Live music', Icons.music_note_rounded),
    ('dinner_with_friends', 'Dinner with friends', Icons.dinner_dining_rounded),
    ('cooking_at_home', 'Cooking something new', Icons.soup_kitchen_outlined),
    ('spontaneous_adventure', 'A spontaneous plan', Icons.explore_outlined),
    ('outdoors', 'Out in nature', Icons.park_outlined),
    ('other', 'Something else entirely', Icons.auto_awesome_outlined),
  ];

  static const interests = [
    ('coffee', 'Coffee', Icons.coffee_outlined),
    ('gaming', 'Gaming', Icons.sports_esports_outlined),
    ('music', 'Music', Icons.music_note_rounded),
    ('books', 'Books', Icons.menu_book_outlined),
    ('planning', 'Planning', Icons.event_note_outlined),
    ('fitness', 'Fitness', Icons.fitness_center_rounded),
    ('travel', 'Travel', Icons.flight_takeoff_rounded),
    ('art', 'Art', Icons.palette_outlined),
    ('dogs', 'Dogs', Icons.pets_rounded),
    ('cats', 'Cats', Icons.cruelty_free_rounded),
    ('nightlife', 'Going out', Icons.nightlife_rounded),
    ('food', 'Foodie spots', Icons.restaurant_outlined),
    ('photography', 'Photography', Icons.camera_alt_outlined),
    ('sports', 'Sports', Icons.sports_basketball_outlined),
    ('hiking', 'Hiking', Icons.hiking_rounded),
    ('movies_and_tv', 'Movies & TV', Icons.live_tv_outlined),
    ('cooking', 'Cooking', Icons.dinner_dining_outlined),
    ('wellness', 'Wellness', Icons.spa_outlined),
    ('fashion', 'Fashion', Icons.checkroom_outlined),
    ('design', 'Design', Icons.draw_outlined),
    ('volunteering', 'Volunteering', Icons.volunteer_activism_outlined),
    ('podcasts', 'Podcasts', Icons.mic_none_rounded),
    ('nature', 'Nature', Icons.forest_rounded),
    ('dancing', 'Dancing', Icons.directions_run_rounded),
    ('concerts', 'Concerts', Icons.confirmation_num_outlined),
    ('technology', 'Tech', Icons.devices_other_rounded),
    ('cars', 'Cars', Icons.directions_car_filled_outlined),
    ('beach_days', 'Beach days', Icons.beach_access_outlined),
    ('board_games', 'Board games', Icons.casino_outlined),
    ('comedy', 'Comedy', Icons.theater_comedy_outlined),
    ('museums', 'Museums', Icons.account_balance_outlined),
    ('gardening', 'Gardening', Icons.yard_outlined),
    ('astrology', 'Astrology', Icons.auto_awesome_outlined),
    ('anime', 'Anime', Icons.movie_filter_outlined),
    ('culture', 'Culture', Icons.public_rounded),
    ('entrepreneurship', 'Building things', Icons.lightbulb_outline_rounded),
    ('family_time', 'Family time', Icons.family_restroom_rounded),
    ('spirituality', 'Spirituality', Icons.self_improvement_rounded),
    ('other', 'Something else', Icons.add_rounded),
  ];

  static const musicGenres = [
    ('indie', 'Indie', Icons.album_outlined),
    ('pop', 'Pop', Icons.star_outline_rounded),
    ('hip_hop', 'Hip-hop', Icons.graphic_eq_rounded),
    ('r_and_b', 'R&B', Icons.favorite_border_rounded),
    ('rock', 'Rock', Icons.music_note_rounded),
    ('edm', 'EDM', Icons.bolt_rounded),
    ('classical', 'Classical', Icons.piano_outlined),
    ('jazz', 'Jazz', Icons.graphic_eq_rounded),
    ('country', 'Country', Icons.music_note_outlined),
    ('afrobeats', 'Afrobeats', Icons.public_rounded),
    ('latin', 'Latin', Icons.local_fire_department_outlined),
    ('k_pop', 'K-pop', Icons.groups_2_outlined),
    ('metal', 'Metal', Icons.electric_bolt_rounded),
    ('folk', 'Folk', Icons.nature_people_outlined),
    ('bollywood', 'Bollywood', Icons.movie_creation_outlined),
    ('reggae', 'Reggae', Icons.wb_sunny_outlined),
    ('soundtracks', 'Soundtracks', Icons.movie_outlined),
    ('lo_fi', 'Lo-fi', Icons.headphones_outlined),
    ('punjabi', 'Punjabi', Icons.music_note_rounded),
    ('other', 'Other', Icons.add_rounded),
    ('a_bit_of_everything', 'A bit of everything', Icons.shuffle_rounded),
    ('not_big_on_music', 'Not big on music', Icons.volume_off_outlined),
  ];

  static const favoriteArtists = [
    'Taylor Swift',
    'The Weeknd',
    'Arijit Singh',
    'Diljit Dosanjh',
    'BTS',
    'Dua Lipa',
    'Drake',
    'SZA',
    'Bad Bunny',
    'A. R. Rahman',
    'Anirudh Ravichander',
    'Shreya Ghoshal',
    'Sid Sriram',
    'Coldplay',
    'Ed Sheeran',
    'Sabrina Carpenter',
    'Kendrick Lamar',
    'Billie Eilish',
  ];

  static const currentEras = [
    ('rebuilding', 'Rebuilding era', Icons.recycling_rounded),
    ('career_mode', 'Career mode', Icons.work_outline_rounded),
    ('travel_era', 'Travel era', Icons.flight_rounded),
    (
      'ready_for_something_real',
      'Ready for something real',
      Icons.favorite_rounded,
    ),
    ('chaos_era', 'Chaos era', Icons.bolt_rounded),
    ('peaceful_era', 'Peaceful era', Icons.spa_rounded),
    ('personal_growth', 'Personal growth', Icons.trending_up_rounded),
    ('exploring_myself', 'Exploring myself', Icons.explore_outlined),
    ('healing_and_growing', 'Healing & growing', Icons.spa_outlined),
    ('just_vibing', 'Just vibing', Icons.waves_rounded),
    ('new_chapter', 'A new chapter', Icons.auto_awesome_outlined),
    ('creative_era', 'Creative era', Icons.brush_outlined),
    ('figuring_it_out', 'Figuring it out', Icons.explore_outlined),
    ('other', 'My own era', Icons.auto_awesome_outlined),
  ];

  static const dealbreakers = [
    ('honesty', 'Honesty', Icons.verified_user_outlined),
    ('kindness', 'Kindness', Icons.volunteer_activism_outlined),
    ('good_communication', 'Good communication', Icons.chat_bubble_outline),
    ('emotional_availability', 'Emotional availability', Icons.favorite_border),
    ('respect', 'Mutual respect', Icons.handshake_outlined),
    ('consistency', 'Consistency', Icons.event_repeat_rounded),
    ('similar_values', 'Similar values', Icons.balance_outlined),
    ('shared_humor', 'A shared sense of humor', Icons.mood_outlined),
    ('ambition', 'Ambition', Icons.rocket_launch_outlined),
    ('family_oriented', 'Family-oriented', Icons.family_restroom_outlined),
    ('wants_children', 'Wants children', Icons.child_friendly_outlined),
    (
      'does_not_want_children',
      'Doesn’t want children',
      Icons.not_interested_rounded,
    ),
    ('monogamy', 'Monogamy', Icons.favorite_outline_rounded),
    ('non_monogamy', 'Ethical non-monogamy', Icons.diversity_1_rounded),
    ('no_smoking', 'No smoking', Icons.smoke_free_rounded),
    ('no_heavy_drinking', 'No heavy drinking', Icons.no_drinks_outlined),
    ('no_drugs', 'No recreational drugs', Icons.block_rounded),
    ('sobriety', 'Sober lifestyle', Icons.local_bar_outlined),
    ('pets', 'Must love pets', Icons.pets_rounded),
    (
      'religion_or_spirituality',
      'Faith or spirituality',
      Icons.temple_buddhist_outlined,
    ),
    (
      'political_compatibility',
      'Political compatibility',
      Icons.how_to_vote_outlined,
    ),
    (
      'financial_responsibility',
      'Financial responsibility',
      Icons.savings_outlined,
    ),
    ('affection', 'Affection', Icons.volunteer_activism_outlined),
    ('quality_time', 'Quality time', Icons.schedule_rounded),
    ('independence', 'Independence', Icons.airline_stops_rounded),
    ('open_minded', 'Open-mindedness', Icons.diversity_3_rounded),
    ('other', 'Other', Icons.add_rounded),
    (
      'no_hard_dealbreakers',
      'No hard deal-breakers',
      Icons.all_inclusive_rounded,
    ),
  ];
}
