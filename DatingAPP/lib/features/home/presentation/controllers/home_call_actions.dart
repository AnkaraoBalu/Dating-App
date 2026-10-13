part of '../screens/home_screen.dart';

// Incoming one-to-one voice calls. A call can arrive both as a live
// `call:incoming` event and as a push; CallCoordinator makes sure only one
// incoming call screen opens, on top of whatever is on screen.
extension _HomeCallActions on _HomeScreenState {
  Future<void> _showIncomingCall(String? callId) async {
    final discover = widget.discoverApi;
    final coordinator = CallCoordinator.instance;
    if (callId == null || discover == null) return;
    if (coordinator.screenOpen || coordinator.activeCallId == callId) return;
    final api = CallsApi(
      baseUrl: discover.baseUrl,
      getSessionToken: discover.getSessionToken,
    );
    final VoiceCall call;
    try {
      call = await api.get(callId);
    } catch (_) {
      return;
    }
    if (!mounted || !call.isRinging || call.isCaller) return;
    if (coordinator.screenOpen || coordinator.activeCallId == callId) return;
    // Claimed before the route builds, so a second trigger cannot race it.
    coordinator
      ..screenOpen = true
      ..activeCallId = callId;
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => VoiceCallScreen.incoming(api: api, call: call),
      ),
    );
  }
}
