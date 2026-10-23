import 'package:flutter/material.dart';

/// Network, asset or bundled demo photo for a discovery person, with a fallback.
abstract final class HomePersonPhoto {
  static const _demoBoys = <String>[
    'aarav',
    'vihaan',
    'kabir',
    'reyansh',
    'arjun',
    'rohan',
    'aditya',
    'ishaan',
    'dev',
    'karthik',
  ];
  static const _demoGirls = <String>[
    'maya',
    'kiara',
    'ananya',
    'meera',
    'sana',
    'ira',
    'tara',
    'nisha',
    'pooja',
    'zoya',
  ];
  static const _demoBoyAssets = <String>[
    'assets/images/boys-images/cafe_hoodie_portrait.png',
    'assets/images/boys-images/rooftop_sunset_portrait.png',
    'assets/images/boys-images/cafe_smiling_portrait.png',
    'assets/images/boys-images/sunset_jacket_portrait.png',
    'assets/images/boys-images/golden_hour_white_shirt.png',
    'assets/images/boys-images/city_night_portrait.png',
  ];
  static const _demoGirlAssets = <String>[
    'assets/images/girls-images/golden_hour_portrait.png',
    'assets/images/girls-images/cafe_coffee_portrait.png',
    'assets/images/girls-images/sunset_floral_portrait.png',
    'assets/images/girls-images/iced_coffee_portrait.png',
    'assets/images/girls-images/cozy_headphones_portrait.png',
    'assets/images/girls-images/city_night_portrait.png',
  ];

  static ImageProvider? providerFor(String image, {String? personName}) {
    final local = _localDemoPhoto(image, personName);
    if (local != null) return AssetImage(local);
    if (image.startsWith('https://') || image.startsWith('http://')) {
      return NetworkImage(image);
    }
    return image.isEmpty ? null : AssetImage(image);
  }

  static Widget imageFor(String image, {String? personName}) {
    final provider = providerFor(image, personName: personName);
    if (provider == null) return _imageFallback();
    return Image(
      image: provider,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _imageFallback(),
    );
  }

  static String? _localDemoPhoto(String image, String? personName) {
    if (Uri.tryParse(image)?.host != 'i.pravatar.cc') return null;
    final name = personName?.trim().toLowerCase();
    if (name == null) return null;
    final isBoy = _demoBoys.indexOf(name);
    final isGirl = _demoGirls.indexOf(name);
    if (isBoy < 0 && isGirl < 0) return null;

    final assets = isBoy >= 0 ? _demoBoyAssets : _demoGirlAssets;
    final profileIndex = isBoy >= 0 ? isBoy : isGirl;
    final firstAvatarId = isBoy >= 0 ? 12 + profileIndex : 22 + profileIndex;
    final avatarId = int.tryParse(
      Uri.tryParse(image)?.queryParameters['img'] ?? '',
    );
    final photoIndex = avatarId == null
        ? 0
        : ((avatarId - firstAvatarId + 70) % 70) ~/ 10;
    return assets[(profileIndex + photoIndex) % assets.length];
  }

  static Widget _imageFallback() => const ColoredBox(
    color: Color(0xFF24322F),
    child: Center(
      child: Icon(Icons.person_rounded, size: 54, color: Colors.white54),
    ),
  );
}
