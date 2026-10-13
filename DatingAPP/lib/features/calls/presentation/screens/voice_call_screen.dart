import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

import '../../../../core/theme/theme.dart';
import '../../../chat/presentation/widgets/chat_media.dart';
import '../../data/call_coordinator.dart';
import '../../data/calls_api.dart';
import '../../models/voice_call.dart';

enum _Phase { starting, ringing, incoming, connecting, connected, ended }

/// A one-to-one voice call: calling, incoming, connected and ended, on one
/// screen. Audio is a two-person LiveKit room; the call's status comes from
/// live `call:updated` events (via [CallCoordinator]) with polling as backup.
class VoiceCallScreen extends StatefulWidget {
  /// Starts a call to the other member of [conversationId].
  const VoiceCallScreen.outgoing({
    super.key,
    required this.api,
    required String this.conversationId,
    required this.peerName,
    required this.peerAvatar,
  }) : incomingCall = null;

  /// Shows a ringing call with Accept and Decline.
  VoiceCallScreen.incoming({
    super.key,
    required this.api,
    required VoiceCall call,
  }) : incomingCall = call,
       conversationId = call.conversationId,
       peerName = call.peerName,
       peerAvatar = call.peerAvatar;

  final CallsApi api;
  final VoiceCall? incomingCall;
  final String? conversationId;
  final String peerName;
  final String peerAvatar;

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen> {
  final _coordinator = CallCoordinator.instance;
  final _ringtone = FlutterRingtonePlayer();
  StreamSubscription<VoiceCallUpdate>? _updates;
  lk.Room? _room;
  lk.EventsListener<lk.RoomEvent>? _roomEvents;
  VoiceCall? _call;
  _Phase _phase = _Phase.starting;
  String _endedLabel = 'Call ended';
  DateTime? _connectedAt;
  Timer? _clock;
  Timer? _poll;
  Timer? _peerGone;
  bool _micOn = true;
  bool _speakerOn = false;
  bool _busy = false;
  bool _ringing = false;
  bool _accepted = false;
  bool _audioReady = false;
  bool _enablingAudio = false;
  bool _togglingMic = false;
  bool _polling = false;
  Timer? _connectionTimeout;

  @override
  void initState() {
    super.initState();
    _coordinator.screenOpen = true;
    _updates = _coordinator.updates.listen((update) {
      if (update.callId == _call?.id) _applyStatus(update.status);
    });
    final incoming = widget.incomingCall;
    if (incoming == null) {
      unawaited(_startOutgoing());
    } else {
      _call = incoming;
      _coordinator.activeCallId = incoming.id;
      _phase = _Phase.incoming;
      unawaited(_startRingtone());
      _startPolling();
    }
  }

  @override
  void dispose() {
    _coordinator.screenOpen = false;
    if (_coordinator.activeCallId == _call?.id) {
      _coordinator.activeCallId = null;
    }
    final call = _call;
    if (call != null && _phase != _Phase.ended) {
      // Closed some other way (for example by the system): hang up.
      unawaited(widget.api.end(call.id).catchError((_) => call));
    }
    unawaited(_updates?.cancel());
    _connectionTimeout?.cancel();
    _clock?.cancel();
    _poll?.cancel();
    _peerGone?.cancel();
    unawaited(_stopRingtone());
    unawaited(_releaseRoom());
    super.dispose();
  }

  Future<void> _startOutgoing() async {
    try {
      final call = await widget.api.start(widget.conversationId!);
      if (!mounted || _phase == _Phase.ended) {
        unawaited(widget.api.end(call.id).catchError((_) => call));
        return;
      }
      _call = call;
      _coordinator.activeCallId = call.id;
      setState(() => _phase = _Phase.ringing);
      _startPolling();
      // Join the audio room now so the call connects the moment it's answered.
      await _connectAudio(call);
    } on CallException catch (error) {
      _endFailedCall();
      _finish(error.busy ? error.message : 'Could not start the call.');
    } catch (_) {
      _endFailedCall();
      _finish('Could not start the call. Check your connection.');
    }
  }

  Future<void> _accept() async {
    final call = _call;
    if (call == null || _busy) return;
    _busy = true;
    await _stopRingtone();
    if (!mounted || _phase == _Phase.ended) return;
    setState(() => _phase = _Phase.connecting);
    try {
      final joined = await widget.api.accept(call.id);
      if (!mounted || _phase == _Phase.ended) {
        unawaited(widget.api.end(call.id).catchError((_) => call));
        return;
      }
      _call = joined;
      _onAccepted();
      await _connectAudio(joined);
      if (!mounted || _phase == _Phase.ended) return;
      await _activateAudio();
    } on CallException catch (error) {
      _endFailedCall();
      _finish(error.message);
    } catch (_) {
      unawaited(widget.api.end(call.id).catchError((_) => call));
      _finish('Could not connect the call.');
    } finally {
      _busy = false;
    }
  }

  Future<void> _decline() async {
    final call = _call;
    if (call == null) return;
    _finish('Call declined');
    try {
      await widget.api.decline(call.id);
    } catch (_) {
      // The call times out as missed on the server anyway.
    }
  }

  Future<void> _hangUp() async {
    final call = _call;
    _finish(_phase == _Phase.ringing ? 'Call cancelled' : 'Call ended');
    if (call == null) return;
    try {
      await widget.api.end(call.id);
    } catch (_) {
      // The server ends calls whose audio room is empty.
    }
  }

  void _applyStatus(String status) {
    if (_phase == _Phase.ended) return;
    switch (status) {
      case 'ringing':
        return;
      case 'accepted':
        if (_phase == _Phase.ringing) {
          _onAccepted();
          unawaited(_activateAudio());
        } else if (_phase == _Phase.incoming) {
          _finish('Answered on another device');
        }
      case 'declined':
        _finish(_call?.isCaller == true ? 'Call declined' : 'Call ended');
      case 'missed':
        _finish(_call?.isCaller == true ? 'No answer' : 'Missed call');
      case 'cancelled':
        _finish(_call?.isCaller == true ? 'Call cancelled' : 'Missed call');
      default:
        _finish('Call ended');
    }
  }

  void _endFailedCall() {
    final call = _call;
    if (call != null) {
      unawaited(widget.api.end(call.id).catchError((_) => call));
    }
  }

  void _onAccepted() {
    if (_accepted) return;
    _accepted = true;
    setState(() => _phase = _Phase.connecting);
    _connectionTimeout = Timer(const Duration(seconds: 30), () {
      _endFailedCall();
      _finish("Could not connect the call. Please try again.");
    });
  }

  Future<void> _activateAudio() async {
    final room = _room;
    if (!mounted ||
        !_accepted ||
        !_audioReady ||
        _enablingAudio ||
        _phase == _Phase.ended ||
        _phase == _Phase.connected ||
        room == null ||
        room.remoteParticipants.isEmpty) {
      return;
    }
    _enablingAudio = true;
    try {
      await room.localParticipant?.setMicrophoneEnabled(true);
      if (mounted && _room == room && _phase != _Phase.ended) {
        _markConnected();
      }
    } catch (_) {
      _endFailedCall();
      _finish("Could not access your microphone. Check app permissions.");
    } finally {
      _enablingAudio = false;
    }
  }

  void _markConnected() {
    if (_phase == _Phase.connected || _phase == _Phase.ended) return;
    _connectionTimeout?.cancel();
    _connectedAt = DateTime.now();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    setState(() => _phase = _Phase.connected);
  }

  void _finish(String label) {
    if (_phase == _Phase.ended || !mounted) return;
    _connectionTimeout?.cancel();
    _clock?.cancel();
    _poll?.cancel();
    _peerGone?.cancel();
    unawaited(_stopRingtone());
    unawaited(_releaseRoom());
    setState(() {
      _phase = _Phase.ended;
      _endedLabel = label;
    });
    Future<void>.delayed(const Duration(milliseconds: 1600), () {
      if (mounted && ModalRoute.of(context)?.isCurrent == true) {
        Navigator.of(context).maybePop();
      }
    });
  }

  /// Backup for missed live events throughout the call.
  void _startPolling() {
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 3), (_) async {
      final call = _call;
      if (call == null || _phase == _Phase.ended || _polling) return;
      _polling = true;
      try {
        final latest = await widget.api.get(call.id);
        if (mounted) _applyStatus(latest.status);
      } catch (_) {
        // Try again on the next tick.
      } finally {
        _polling = false;
      }
    });
  }

  Future<void> _connectAudio(VoiceCall call) async {
    if (!mounted || _phase == _Phase.ended) return;
    final serverUrl = call.serverUrl;
    final token = call.participantToken;
    if (serverUrl == null || token == null) {
      throw const FormatException('Missing call audio details.');
    }
    final room = lk.Room();
    _room = room;
    final events = room.createListener();
    _roomEvents = events;
    events
      ..on<lk.ParticipantConnectedEvent>((_) {
        _peerGone?.cancel();
        unawaited(_activateAudio());
      })
      ..on<lk.ParticipantDisconnectedEvent>((_) {
        if (_phase != _Phase.connected) return;
        // Give them a moment to come back (e.g. switching networks).
        _peerGone?.cancel();
        _peerGone = Timer(const Duration(seconds: 15), _hangUp);
      })
      ..on<lk.RoomReconnectingEvent>((_) => _refresh())
      ..on<lk.RoomReconnectedEvent>((_) => _refresh())
      ..on<lk.RoomDisconnectedEvent>((event) {
        if (_room != room || _phase == _Phase.ended) return;
        if (event.reason == lk.DisconnectReason.roomDeleted) {
          _finish('Call ended');
        } else {
          unawaited(_hangUp());
        }
      });
    await room.connect(serverUrl, token);
    if (!mounted || _room != room) return;
    _audioReady = true;
    await _activateAudio();
    if (!mounted || _room != room) return;
    try {
      await lk.AudioManager.instance.setSpeakerOutputPreferred(false);
    } catch (_) {
      // Audio still plays through the current output.
    }
  }

  Future<void> _releaseRoom() async {
    final events = _roomEvents;
    final room = _room;
    _roomEvents = null;
    _room = null;
    _audioReady = false;
    await events?.dispose();
    if (room == null) return;
    try {
      await room.disconnect();
    } catch (_) {
      // Already disconnected.
    }
    await room.dispose();
  }

  Future<void> _toggleMic() async {
    final participant = _room?.localParticipant;
    if (participant == null || _phase != _Phase.connected || _togglingMic) {
      return;
    }
    _togglingMic = true;
    final next = !participant.isMicrophoneEnabled();
    try {
      await participant.setMicrophoneEnabled(next);
      if (mounted) setState(() => _micOn = next);
    } catch (_) {
      _notice('Could not access your microphone. Check app permissions.');
    } finally {
      _togglingMic = false;
    }
  }

  Future<void> _toggleSpeaker() async {
    final next = !_speakerOn;
    try {
      await lk.AudioManager.instance.setSpeakerOutputPreferred(next);
      if (mounted) setState(() => _speakerOn = next);
    } catch (_) {
      _notice('Could not change the audio output.');
    }
  }

  Future<void> _startRingtone() async {
    try {
      await _ringtone.playRingtone(looping: true);
      _ringing = true;
      if (!mounted || _phase != _Phase.incoming) await _stopRingtone();
    } catch (_) {
      // The incoming screen is still shown without sound.
    }
  }

  Future<void> _stopRingtone() async {
    if (!_ringing) return;
    _ringing = false;
    try {
      await _ringtone.stop();
    } catch (_) {
      // Nothing playing.
    }
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _notice(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String get _statusLabel => switch (_phase) {
    _Phase.starting => 'Calling…',
    _Phase.ringing => 'Ringing…',
    _Phase.incoming => 'Incoming voice call',
    _Phase.connecting => 'Connecting…',
    _Phase.connected =>
      _room?.connectionState == lk.ConnectionState.reconnecting
          ? 'Reconnecting…'
          : _elapsed,
    _Phase.ended => _endedLabel,
  };

  String get _elapsed {
    final started = _connectedAt;
    if (started == null) return '0:00';
    final seconds = DateTime.now().difference(started).inSeconds;
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final rest = (seconds % 60).toString().padLeft(2, '0');
    return hours > 0
        ? '$hours:${minutes.toString().padLeft(2, '0')}:$rest'
        : '$minutes:$rest';
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _phase == _Phase.ended,
    onPopInvokedWithResult: (didPop, _) {
      if (didPop) return;
      if (_phase == _Phase.incoming) {
        unawaited(_decline());
      } else {
        unawaited(_hangUp());
      }
    },
    child: Scaffold(
      backgroundColor: AppColors.forestDeep,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),
            _Avatar(
              image: widget.peerAvatar,
              pulsing:
                  _phase == _Phase.ringing ||
                  _phase == _Phase.incoming ||
                  _phase == _Phase.starting,
            ),
            const SizedBox(height: 22),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                widget.peerName,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.h2.copyWith(color: AppColors.textOnDark),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _statusLabel,
              style: AppTypography.body.copyWith(
                color: AppColors.textOnDark.withValues(alpha: .75),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const Spacer(flex: 3),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 36),
              child: _controls(),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _controls() {
    switch (_phase) {
      case _Phase.ended:
        return const SizedBox(height: 96);
      case _Phase.incoming:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _CallButton(
              icon: Icons.call_end_rounded,
              label: 'Decline',
              color: AppColors.error,
              onTap: () => unawaited(_decline()),
            ),
            _CallButton(
              icon: Icons.call_rounded,
              label: 'Accept',
              color: AppColors.success,
              onTap: () => unawaited(_accept()),
            ),
          ],
        );
      case _Phase.starting:
      case _Phase.ringing:
      case _Phase.connecting:
      case _Phase.connected:
        final live = _phase == _Phase.connected || _phase == _Phase.ringing;
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _CallButton(
              icon: _micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
              label: _micOn ? 'Mute' : 'Unmute',
              color: _micOn ? Colors.white24 : Colors.white,
              iconColor: _micOn ? Colors.white : AppColors.forestDeep,
              onTap: live ? () => unawaited(_toggleMic()) : null,
            ),
            _CallButton(
              icon: Icons.call_end_rounded,
              label: 'End',
              color: AppColors.error,
              onTap: () => unawaited(_hangUp()),
            ),
            _CallButton(
              icon: _speakerOn
                  ? Icons.volume_up_rounded
                  : Icons.volume_down_rounded,
              label: 'Speaker',
              color: _speakerOn ? Colors.white : Colors.white24,
              iconColor: _speakerOn ? AppColors.forestDeep : Colors.white,
              onTap: live ? () => unawaited(_toggleSpeaker()) : null,
            ),
          ],
        );
    }
  }
}

class _Avatar extends StatefulWidget {
  const _Avatar({required this.image, required this.pulsing});

  final String image;
  final bool pulsing;

  @override
  State<_Avatar> createState() => _AvatarState();
}

class _AvatarState extends State<_Avatar> with SingleTickerProviderStateMixin {
  late final _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    if (widget.pulsing) _pulse.repeat();
  }

  @override
  void didUpdateWidget(_Avatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulsing && !_pulse.isAnimating) {
      _pulse.repeat();
    } else if (!widget.pulsing && _pulse.isAnimating) {
      _pulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 190,
    height: 190,
    child: Stack(
      alignment: Alignment.center,
      children: [
        AnimatedBuilder(
          animation: _pulse,
          builder: (context, _) => Container(
            width: 128 + 60 * _pulse.value,
            height: 128 + 60 * _pulse.value,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.coral.withValues(
                alpha: .35 * (1 - _pulse.value),
              ),
            ),
          ),
        ),
        ClipOval(
          child: SizedBox(
            width: 128,
            height: 128,
            child: widget.image.isEmpty
                ? const ColoredBox(
                    color: AppColors.darkSurface2,
                    child: Icon(Icons.person, size: 64, color: Colors.white54),
                  )
                : chatPhoto(widget.image),
          ),
        ),
      ],
    ),
  );
}

class _CallButton extends StatelessWidget {
  const _CallButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.iconColor = Colors.white,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: onTap == null ? .45 : 1,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: color,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 68,
              height: 68,
              child: Icon(icon, color: iconColor, size: 30),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTypography.caption.copyWith(color: AppColors.textOnDark),
        ),
      ],
    ),
  );
}
