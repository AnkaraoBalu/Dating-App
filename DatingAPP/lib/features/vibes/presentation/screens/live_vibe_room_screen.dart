import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../data/vibe_room_live_service.dart';
import '../../data/vibe_rooms_api.dart';
import '../../data/vibe_room_store.dart';
import '../../models/vibe_room.dart';
import '../widgets/live_vibe_room_widgets.dart';
import '../widgets/vibe_room_widgets.dart';
import 'icebreaker_games_screen.dart';
import 'live_vibe_voice_screen.dart';
import 'vibe_room_people_screen.dart';

class LiveVibeRoomScreen extends StatefulWidget {
  const LiveVibeRoomScreen({
    super.key,
    required this.room,
    this.api,
    this.voiceMode = false,
  });

  final VibeRoom room;
  final VibeRoomsApi? api;
  final bool voiceMode;

  @override
  State<LiveVibeRoomScreen> createState() => _LiveVibeRoomScreenState();
}

class _LiveVibeRoomScreenState extends State<LiveVibeRoomScreen> {
  final _messageController = TextEditingController();
  late final List<VibeRoomMessage> _messages = [...widget.room.messages];
  Timer? _messagePoll;
  VibeRoomLiveService? _live;
  StreamSubscription<VibeRoomMessage>? _liveMessages;
  StreamSubscription<void>? _liveJoined;
  bool _refreshingMessages = false;
  bool _leaving = false;
  String? _retryMessageId;
  String? _retryMessageText;

  @override
  void initState() {
    super.initState();
    final api = widget.api;
    if (api != null) {
      unawaited(_refreshMessages(showInitialError: true));
      final live = VibeRoomLiveService(api: api, roomId: widget.room.id);
      _live = live;
      _liveMessages = live.messages.listen(_receiveLiveMessage);
      // Every (re)join reloads history to cover anything sent while offline.
      _liveJoined = live.joined.listen((_) => unawaited(_refreshMessages()));
      live.connect();
      // Fallback while the live connection is down.
      _messagePoll = Timer.periodic(const Duration(seconds: 5), (_) {
        if (_live?.live.value != true) unawaited(_refreshMessages());
      });
    }
  }

  @override
  void dispose() {
    _messagePoll?.cancel();
    unawaited(_liveMessages?.cancel());
    unawaited(_liveJoined?.cancel());
    unawaited(_live?.dispose());
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _leave() async {
    if (_leaving) return;
    setState(() => _leaving = true);
    try {
      if (widget.api == null) {
        VibeRoomStore.instance.leave(widget.room);
      } else {
        final room = await widget.api!.leaveRoom(widget.room.id);
        VibeRoomStore.instance.historyIds.add(room.id);
        VibeRoomStore.instance.cacheRoom(room);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not leave this room: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _leaving = false);
    }
  }

  void _openPeople() => Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => VibeRoomPeopleScreen(room: widget.room),
    ),
  );

  void _openGames() => Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => IcebreakerGamesScreen(room: widget.room, api: widget.api),
    ),
  );

  /// Adds a pushed message, replacing this member's pending copy if the push
  /// arrives before the send response, and ignoring messages already shown.
  void _receiveLiveMessage(VibeRoomMessage message) {
    if (!mounted) return;
    if (message.id != null && _messages.any((m) => m.id == message.id)) return;
    setState(() {
      final pending = message.clientMessageId == null
          ? -1
          : _messages.indexWhere(
              (m) => m.clientMessageId == message.clientMessageId,
            );
      if (pending == -1) {
        _messages.add(message);
      } else {
        _messages[pending] = message;
      }
    });
  }

  Future<void> _refreshMessages({bool showInitialError = false}) async {
    final api = widget.api;
    if (api == null || _refreshingMessages) return;
    _refreshingMessages = true;
    try {
      final messages = await api.listMessages(widget.room.id);
      if (!mounted) return;
      setState(() {
        final pending = _messages.where(
          (message) =>
              message.id == null &&
              message.clientMessageId != null &&
              !messages.any(
                (remote) => remote.clientMessageId == message.clientMessageId,
              ),
        );
        _messages
          ..clear()
          ..addAll(messages)
          ..addAll(pending);
      });
    } catch (error) {
      if (showInitialError && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load room messages: $error')),
        );
      }
    } finally {
      _refreshingMessages = false;
    }
  }

  Future<void> _send() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    final clientMessageId = widget.api == null
        ? null
        : _retryMessageText == text && _retryMessageId != null
        ? _retryMessageId
        : '${widget.room.id}-${DateTime.now().microsecondsSinceEpoch}';
    final pendingMessage = VibeRoomMessage(
      clientMessageId: clientMessageId,
      sender: 'You',
      avatar: VibeRoomSeeds.me.avatar,
      text: text,
      time: TimeOfDay.now().format(context),
      isMe: true,
    );
    setState(() {
      _messages.add(pendingMessage);
      _messageController.clear();
    });
    if (widget.api == null) return;

    try {
      final sent = await widget.api!.sendMessage(
        roomId: widget.room.id,
        clientMessageId: clientMessageId!,
        text: text,
      );
      if (!mounted) return;
      setState(() {
        final index = _messages.indexWhere(
          (message) => message.clientMessageId == clientMessageId,
        );
        if (index == -1) {
          _messages.add(sent);
        } else {
          _messages[index] = sent;
        }
      });
      if (_retryMessageId == clientMessageId) {
        _retryMessageId = null;
        _retryMessageText = null;
      }
    } catch (error) {
      if (!mounted) return;
      _retryMessageId = clientMessageId;
      _retryMessageText = text;
      setState(() {
        _messages.removeWhere(
          (message) => message.clientMessageId == clientMessageId,
        );
      });
      _messageController.text = text;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Message was not sent. '
            '${'$error'.replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) =>
      widget.voiceMode ? _voiceScreen() : _chatScreen(context);

  Widget _chatScreen(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      titleSpacing: 4,
      title: InkWell(
        onTap: _openPeople,
        child: Row(
          children: [
            VibeRoomAvatar(image: widget.room.hostAvatar, size: 37),
            const SizedBox(width: 9),
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
                    '${widget.room.participantCount} people live',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _leaving ? null : _leave,
          child: const Text('Leave'),
        ),
        const SizedBox(width: 5),
      ],
    ),
    body: SafeArea(
      top: false,
      child: Column(
        children: [
          LiveVibeSpeakerStrip(room: widget.room, onTap: _openPeople),
          LiveVibeTopicCard(room: widget.room, onOpenGames: _openGames),
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Text(
                      'Start the conversation',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(15, 6, 15, 12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) =>
                        LiveVibeMessageTile(message: _messages[index]),
                  ),
          ),
          LiveVibeComposer(
            controller: _messageController,
            onSend: _send,
            onOpenGames: _openGames,
          ),
        ],
      ),
    ),
  );

  Widget _voiceScreen() => LiveVibeVoiceScreen(
    room: widget.room,
    leaving: _leaving,
    onLeave: _leave,
    onOpenPeople: _openPeople,
    onOpenGames: _openGames,
  );
}
