class OnboardingProfile {
  const OnboardingProfile({
    this.username,
    this.birthDate,
    this.genderIdentity,
    this.interestedIn,
    this.datingIntentions = const [],
    this.vibeTypes = const [],
    this.idealFridays = const [],
    this.interests = const [],
    this.musicGenres = const [],
    this.favoriteArtists = const [],
    this.skippedQuestions = const [],
    this.currentEras = const [],
    this.dealbreakers = const [],
    this.preferredDistanceKm = 25,
    this.onlyShowPeopleNearby = false,
    this.locationPermissionGranted = false,
    this.completedAt,
  });

  final String? username;
  final DateTime? birthDate;
  final String? genderIdentity;
  final String? interestedIn;
  final List<String> datingIntentions;
  final List<String> vibeTypes;
  final List<String> idealFridays;
  final List<String> interests;
  final List<String> musicGenres;
  final List<String> favoriteArtists;
  final List<String> skippedQuestions;
  final List<String> currentEras;
  final List<String> dealbreakers;
  final int preferredDistanceKm;
  final bool onlyShowPeopleNearby;
  final bool locationPermissionGranted;
  final DateTime? completedAt;

  factory OnboardingProfile.fromJson(Map<String, dynamic> json) {
    return OnboardingProfile(
      username: json['username'] as String?,
      birthDate: json['birthDate'] == null
          ? null
          : DateTime.parse(json['birthDate'] as String),
      genderIdentity: json['genderIdentity'] as String?,
      interestedIn: json['interestedIn'] as String?,
      datingIntentions: (json['datingIntentions'] as List<dynamic>? ?? [])
          .cast<String>(),
      vibeTypes: readOnboardingChoices(json, 'vibeTypes', 'vibeType'),
      idealFridays: readOnboardingChoices(json, 'idealFridays', 'idealFriday'),
      interests: (json['interests'] as List<dynamic>? ?? []).cast<String>(),
      musicGenres: (json['musicGenres'] as List<dynamic>? ?? []).cast<String>(),
      favoriteArtists: (json['favoriteArtists'] as List<dynamic>? ?? [])
          .cast<String>(),
      skippedQuestions: (json['skippedQuestions'] as List<dynamic>? ?? [])
          .cast<String>(),
      currentEras: readOnboardingChoices(json, 'currentEras', 'currentEra'),
      dealbreakers: (json['dealbreakers'] as List<dynamic>? ?? [])
          .cast<String>(),
      preferredDistanceKm: json['preferredDistanceKm'] as int? ?? 25,
      onlyShowPeopleNearby: json['onlyShowPeopleNearby'] as bool? ?? false,
      locationPermissionGranted:
          json['locationPermissionGranted'] as bool? ?? false,
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
    );
  }
}

List<String> readOnboardingChoices(
  Map<String, dynamic> data,
  String key,
  String legacyKey,
) {
  final value = data[key];
  if (value is List) return value.whereType<String>().toSet().toList();
  final legacy = data[legacyKey];
  return legacy is String && legacy.isNotEmpty ? [legacy] : [];
}
