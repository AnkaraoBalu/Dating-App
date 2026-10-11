abstract final class ProfileSetupOptions {
  static const menPhotos = [
    'assets/images/boys-images/rooftop_sunset_portrait.png',
    'assets/images/boys-images/cafe_hoodie_portrait.png',
    'assets/images/boys-images/sunset_jacket_portrait.png',
    'assets/images/boys-images/cafe_smiling_portrait.png',
    'assets/images/boys-images/golden_hour_white_shirt.png',
    'assets/images/boys-images/city_night_portrait.png',
  ];

  static const womenPhotos = [
    'assets/images/girls-images/golden_hour_portrait.png',
    'assets/images/girls-images/cafe_coffee_portrait.png',
    'assets/images/girls-images/sunset_floral_portrait.png',
    'assets/images/girls-images/iced_coffee_portrait.png',
    'assets/images/girls-images/cozy_headphones_portrait.png',
    'assets/images/girls-images/city_night_portrait.png',
  ];

  static const promptFilters = [
    'All',
    'Fun',
    'Deep',
    'Lifestyle',
    'Relationships',
    'Values',
    'Random',
    'Creative',
  ];

  static const promptSections = <String, List<String>>{
    'About Me': [
      'My current obsession is...',
      'I’m the type of person who...',
      'You should know that...',
      'The thing that makes me, me...',
      'I get excited about...',
      'A little-known fact about me...',
      'My friends would say I’m...',
      'I feel most like myself when...',
    ],
    'Fun & Quirky': [
      'A perfect Sunday looks like...',
      'The most spontaneous thing I’ve ever done...',
      'My go-to karaoke song is...',
      'My most useless talent is...',
      'I’ll never say no to...',
      'The quickest way to make me laugh...',
      'My weirdest food combination is...',
      'A random fact I love is...',
    ],
    'Lifestyle': [
      'You’ll usually find me...',
      'I can’t live without...',
      'My weekend looks like...',
      'My ideal morning starts with...',
      'The place I want to explore next...',
      'My favorite way to unwind...',
      'A hobby I’m proud of...',
      'The best part of my day...',
    ],
    'Relationships': [
      'A green flag I love is...',
      'We’d get along if...',
      'Dating me feels like...',
      'The way to my heart is...',
      'My love language is...',
      'A great first date would be...',
      'I’m looking for someone who...',
      'The little things I appreciate...',
    ],
    'Values & Opinions': [
      'A value I live by...',
      'Something I’ll always stand for...',
      'A lesson I’m grateful for...',
      'Good communication means...',
      'An opinion I’ll defend...',
      'What matters most to me...',
      'The best advice I’ve received...',
    ],
    'Goals & Ambitions': [
      'I’m working toward...',
      'A dream I’m chasing...',
      'In five years I hope to...',
      'Something I want to learn...',
      'My proudest achievement...',
      'A goal that excites me...',
    ],
    'Music, Movies & Culture': [
      'The song I’ll never skip...',
      'A movie I can rewatch forever...',
      'My comfort show is...',
      'The concert I wish I’d seen...',
      'My favorite festival memory...',
      'The book I keep recommending...',
      'My dream dinner guest...',
      'A playlist that describes me...',
    ],
    'Random': [
      'Two truths and a lie...',
      'My most controversial food take...',
      'The most random thing in my bag...',
      'A tiny hill I’ll die on...',
      'My hidden superpower...',
      'Something that surprised me lately...',
      'My best bad joke...',
      'An unexpected adventure I’d try...',
    ],
  };

  static const promptSectionDescriptions = <String, String>{
    'About Me': 'Basics, personality, who I am',
    'Fun & Quirky': 'Light-hearted and playful',
    'Lifestyle': 'Daily life, hobbies, interests',
    'Relationships': 'Dating preferences, love style',
    'Values & Opinions': 'Beliefs, perspectives, important things',
    'Goals & Ambitions': 'Career, growth, future plans',
    'Music, Movies & Culture': 'Taste in music, movies, shows',
    'Random': 'Unexpected, creative, anything goes',
  };

  static List<String> sectionsForFilter(String filter) => switch (filter) {
    'Fun' => ['Fun & Quirky', 'Random'],
    'Deep' => ['About Me', 'Values & Opinions', 'Goals & Ambitions'],
    'Lifestyle' => ['Lifestyle', 'Music, Movies & Culture'],
    'Relationships' => ['Relationships'],
    'Values' => ['Values & Opinions'],
    'Random' => ['Random'],
    'Creative' => ['Fun & Quirky', 'Music, Movies & Culture'],
    _ => promptSections.keys.toList(),
  };
}
