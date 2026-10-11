import 'package:flutter/material.dart';

import '../models/vibe_category.dart';

abstract final class VibeCategories {
  static const all = <VibeCategory>[
    VibeCategory(
      id: 'coffee_chats',
      title: 'Coffee & Chats',
      description: 'Café dates and slow mornings',
      emoji: '☕',
      color: Color(0xFFFFE5D7),
      interests: ['coffee', 'podcasts', 'books'],
    ),
    VibeCategory(
      id: 'late_night_talks',
      title: 'Late Night Talks',
      description: 'Good conversations after dark',
      emoji: '🌙',
      color: Color(0xFFECE5F8),
      interests: ['nightlife', 'music', 'comedy'],
    ),
    VibeCategory(
      id: 'music_chill',
      title: 'Music & Chill',
      description: 'Playlists, gigs, and quiet nights',
      emoji: '🎵',
      color: Color(0xFFF8E6F0),
      interests: ['music', 'podcasts', 'concerts'],
    ),
    VibeCategory(
      id: 'food_adventures',
      title: 'Food Adventures',
      description: 'Find your next favorite spot',
      emoji: '🍜',
      color: Color(0xFFFFE9D8),
      interests: ['food', 'cooking', 'coffee'],
    ),
    VibeCategory(
      id: 'travel_buddies',
      title: 'Travel Buddies',
      description: 'New places and spontaneous trips',
      emoji: '✈️',
      color: Color(0xFFE3F0F5),
      interests: ['travel', 'beach_days', 'hiking'],
    ),
    VibeCategory(
      id: 'feeling_romantic',
      title: 'Feeling Romantic',
      description: 'Thoughtful dates and real connection',
      emoji: '💗',
      color: Color(0xFFFFE3E5),
      interests: ['art', 'photography', 'cooking'],
    ),
    VibeCategory(
      id: 'gaming_together',
      title: 'Gaming Together',
      description: 'Friendly competition and co-op fun',
      emoji: '🎮',
      color: Color(0xFFECE6FA),
      interests: ['gaming', 'board_games', 'anime'],
    ),
    VibeCategory(
      id: 'study_dates',
      title: 'Study Dates',
      description: 'Curious minds and cozy cafés',
      emoji: '📚',
      color: Color(0xFFE9EEF9),
      interests: ['books', 'technology', 'museums'],
    ),
    VibeCategory(
      id: 'random_plans',
      title: 'Random Plans',
      description: 'Say yes to a little adventure',
      emoji: '✨',
      color: Color(0xFFFFEAD7),
      interests: ['travel', 'dancing', 'comedy'],
    ),
  ];

  static VibeCategory? byId(String id) =>
      all.where((category) => category.id == id).firstOrNull;
}
