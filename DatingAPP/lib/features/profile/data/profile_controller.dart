import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../profile_setup/data/profile_setup_api.dart';
import '../../onboarding/data/onboarding_api.dart';
import '../models/member_profile.dart';

class ProfileController extends ChangeNotifier {
  ProfileController({
    required this.baseUrl,
    required this.getSessionToken,
    OnboardingApi? onboardingApi,
    ProfileSetupApi? profileApi,
  }) : api =
           profileApi ??
           ProfileSetupApi(baseUrl: baseUrl, getSessionToken: getSessionToken),
       onboardingApi =
           onboardingApi ??
           OnboardingApi(baseUrl: baseUrl, getSessionToken: getSessionToken);
  final String baseUrl;
  final Future<String> Function() getSessionToken;
  final ProfileSetupApi api;
  final OnboardingApi onboardingApi;
  MemberProfile? profile;
  Map<String, dynamic> insights = {};
  bool loading = false;
  bool saving = false;
  String? error;
  bool _disposed = false;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load() async {
    loading = true;
    error = null;
    _notify();
    try {
      final results = await Future.wait<Object>([
        api.load().then((data) {
          profile = MemberProfile(data);
          _notify();
          return data;
        }),
        request('GET', '/profile/insights').catchError((Object error) {
          debugPrint('[Profile] Could not load insights: $error');
          return <String, dynamic>{};
        }),
      ]);
      profile = MemberProfile(results[0] as Map<String, dynamic>);
      insights = results[1] as Map<String, dynamic>;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      _notify();
    }
  }

  Future<Map<String, dynamic>> request(
    String method,
    String path, [
    Map<String, Object?>? body,
  ]) async {
    final request = http.Request(method, Uri.parse('$baseUrl$path'))
      ..headers.addAll({
        'Authorization': 'Bearer ${await getSessionToken()}',
        'Content-Type': 'application/json',
      });
    if (body != null) request.body = jsonEncode(body);
    final response = await http.Response.fromStream(
      await request.send().timeout(const Duration(seconds: 20)),
    );
    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(decoded is Map ? decoded['message'] : 'Request failed.');
    }
    return decoded as Map<String, dynamic>;
  }

  Future<void> _save(
    Future<void> Function() action, {
    bool reloadProfile = true,
  }) async {
    if (saving) throw StateError('A profile update is already in progress.');
    saving = true;
    _notify();
    try {
      await action();
      if (reloadProfile) profile = MemberProfile(await api.load());
    } finally {
      saving = false;
      _notify();
    }
  }

  Future<void> update(Map<String, Object?> changes) => _save(() async {
    await api.update(changes);
  });
  Future<void> updateOnboarding(
    Map<String, Object?> changes,
  ) => _save(() async {
    await onboardingApi.update(changes);
    // The write has succeeded. Publish the confirmed values without depending
    // on a second request that could fail and leave discovery using old values.
    final current = profile;
    if (current != null) {
      profile = MemberProfile({
        ...current.data,
        'user': {
          ...current.user,
          'onboardingProfile': {...current.onboarding, ...changes},
        },
      });
    }
  }, reloadProfile: profile == null);

  /// Permanently deletes the account on the server (data, photos, login).
  Future<void> deleteAccount() => request('DELETE', '/users/me');
  Future<void> updateName(String username) => _save(() async {
    await request('PATCH', '/users/me/name', {'username': username.trim()});
  });
  Future<void> savePrompts(List<Map<String, String>> prompts) =>
      _save(() async {
        await api.savePrompts(prompts);
      });
  Future<void> addPhoto(File file) => _save(() async {
    await api.uploadPhoto(file);
  });
  Future<void> deletePhoto(String id) => _save(() async {
    await api.deletePhoto(id);
  });
  Future<void> makeMain(String id) => _save(() async {
    final ids = profile!.photos.map((p) => p.id).toList()..remove(id);
    await api.reorderPhotos([id, ...ids]);
  });
  Future<void> replacePhoto(String id, Uint8List bytes) => _save(() async {
    final request =
        http.MultipartRequest('PUT', Uri.parse('$baseUrl/profile/photos/$id'))
          ..headers['Authorization'] = 'Bearer ${await getSessionToken()}'
          ..files.add(
            http.MultipartFile.fromBytes(
              'file',
              bytes,
              filename: 'profile.png',
            ),
          );
    final response = await http.Response.fromStream(
      await request.send().timeout(const Duration(seconds: 60)),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = jsonDecode(response.body);
      throw Exception(body['message'] ?? 'Could not save photo.');
    }
  });
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
