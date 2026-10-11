part of '../screens/home_screen.dart';

// Live inbox, like and match updates for the signed-in session. Events only
// say what changed, so each one reloads the shared MatchController, which
// drives the chat list, the Chat/Matches badges and incoming likes.
extension _HomeRealtimeActions on _HomeScreenState {
  void _startRealtime(DiscoverApi api) {
    final realtime = RealtimeService(
      baseUrl: api.baseUrl,
      getSessionToken: api.getSessionToken,
    );
    _realtime = realtime;
    _realtimeEvents = realtime.events.listen(_onRealtimeEvent);
    realtime.connect();
  }

  void _onRealtimeEvent(RealtimeEvent event) {
    switch (event.type) {
      case RealtimeEventType.likeReceived:
        unawaited(_matchController?.loadIncomingLikes());
      case RealtimeEventType.inboxChanged:
      case RealtimeEventType.resynced:
        _scheduleMatchReload();
      case RealtimeEventType.matched:
        _scheduleMatchReload(
          announceMatchWith: event.initiatedByYou ? null : event.userId,
        );
    }
  }

  /// Several events often arrive together (a message updates both sides);
  /// collapse them into one reload.
  void _scheduleMatchReload({String? announceMatchWith}) {
    if (announceMatchWith != null) {
      _pendingMatchAnnouncement = announceMatchWith;
    }
    _realtimeReload?.cancel();
    _realtimeReload = Timer(const Duration(milliseconds: 300), () async {
      await _matchController?.load();
      final userId = _pendingMatchAnnouncement;
      _pendingMatchAnnouncement = null;
      if (userId != null && mounted) _announceMatch(userId);
    });
  }

  void _announceMatch(String userId) {
    final match = _matchController?.matches
        .where((match) => match.person.id == userId)
        .firstOrNull;
    if (match == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text("It's a match with ${match.person.name}!"),
          action: SnackBarAction(
            label: 'View',
            onPressed: () {
              if (mounted) _refresh(() => _selectedNav = 2);
            },
          ),
        ),
      );
  }

  void _stopRealtime() {
    _realtimeReload?.cancel();
    unawaited(_realtimeEvents?.cancel());
    unawaited(_realtime?.dispose());
  }
}
