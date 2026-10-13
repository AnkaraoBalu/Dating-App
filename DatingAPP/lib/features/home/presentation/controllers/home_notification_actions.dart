part of '../screens/home_screen.dart';

// Foreground pushes appear at the top; taps open the relevant screen.
extension _HomeNotificationActions on _HomeScreenState {
  void _startPushNotifications(DiscoverApi api) {
    final push = PushNotificationsService(
      api: NotificationsApi(
        baseUrl: api.baseUrl,
        getSessionToken: api.getSessionToken,
      ),
    );
    _push = push;
    _pushOpened = push.opened.listen(
      (notification) => unawaited(_openFromNotification(notification)),
    );
    _pushForeground = push.foreground.listen((notification) {
      if (!mounted) return;
      if (notification.type == PushNotificationType.call) {
        // Shown as the incoming call screen, not a banner.
        unawaited(_showIncomingCall(notification.callId));
        return;
      }
      _inAppNotification.show(
        context,
        notification: notification,
        onTap: () => unawaited(_openFromNotification(notification)),
      );
    });
    unawaited(push.start());
  }

  Future<void> _openFromNotification(PushNotification notification) async {
    if (!mounted) return;
    if (notification.type == PushNotificationType.call) {
      // Opens on top of the current screen; a call that already ended
      // shows its chat instead, where the missed call is listed.
      final shown = CallCoordinator.instance.screenOpen;
      await _showIncomingCall(notification.callId);
      if (!mounted || shown || CallCoordinator.instance.screenOpen) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      _refresh(() => _selectedNav = 3);
      await _openConversation(notification.conversationId);
      return;
    }
    Navigator.of(context).popUntil((route) => route.isFirst);
    switch (notification.type) {
      case PushNotificationType.message:
        _refresh(() => _selectedNav = 3);
        await _openConversation(notification.conversationId);
      case PushNotificationType.match:
        _refresh(() => _selectedNav = 2);
        unawaited(_matchController?.load());
      case PushNotificationType.like:
        await _openLikes();
      case PushNotificationType.vibe:
        _refresh(() => _selectedNav = 1);
        await _openVibeRoom(notification.roomId);
      case PushNotificationType.call:
      case PushNotificationType.unknown:
        break;
    }
  }

  Future<void> _openConversation(String? conversationId) async {
    final controller = _matchController;
    if (conversationId == null || controller == null) return;
    await controller.load();
    final match = [
      ...controller.conversations,
      ...controller.matches,
    ].where((match) => match.conversationId == conversationId).firstOrNull;
    if (match == null || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ConversationScreen(
          match: match,
          api: ChatApi(
            baseUrl: controller.api.baseUrl,
            getSessionToken: controller.api.getSessionToken,
          ),
        ),
      ),
    );
  }

  /// Opens the room from a Vibe notification: straight into the chat for
  /// members, or the room page otherwise.
  Future<void> _openVibeRoom(String? roomId) async {
    final discover = widget.discoverApi;
    if (roomId == null || discover == null) return;
    final api = VibeRoomsApi(
      baseUrl: discover.baseUrl,
      getSessionToken: discover.getSessionToken,
      currentUserImage: _memberPhotos.isEmpty ? null : _memberPhotos.first,
    );
    final store = VibeRoomStore.instance;
    var room = store.rooms.where((item) => item.id == roomId).firstOrNull;
    if (room == null) {
      try {
        for (final item in await api.listRooms()) {
          store.cacheRoom(item);
        }
      } catch (_) {
        return;
      }
      room = store.rooms.where((item) => item.id == roomId).firstOrNull;
    }
    if (room == null || !mounted) return;
    final target = room;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => target.isJoined
            ? LiveVibeRoomScreen(room: target, api: api)
            : RoomDetailScreen(room: target, api: api),
      ),
    );
  }

  void _stopPushNotifications() {
    _inAppNotification.dismiss();
    unawaited(_pushForeground?.cancel());
    unawaited(_pushOpened?.cancel());
    unawaited(_push?.dispose());
  }
}
