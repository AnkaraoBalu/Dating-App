class OnboardingProfile {
  const OnboardingProfile({
    this.username,
    this.birthDate,
    this.genderIdentity,
    this.interestedIn,
    this.datingIntentions = const [],
    this.vibeType,
    this.idealFriday,
    this.interests = const [],
    this.musicGenres = const [],
    this.favoriteArtists = const [],
    this.skippedQuestions = const [],
    this.currentEra,
    this.dealbreakers = const [],
    this.preferredDistanceKm = 25,
    this.onlyShowPeopleNearby = true,
    this.locationPermissionGranted = false,
    this.completedAt,
  });

  final String? username;
  final DateTime? birthDate;
  final String? genderIdentity;
  final String? interestedIn;
  final List<String> datingIntentions;
  final String? vibeType;
  final String? idealFriday;
  final List<String> interests;
  final List<String> musicGenres;
  final List<String> favoriteArtists;
  final List<String> skippedQuestions;
  final String? currentEra;
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
      vibeType: json['vibeType'] as String?,
      idealFriday: json['idealFriday'] as String?,
      interests: (json['interests'] as List<dynamic>? ?? []).cast<String>(),
      musicGenres: (json['musicGenres'] as List<dynamic>? ?? []).cast<String>(),
      favoriteArtists: (json['favoriteArtists'] as List<dynamic>? ?? [])
          .cast<String>(),
      skippedQuestions: (json['skippedQuestions'] as List<dynamic>? ?? [])
          .cast<String>(),
      currentEra: json['currentEra'] as String?,
      dealbreakers: (json['dealbreakers'] as List<dynamic>? ?? [])
          .cast<String>(),
      preferredDistanceKm: json['preferredDistanceKm'] as int? ?? 25,
      onlyShowPeopleNearby: json['onlyShowPeopleNearby'] as bool? ?? true,
      locationPermissionGranted:
          json['locationPermissionGranted'] as bool? ?? false,
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
    );
  }
}
