import 'package:shared_preferences/shared_preferences.dart';

/// A replay round is scoped to a backend and member, never the whole device.
class DiscoveryRoundStore {
  DiscoveryRoundStore({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _preferences;
  String _key(String backend, String memberId) =>
      'discovery_round_v1:${Uri.encodeComponent(backend)}:${Uri.encodeComponent(memberId)}';

  Future<String?> load(String backend, String memberId) async {
    final raw = await _preferences.getString(_key(backend, memberId));
    final date = raw == null ? null : DateTime.tryParse(raw);
    if (date == null || date.isAfter(DateTime.now().toUtc())) return null;
    return date.toUtc().toIso8601String();
  }

  Future<void> save(String backend, String memberId, String cutoff) =>
      _preferences.setString(_key(backend, memberId), cutoff);
}
