import 'dart:async';

import 'package:flutter/foundation.dart';
import '../../home/data/discover_api.dart';

import 'match_api.dart';
import '../models/match_model.dart';

class MatchController extends ChangeNotifier {
  MatchController({required this.api, DiscoverApi? discoverApi})
    : discoverApi =
          discoverApi ??
          DiscoverApi(
            baseUrl: api.baseUrl,
            getSessionToken: api.getSessionToken,
          ),
      _ownsDiscoverApi = discoverApi == null;

  final MatchApi api;
  final DiscoverApi discoverApi;
  final bool _ownsDiscoverApi;
  List<MatchRecord> matches = const [];
  List<MatchRecord> conversations = const [];
  List<MatchRecord> incomingLikes = const [];
  bool usingDemoData = false;
  bool loading = false;
  bool incomingLikesLoading = false;
  String? error;
  String? incomingLikesError;
  bool _disposed = false;
  int _incomingLikesRequest = 0;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load({String? query}) async {
    if (query == null) loading = true;
    error = null;
    _notify();
    try {
      final loaded = await Future.wait([
        api.loadMatches(query: query),
        api.loadConversations(query: query),
      ]);
      matches = loaded[0];
      conversations = loaded[1];
      usingDemoData = false;
    } catch (exception) {
      error = exception.toString();
      if (query == null) {
        matches = const [];
        conversations = const [];
      }
      usingDemoData = false;
    } finally {
      loading = false;
      _notify();
    }
    if (query == null) unawaited(loadIncomingLikes());
  }

  Future<void> loadIncomingLikes() async {
    final requestId = ++_incomingLikesRequest;
    incomingLikesLoading = true;
    incomingLikesError = null;
    _notify();
    try {
      final loaded = await api.loadIncomingLikes();
      if (_disposed || requestId != _incomingLikesRequest) return;
      incomingLikes = loaded;
    } catch (exception) {
      if (_disposed || requestId != _incomingLikesRequest) return;
      incomingLikesError = exception.toString();
    } finally {
      if (!_disposed && requestId == _incomingLikesRequest) {
        incomingLikesLoading = false;
        _notify();
      }
    }
  }

  Future<bool> like(String userId) => discoverApi.like(userId);

  Future<String?> loadCurrentUserImage() => api.loadCurrentUserImage();

  Future<bool> likeIncoming(MatchRecord incoming) => like(incoming.person.id);

  Future<void> markConversationRead(String conversationId) =>
      api.markConversationRead(conversationId);

  @override
  void dispose() {
    _disposed = true;
    if (_ownsDiscoverApi) discoverApi.dispose();
    super.dispose();
  }
}
