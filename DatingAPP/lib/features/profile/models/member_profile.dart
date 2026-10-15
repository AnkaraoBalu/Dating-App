import '../../onboarding/models/onboarding_profile.dart';
import '../../home/data/home_discover_data.dart';

class MemberPhoto {
  const MemberPhoto({required this.id, required this.url});
  final String id;
  final String url;
}

class MemberProfile {
  MemberProfile(this.data);
  final Map<String, dynamic> data;

  Map<String, dynamic> get user =>
      Map<String, dynamic>.from(data['user'] as Map? ?? {});
  Map<String, dynamic> get onboarding =>
      Map<String, dynamic>.from(user['onboardingProfile'] as Map? ?? {});
  int get preferredDistanceKm {
    final value = onboarding['preferredDistanceKm'];
    return (value is num ? value.round() : 25).clamp(1, 100).toInt();
  }

  bool get onlyShowPeopleNearby => onboarding['onlyShowPeopleNearby'] == true;

  /// Discovery "Show me" value (man/woman/everyone) from the onboarding
  /// "Who are you interested in?" answer, which is the single source of truth.
  String get discoveryGender => switch (onboarding['interestedIn']) {
    'women' => 'woman',
    'men' => 'man',
    _ => 'everyone',
  };

  static String interestedInFor(String discoveryGender) =>
      switch (discoveryGender) {
        'woman' => 'women',
        'man' => 'men',
        _ => 'everyone',
      };

  List<String> lifestyleChoices(String key) =>
      readOnboardingChoices(onboarding, key, switch (key) {
        'vibeTypes' => 'vibeType',
        'idealFridays' => 'idealFriday',
        'currentEras' => 'currentEra',
        _ => key,
      });

  String text(String key) => data[key]?.toString() ?? '';
  String onboardingText(String key) => onboarding[key]?.toString() ?? '';
  List<String> values(String key, {bool fromOnboarding = false}) =>
      ((fromOnboarding ? onboarding : data)[key] as List<dynamic>? ?? [])
          .whereType<String>()
          .toList();
  bool flag(String key) => data[key] != false;
  String get firstName => user['firstName']?.toString() ?? '';
  String get lastName => user['lastName']?.toString() ?? '';
  String get username => user['username']?.toString() ?? '';
  String get name => username.trim();
  DateTime? get birthDate => DateTime.tryParse(onboardingText('birthDate'));
  int? ageAt(DateTime now) {
    final birth = birthDate;
    if (birth == null) return null;
    return now.year -
        birth.year -
        ((now.month < birth.month ||
                (now.month == birth.month && now.day < birth.day))
            ? 1
            : 0);
  }

  int? get age => ageAt(DateTime.now());
  bool get verified => text('verificationStatus') == 'verified';
  List<MemberPhoto> get photos => (data['photos'] as List<dynamic>? ?? [])
      .whereType<Map>()
      .map(
        (photo) => MemberPhoto(
          id: photo['id']?.toString() ?? '',
          url: (photo['secureUrl'] ?? photo['url'])?.toString() ?? '',
        ),
      )
      .where((photo) => photo.url.trim().isNotEmpty)
      .toList();
  List<Map<String, String>> get prompts =>
      (data['prompts'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(
            (p) => {
              'question': p['question']?.toString() ?? '',
              'answer': p['answer']?.toString() ?? '',
            },
          )
          .toList();
  List<String> get interests => values('interests', fromOnboarding: true);
  List<({String label, bool done})> get completion => [
    (label: 'Add at least 4 photos', done: photos.length >= 4),
    (label: 'Write a bio', done: text('bio').trim().isNotEmpty),
    (label: 'Answer at least 3 prompts', done: prompts.length >= 3),
    (label: 'Choose at least 3 interests', done: interests.length >= 3),
    (label: 'Add your location', done: text('location').isNotEmpty),
    (
      label: 'Add education or work',
      done: text('education').isNotEmpty || text('jobTitle').isNotEmpty,
    ),
  ];
  int get strength =>
      (completion.where((c) => c.done).length / completion.length * 100)
          .round();
  HomePerson get preview => HomePerson(
    id: data['userId']?.toString() ?? '',
    name: name.isEmpty ? 'Your profile' : name,
    age: age ?? 18,
    image: photos.isEmpty ? '' : photos.first.url,
    photos: photos.map((p) => p.url).toList(),
    prompts: prompts,
    distance: text('location'),
    match: 0,
    bio: text('bio'),
    tags: interests.map(displayValue).toList(),
    verified: verified,
    location: text('location'),
    education: [
      text('education'),
      text('fieldOfStudy'),
    ].where((v) => v.isNotEmpty).join(', '),
    jobTitle: text('jobTitle'),
    company: text('company'),
    heightCm: data['heightCm'] as int?,
    zodiac: text('zodiac'),
    languages: values('languages'),
  );
}

String displayValue(String value) {
  const labels = {
    'man': 'Man',
    'woman': 'Woman',
    'non_binary': 'Non-binary',
    'fitness': 'Gym',
    'movies_and_tv': 'Movies & TV',
    'dogs': 'Dogs',
    'cats': 'Cats',
  };
  if (labels.containsKey(value)) return labels[value]!;
  if (value.isEmpty) return 'Not added';
  return value
      .replaceAll('_', ' ')
      .split(' ')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}
