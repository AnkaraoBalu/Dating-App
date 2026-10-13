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
      case RealtimeEventType.matched:
        // The match itself is announced by its push notification.
        _scheduleMatchReload();
      case RealtimeEventType.callIncoming:
        unawaited(_showIncomingCall(event.callId));
      case RealtimeEventType.callUpdated:
        final callId = event.callId;
        final status = event.callStatus;
        if (callId != null && status != null) {
          CallCoordinator.instance.publish(VoiceCallUpdate(callId, status));
        }
    }
  }

  /// Several events often arrive together (a message updates both sides);
  /// collapse them into one reload.
  void _scheduleMatchReload() {
    _realtimeReload?.cancel();
    _realtimeReload = Timer(
      const Duration(milliseconds: 300),
      () => unawaited(_matchController?.load()),
    );
  }

  void _stopRealtime() {
    _realtimeReload?.cancel();
    unawaited(_realtimeEvents?.cancel());
    unawaited(_realtime?.dispose());
  }
}
