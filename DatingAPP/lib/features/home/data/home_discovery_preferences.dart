import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Profile verification is hidden until it ships, so no one is verified yet
/// and a "verified only" filter would empty the feed.
const verifiedFilterAvailable = false;

class HomeDiscoveryPreferences {
  const HomeDiscoveryPreferences({
    this.selectedVibeIds = const {},
    this.minAge = 21,
    this.maxAge = 34,
    this.interest,
    this.interests = const [],
    this.onlineOnly = false,
    this.verifiedOnly = false,
    this.selectedInterest,
    this.travelLocation,
  });

  final Set<String> selectedVibeIds;
  final int minAge;
  final int maxAge;
  final String? interest;
  final List<String> interests;
  final bool onlineOnly;
  final bool verifiedOnly;
  final String? selectedInterest;
  final String? travelLocation;
}

class HomeDiscoveryPreferencesStore {
  HomeDiscoveryPreferencesStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _storageKey = 'home_discovery_preferences_v1';

  final SharedPreferencesAsync _preferences;

  Future<HomeDiscoveryPreferences> load() async {
    final raw = await _preferences.getString(_storageKey);
    if (raw == null || raw.isEmpty) return const HomeDiscoveryPreferences();

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return const HomeDiscoveryPreferences();
      }

      final minAge = _readInt(decoded['minAge'], 21).clamp(18, 70).toInt();
      final maxAge = _readInt(decoded['maxAge'], 34).clamp(minAge, 70).toInt();
      final rawVibes = decoded['selectedVibeIds'];
      final rawInterests = decoded['interests'];

      return HomeDiscoveryPreferences(
        selectedVibeIds: rawVibes is List
            ? rawVibes.whereType<String>().toSet()
            : const {},
        minAge: minAge,
        maxAge: maxAge,
        interest: _readOptionalString(decoded['interest']),
        interests: rawInterests is List
            ? rawInterests.whereType<String>().toList()
            : const [],
        onlineOnly: decoded['onlineOnly'] == true,
        verifiedOnly:
            verifiedFilterAvailable && decoded['verifiedOnly'] == true,
        selectedInterest: _readOptionalString(decoded['selectedInterest']),
        travelLocation: _readOptionalString(decoded['travelLocation']),
      );
    } on FormatException {
      return const HomeDiscoveryPreferences();
    }
  }

  Future<void> save(HomeDiscoveryPreferences preferences) async {
    await _preferences.setString(
      _storageKey,
      jsonEncode({
        'selectedVibeIds': preferences.selectedVibeIds.toList(),
        'minAge': preferences.minAge,
        'maxAge': preferences.maxAge,
        'interest': preferences.interest,
        'interests': preferences.interests,
        'onlineOnly': preferences.onlineOnly,
        'verifiedOnly': preferences.verifiedOnly,
        'selectedInterest': preferences.selectedInterest,
        'travelLocation': preferences.travelLocation,
      }),
    );
  }

  static int _readInt(Object? value, int fallback) =>
      value is num ? value.round() : fallback;

  static String? _readOptionalString(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
