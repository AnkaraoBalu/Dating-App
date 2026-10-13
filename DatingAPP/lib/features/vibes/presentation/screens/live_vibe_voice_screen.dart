import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

import '../../../../core/theme/theme.dart';
import '../../data/vibe_rooms_api.dart';
import '../../models/vibe_room.dart';
import '../widgets/vibe_room_widgets.dart';

enum _VoiceConnectionStatus { connecting, connected, reconnecting, failed }

class LiveVibeVoiceScreen extends StatefulWidget {
  const LiveVibeVoiceScreen({
    super.key,
    required this.room,
    required this.onLeave,
    required this.onOpenPeople,
    required this.onOpenGames,
    this.api,
    this.leaving = false,
  });

  final VibeRoom room;
  final VibeRoomsApi? api;
  final VoidCallback onLeave;
  final VoidCallback onOpenPeople;
  final VoidCallback onOpenGames;
  final bool leaving;

  @override
  State<LiveVibeVoiceScreen> createState() => _LiveVibeVoiceScreenState();
}

class _LiveVibeVoiceScreenState extends State<LiveVibeVoiceScreen> {
  lk.Room? _liveKitRoom;
  lk.EventsListener<lk.RoomEvent>? _roomEvents;
  VibeVoiceCredentials? _credentials;
  _VoiceConnectionStatus _status = _VoiceConnectionStatus.connecting;
  String? _errorMessage;
  bool _connecting = false;
  bool _togglingMic = false;
  bool _speakerPreferred = true;

  /// Read from LiveKit so a host mute or a reconnect shows up here too.
  bool get _micEnabled =>
      _liveKitRoom?.localParticipant?.isMicrophoneEnabled() ?? false;

  bool get _isHost => _credentials?.role.toLowerCase() == 'host';

  @override
  void initState() {
    super.initState();
    unawaited(_connect());
  }

  @override
  void dispose() {
    unawaited(_releaseRoom());
    super.dispose();
  }

  Future<void> _connect() async {
    final api = widget.api;
    if (_connecting) return;
    if (api == null) {
      setState(() {
        _status = _VoiceConnectionStatus.failed;
        _errorMessage =
            'Audio is unavailable here. Go back and reopen the joined room.';
      });
      return;
    }
    _connecting = true;
    if (mounted) {
      setState(() {
        _status = _VoiceConnectionStatus.connecting;
        _errorMessage = null;
      });
    }

    try {
      await _releaseRoom();
      if (!mounted) return;
      final credentials = await api.createVoiceToken(widget.room.id);
      if (!mounted) return;
      final liveKitRoom = lk.Room();
      _credentials = credentials;
      _liveKitRoom = liveKitRoom;
      liveKitRoom.addListener(_refreshRoomState);
      final events = liveKitRoom.createListener();
      _roomEvents = events;
      events
        ..on<lk.RoomReconnectingEvent>(
          (_) => _setStatus(_VoiceConnectionStatus.reconnecting),
        )
        ..on<lk.RoomResumingEvent>(
          (_) => _setStatus(_VoiceConnectionStatus.reconnecting),
        )
        ..on<lk.RoomReconnectedEvent>(
          (_) => _setStatus(_VoiceConnectionStatus.connected),
        )
        ..on<lk.RoomDisconnectedEvent>((event) {
          if (mounted && _liveKitRoom == liveKitRoom) {
            setState(() {
              _status = _VoiceConnectionStatus.failed;
              _errorMessage = _disconnectMessage(event.reason);
            });
          }
        })
        ..on<lk.TrackMutedEvent>((event) {
          // The host muted us from the server; tell the user why.
          if (event.participant is lk.LocalParticipant &&
              event.publication.source == lk.TrackSource.microphone &&
              !_togglingMic &&
              mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('The host muted your mic.')),
            );
          }
        });

      await liveKitRoom.connect(
        credentials.serverUrl,
        credentials.participantToken,
      );
      if (!mounted || _liveKitRoom != liveKitRoom) return;
      try {
        await lk.AudioManager.instance.setSpeakerOutputPreferred(true);
      } catch (_) {
        // Audio still works through the system's current output route.
      }
      if (!mounted || _liveKitRoom != liveKitRoom) return;
      setState(() {
        _status = _VoiceConnectionStatus.connected;
        _speakerPreferred = true;
      });
    } catch (error) {
      await _releaseRoom();
      if (mounted) {
        setState(() {
          _status = _VoiceConnectionStatus.failed;
          _errorMessage = _friendlyError(error);
        });
      }
    } finally {
      _connecting = false;
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    if (message.toLowerCase().contains('not configured')) {
      return 'Voice is not configured on the server yet. Check the LiveKit settings.';
    }
    if (message.toLowerCase().contains('join this vibe room')) {
      return 'Join this room before starting its voice chat.';
    }
    if (message.toLowerCase().contains('401') ||
        message.toLowerCase().contains('unauthorized')) {
      return 'Your sign-in expired. Sign in again, then rejoin the room.';
    }
    return 'Could not connect to live audio. Check your connection and retry.';
  }

  String _disconnectMessage(lk.DisconnectReason? reason) => switch (reason) {
    lk.DisconnectReason.participantRemoved =>
      'You left this room, so your voice connection ended.',
    lk.DisconnectReason.duplicateIdentity =>
      'You joined this voice room on another device.',
    lk.DisconnectReason.roomDeleted => 'This voice room has ended.',
    _ => 'The audio connection ended. Try reconnecting.',
  };

  void _setStatus(_VoiceConnectionStatus status) {
    if (!mounted) return;
    setState(() => _status = status);
  }

  void _refreshRoomState() {
    if (mounted) setState(() {});
  }

  Future<void> _releaseRoom() async {
    final events = _roomEvents;
    final room = _liveKitRoom;
    _roomEvents = null;
    _liveKitRoom = null;
    if (events != null) await events.dispose();
    if (room == null) return;
    room.removeListener(_refreshRoomState);
    try {
      await room.disconnect();
    } catch (_) {
      // A failed or partially opened connection may already be disconnected.
    }
    await room.dispose();
  }

  Future<void> _toggleMicrophone() async {
    final participant = _liveKitRoom?.localParticipant;
    if (_status != _VoiceConnectionStatus.connected || participant == null) {
      return;
    }
    if (_togglingMic) return;
    _togglingMic = true;
    try {
      await participant.setMicrophoneEnabled(!_micEnabled);
      if (mounted) setState(() {});
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not access your microphone. Check app permissions.',
            ),
          ),
        );
      }
    } finally {
      _togglingMic = false;
    }
  }

  Future<void> _showParticipantActions(_VoiceParticipant participant) async {
    final api = widget.api;
    if (!_isHost || participant.isMe || api == null) return;
    final mute = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: VibeRoomAvatar(image: participant.avatar, size: 40),
              title: Text(
                participant.name,
                style: AppTypography.label.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            ListTile(
              enabled: !participant.muted,
              leading: const Icon(Icons.mic_off_rounded),
              title: Text(participant.muted ? 'Mic already off' : 'Mute mic'),
              onTap: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      ),
    );
    if (mute != true) return;
    try {
      await api.muteVoiceParticipant(widget.room.id, participant.identity);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not mute ${participant.name}.')),
        );
      }
    }
  }

  Future<void> _toggleSpeaker() async {
    final preferred = !_speakerPreferred;
    try {
      await lk.AudioManager.instance.setSpeakerOutputPreferred(preferred);
      if (mounted) setState(() => _speakerPreferred = preferred);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not change the audio output.')),
        );
      }
    }
  }

  List<_VoiceParticipant> _participants() {
    final room = _liveKitRoom;
    if (_status != _VoiceConnectionStatus.connected || room == null) {
      return const [];
    }
    final result = <_VoiceParticipant>[];
    final local = room.localParticipant;
    final credentials = _credentials;
    if (local != null && credentials != null) {
      result.add(
        _participantView(
          identity: local.identity,
          name: credentials.name,
          avatar: credentials.avatar,
          role: credentials.role,
          speaking: local.isSpeaking,
          muted: local.isMuted,
          isMe: true,
        ),
      );
    }
    for (final participant in room.remoteParticipants.values) {
      final metadata = _metadata(participant.metadata);
      result.add(
        _participantView(
          identity: participant.identity,
          name: participant.name,
          avatar: metadata['avatar']?.toString() ?? '',
          role: metadata['role']?.toString() ?? '',
          speaking: participant.isSpeaking,
          muted: participant.isMuted,
          isMe: false,
        ),
      );
    }
    return result;
  }

  _VoiceParticipant _participantView({
    required String identity,
    required String name,
    required String avatar,
    required String role,
    required bool speaking,
    required bool muted,
    required bool isMe,
  }) {
    final member = widget.room.members.cast<VibeRoomMember?>().firstWhere(
      (candidate) => candidate?.id == identity,
      orElse: () => null,
    );
    final resolvedAvatar = avatar.isNotEmpty
        ? avatar
        : member?.avatar ?? widget.room.hostAvatar;
    final resolvedName = name.trim().isNotEmpty
        ? name
        : member?.name ?? 'Member';
    return _VoiceParticipant(
      identity: identity,
      name: isMe ? 'You' : resolvedName,
      avatar: resolvedAvatar,
      role: role.isNotEmpty ? role : member?.role ?? 'Listener',
      speaking: speaking,
      muted: muted,
      isMe: isMe,
    );
  }

  Map<String, dynamic> _metadata(String? value) {
    if (value == null || value.isEmpty) return const {};
    try {
      final decoded = jsonDecode(value);
      return decoded is Map<String, dynamic> ? decoded : const {};
    } catch (_) {
      return const {};
    }
  }

  String get _connectionLabel => switch (_status) {
    _VoiceConnectionStatus.connecting => 'Connecting to live audio',
    _VoiceConnectionStatus.connected => 'Live audio connected',
    _VoiceConnectionStatus.reconnecting => 'Reconnecting audio…',
    _VoiceConnectionStatus.failed => 'Audio disconnected',
  };

  Color get _connectionColor => switch (_status) {
    _VoiceConnectionStatus.connected => AppColors.success,
    _VoiceConnectionStatus.reconnecting => AppColors.warning,
    _VoiceConnectionStatus.failed => AppColors.error,
    _VoiceConnectionStatus.connecting => AppColors.textSecondary,
  };

  @override
  Widget build(BuildContext context) {
    final participants = _participants();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        title: Row(
          children: [
            const Icon(Icons.headphones_rounded, color: AppColors.coral),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.room.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.label.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    _connectionLabel,
                    style: AppTypography.caption.copyWith(
                      color: _connectionColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: widget.leaving ? null : widget.onLeave,
            child: const Text('Leave'),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                children: [
                  Text(
                    widget.room.title,
                    textAlign: TextAlign.center,
                    style: AppTypography.h2.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 9),
                  _connectionBadge(),
                ],
              ),
            ),
            Expanded(
              child: _status == _VoiceConnectionStatus.failed
                  ? _connectionError()
                  : _status == _VoiceConnectionStatus.connected
                  ? _participantStage(participants)
                  : _connectingView(),
            ),
            if (_status == _VoiceConnectionStatus.connected)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(
                  'You joined muted. Turn on your mic when you are ready to speak.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            _controls(),
          ],
        ),
      ),
    );
  }

  Widget _connectionBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
    decoration: BoxDecoration(
      color: _connectionColor.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_status == _VoiceConnectionStatus.connecting ||
            _status == _VoiceConnectionStatus.reconnecting)
          SizedBox(
            width: 13,
            height: 13,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _connectionColor,
            ),
          )
        else
          Icon(
            _status == _VoiceConnectionStatus.connected
                ? Icons.wifi_calling_3_rounded
                : Icons.wifi_off_rounded,
            size: 15,
            color: _connectionColor,
          ),
        const SizedBox(width: 7),
        Text(
          _status == _VoiceConnectionStatus.connected
              ? '${_participants().length} in voice now'
              : _connectionLabel,
          style: AppTypography.caption.copyWith(
            color: _connectionColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );

  Widget _connectingView() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircularProgressIndicator(color: AppColors.coral),
        const SizedBox(height: 16),
        Text(
          _status == _VoiceConnectionStatus.reconnecting
              ? 'Restoring the voice connection…'
              : 'Joining live voice…',
          style: AppTypography.body.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 6),
        Text(
          'Your microphone stays off until you turn it on.',
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    ),
  );

  Widget _connectionError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.headset_off_rounded,
            size: 48,
            color: AppColors.error,
          ),
          const SizedBox(height: 14),
          Text(
            _errorMessage ?? 'Could not connect to live audio.',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _connecting || widget.api == null
                ? null
                : () => unawaited(_connect()),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      ),
    ),
  );

  Widget _participantStage(List<_VoiceParticipant> participants) {
    if (participants.isEmpty) {
      return Center(
        child: Text(
          'Waiting for people to join voice…',
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      itemCount: participants.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.05,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemBuilder: (context, index) => _participantTile(participants[index]),
    );
  }

  Widget _participantTile(_VoiceParticipant participant) => InkWell(
    onTap: _isHost && !participant.isMe
        ? () => unawaited(_showParticipantActions(participant))
        : null,
    borderRadius: BorderRadius.circular(20),
    child: Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: participant.speaking ? AppColors.success : AppColors.border,
          width: participant.speaking ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          VibeRoomAvatar(
            image: participant.avatar,
            size: 72,
            borderColor: participant.speaking ? AppColors.success : null,
            online: true,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              participant.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.label.copyWith(color: AppColors.textPrimary),
            ),
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                participant.muted ? Icons.mic_off_rounded : Icons.mic_rounded,
                size: 13,
                color: participant.muted
                    ? AppColors.textSecondary
                    : AppColors.success,
              ),
              const SizedBox(width: 4),
              Text(
                participant.isMe ? 'You' : participant.role,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _controls() => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _VoiceControlButton(
              icon: _micEnabled ? Icons.mic_rounded : Icons.mic_off_rounded,
              label: _micEnabled ? 'Mic on' : 'Unmute',
              active: _micEnabled,
              enabled:
                  _status == _VoiceConnectionStatus.connected && !_togglingMic,
              onTap: () => unawaited(_toggleMicrophone()),
            ),
          ),
          Expanded(
            child: _VoiceControlButton(
              icon: _speakerPreferred
                  ? Icons.volume_up_rounded
                  : Icons.hearing_rounded,
              label: _speakerPreferred ? 'Speaker' : 'Earpiece',
              active: _speakerPreferred,
              enabled: _status == _VoiceConnectionStatus.connected,
              onTap: () => unawaited(_toggleSpeaker()),
            ),
          ),
          Expanded(
            child: _VoiceControlButton(
              icon: Icons.people_alt_outlined,
              label: 'People',
              active: false,
              enabled: true,
              onTap: widget.onOpenPeople,
            ),
          ),
          Expanded(
            child: _VoiceControlButton(
              icon: Icons.sports_esports_outlined,
              label: 'Games',
              active: false,
              enabled: true,
              onTap: widget.onOpenGames,
            ),
          ),
        ],
      ),
    ),
  );
}

class _VoiceParticipant {
  const _VoiceParticipant({
    required this.identity,
    required this.name,
    required this.avatar,
    required this.role,
    required this.speaking,
    required this.muted,
    required this.isMe,
  });

  final String identity;
  final String name;
  final String avatar;
  final String role;
  final bool speaking;
  final bool muted;
  final bool isMe;
}

class _VoiceControlButton extends StatelessWidget {
  const _VoiceControlButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: enabled ? onTap : null,
    borderRadius: BorderRadius.circular(18),
    child: Opacity(
      opacity: enabled ? 1 : .45,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: active
                  ? AppColors.coralSoft
                  : AppColors.surfaceSecondary,
              child: Icon(icon, size: 20, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
