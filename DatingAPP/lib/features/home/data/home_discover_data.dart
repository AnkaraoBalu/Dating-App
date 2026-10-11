class HomePerson {
  const HomePerson({
    required this.name,
    required this.age,
    required this.image,
    required this.distance,
    required this.match,
    required this.bio,
    required this.tags,
    this.online = false,
    this.education,
    this.id = '',
    this.photos = const [],
    this.prompts = const [],
    this.verified = false,
    this.latitude,
    this.longitude,
    this.location,
    this.jobTitle,
    this.company,
    this.heightCm,
    this.zodiac,
    this.languages = const [],
  });

  final String name;
  final int age;
  final String image;
  final String distance;
  final int match;
  final String bio;
  final List<String> tags;
  final bool online;
  final String? education;
  final String id;
  final List<String> photos;
  final List<Map<String, String>> prompts;
  final bool verified;
  final double? latitude;
  final double? longitude;
  final String? location;
  final String? jobTitle;
  final String? company;
  final int? heightCm;
  final String? zodiac;
  final List<String> languages;
}

abstract final class HomeDiscoverData {
  static const lead = HomePerson(
    name: 'Aanya',
    age: 22,
    image: 'assets/images/girls-images/golden_hour_portrait.png',
    distance: '5 km away',
    match: 87,
    bio: 'Good coffee, deep conversations and spontaneous trips ✨',
    tags: ['☕ Coffee', '✈️ Travel', '♫ Music', '+2'],
    education: 'B.Tech, IIIT Hyd',
    online: true,
  );

  static const nearby = [
    HomePerson(
      name: 'Meera',
      age: 22,
      image: 'assets/images/girls-images/sunset_floral_portrait.png',
      distance: '2 km',
      match: 91,
      bio: 'Finding little joys in every city.',
      tags: ['Travel', 'Coffee'],
      online: true,
    ),
    HomePerson(
      name: 'Kavya',
      age: 23,
      image: 'assets/images/girls-images/cafe_coffee_portrait.png',
      distance: '3 km',
      match: 84,
      bio: 'Weekend brunch and live music fan.',
      tags: ['Music', 'Food'],
      online: true,
    ),
    HomePerson(
      name: 'Anika',
      age: 24,
      image: 'assets/images/girls-images/cozy_headphones_portrait.png',
      distance: '4 km',
      match: 79,
      bio: 'Books, playlists and long walks.',
      tags: ['Books', 'Music'],
    ),
    HomePerson(
      name: 'Diya',
      age: 22,
      image: 'assets/images/girls-images/city_night_portrait.png',
      distance: '6 km',
      match: 82,
      bio: 'Always planning my next adventure.',
      tags: ['Art', 'Travel'],
      online: true,
    ),
  ];
}
