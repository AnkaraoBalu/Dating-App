import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/theme.dart';
import '../../../calls/data/call_coordinator.dart';
import '../../../calls/data/calls_api.dart';
import '../../../calls/presentation/screens/voice_call_screen.dart';
import '../../../calls/presentation/widgets/call_microphone_permission.dart';
import '../../../matches/models/match_model.dart';
import '../../data/chat_api.dart';
import '../../models/chat_models.dart';
import '../../data/chat_controller.dart';
import '../../data/chat_socket_service.dart';
import '../widgets/chat_composer_bar.dart';
import '../widgets/chat_location.dart';
import '../widgets/chat_sheets.dart';
import '../widgets/chat_media.dart';
import '../widgets/chat_message_bubble.dart';
import '../../../matches/presentation/screens/matched_profile_screen.dart';
import 'chat_info_screen.dart';
import 'chat_search_screen.dart';
import 'shared_media_screen.dart';

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({super.key, required this.match, required this.api});

  final MatchRecord match;
  final ChatApi api;

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen>
    with WidgetsBindingObserver {
  final _composer = TextEditingController();
  final _messagesScroll = ScrollController();
  final _imagePicker = ImagePicker();
  int _lastMessageCount = 0;
  StreamSubscription<String>? _sendErrors;
  late final ChatController _controller = ChatController(
    api: widget.api,
    socket: ChatSocketService(widget.api),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller.addListener(_updated);
    _sendErrors = _controller.sendErrors.listen((reason) {
      if (mounted) _notice(reason);
    });
    _messagesScroll.addListener(_loadOlderWhenNearTop);
    unawaited(
      _controller.open(
        widget.match.person.id,
        existingConversationId: widget.match.conversationId,
      ),
    );
  }

  void _updated() {
    if (!mounted) return;
    final count = _controller.messages.length;
    final follow =
        _lastMessageCount == 0 ||
        !_messagesScroll.hasClients ||
        _messagesScroll.position.extentAfter < 100 ||
        (count > _lastMessageCount && _controller.messages.last.fromMe);
    final changed = count != _lastMessageCount;
    _lastMessageCount = count;
    setState(() {});
    if (changed && follow && !_controller.loadingOlder) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _messagesScroll.hasClients) {
          _messagesScroll.jumpTo(_messagesScroll.position.maxScrollExtent);
        }
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      unawaited(_controller.leaveConversation());
    }
    _controller.active = state == AppLifecycleState.resumed;
    if (_controller.active) unawaited(_controller.retryConnection());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_updated);
    unawaited(_sendErrors?.cancel());
    _messagesScroll.removeListener(_loadOlderWhenNearTop);
    _messagesScroll.dispose();
    _controller.dispose();
    _composer.dispose();
    super.dispose();
  }

  Future<void> _showSaveMessage(ChatMessage message) async {
    final save = await showModalBottomSheet<bool>(
      context: context,
      builder: (context) => SafeArea(
        child: ListTile(
          leading: Icon(
            message.savedInChat
                ? Icons.bookmark_remove_outlined
                : Icons.bookmark_add_outlined,
          ),
          title: Text(
            message.savedInChat ? 'Unsave from Chat' : 'Save in Chat',
          ),
          subtitle: Text(
            message.savedInChat
                ? 'This message can disappear after the recipient leaves.'
                : 'Keep this message for both people.',
          ),
          onTap: () => Navigator.pop(context, true),
        ),
      ),
    );
    if (save != true || !mounted) return;
    try {
      await _controller.toggleSaved(message);
    } catch (_) {
      if (mounted) _notice('Could not update saved message. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: AppColors.background,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: AppColors.background,
    ),
    child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        title: InkWell(
          onTap: () => _openInfo(context),
          child: Row(
            children: [
              _avatar(),
              const SizedBox(width: 9),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.match.person.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    widget.match.person.online ? 'Online now' : 'Your match',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => unawaited(_startCall()),
            tooltip: 'Voice call',
            icon: const Icon(Icons.call_outlined),
          ),
          IconButton(
            onPressed: _showOptions,
            icon: const Icon(Icons.more_horiz_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_controller.connectionError != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Live chat is offline. Unread messages stay until viewed.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _controller.retryConnection,
                    child: const Text('Reconnect'),
                  ),
                ],
              ),
            ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Viewed messages disappear · Long-press to save',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 10),
            ),
          ),
          Expanded(
            child: _controller.loading && _controller.messages.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.coral),
                  )
                : _controller.messages.isEmpty && _controller.error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Could not load this conversation.\n${_controller.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: _controller.retryOpen,
                            child: const Text('Try again'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _messagesScroll,
                    padding: const EdgeInsets.fromLTRB(14, 2, 14, 12),
                    itemCount:
                        _controller.messages.length +
                        (_controller.hasMore || _controller.loadingOlder
                            ? 1
                            : 0),
                    itemBuilder: (context, index) {
                      if (_controller.hasMore || _controller.loadingOlder) {
                        if (index == 0) {
                          return Center(
                            child: TextButton(
                              onPressed: _controller.loadingOlder
                                  ? null
                                  : _loadOlderKeepingPosition,
                              child: Text(
                                _controller.loadingOlder
                                    ? 'Loading earlier messages…'
                                    : 'Load earlier messages',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          );
                        }
                        index -= 1;
                      }
                      final message = _controller.messages[index];
                      return ChatMessageBubble(
                        onSave: () => unawaited(_showSaveMessage(message)),
                        message: message,
                        person: widget.match.person,
                        onRetry: () => _controller.retryMessage(message),
                      );
                    },
                  ),
          ),
          ChatComposerBar(
            controller: _composer,
            onAttach: _showAttachments,
            onSend: _send,
            onSendVoice: (note) =>
                unawaited(_controller.sendVoice(note.path, note.duration)),
          ),
        ],
      ),
    ),
  );

  Widget _avatar() => chatPersonAvatar(widget.match.person, radius: 17);

  void _send() {
    final value = _composer.text.trim();
    if (value.isEmpty) return;
    if (!_controller.sendText(value)) return;
    _composer.clear();
  }

  void _loadOlderWhenNearTop() {
    if (!_messagesScroll.hasClients ||
        _messagesScroll.position.pixels > 60 ||
        !_controller.hasMore ||
        _controller.loadingOlder) {
      return;
    }
    _loadOlderKeepingPosition();
  }

  Future<void> _loadOlderKeepingPosition() async {
    if (!_messagesScroll.hasClients || _controller.loadingOlder) return;
    final oldExtent = _messagesScroll.position.maxScrollExtent;
    final oldOffset = _messagesScroll.position.pixels;
    await _controller.loadOlder();
    if (!mounted || !_messagesScroll.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_messagesScroll.hasClients) return;
      final addedExtent = _messagesScroll.position.maxScrollExtent - oldExtent;
      if (addedExtent > 0) {
        _messagesScroll.jumpTo(oldOffset + addedExtent);
      }
    });
  }

  void _showAttachments() => showChatAttachmentSheet(
    context,
    onGallery: () => _pickAndSendImage(ImageSource.gallery),
    onCamera: () => _pickAndSendImage(ImageSource.camera),
    onGif: () => _notice(
      'GIF search will be enabled after a GIF provider is configured.',
    ),
    onLocation: _confirmAndSendLocation,
    onEmoji: () => showChatEmojiPicker(context, _composer),
    onSharedMedia: _showSharedMedia,
  );

  Future<void> _pickAndSendImage(ImageSource source) async {
    try {
      final image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 82,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (image == null || !mounted) return;
      if (_controller.conversationId == null) {
        _notice(
          'Wait for the conversation to finish connecting, then try again.',
        );
        return;
      }
      final caption = _composer.text.trim();
      _composer.clear();
      await _controller.sendImage(image, caption: caption);
    } catch (error) {
      _notice('Could not select that photo: $error');
    }
  }

  Future<void> _confirmAndSendLocation() async {
    final share = await confirmChatLocationShare(context);
    if (share != true || !mounted) return;
    if (_controller.conversationId == null) {
      _notice(
        'Wait for the conversation to finish connecting, then try again.',
      );
      return;
    }
    try {
      final (latitude, longitude) = await currentApproximatePosition();
      if (!mounted) return;
      _controller.sendLocation(latitude, longitude);
    } catch (error) {
      if (mounted) _notice(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _showSharedMedia() => Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => SharedMediaScreen(
        match: widget.match,
        messages: _controller.messages,
      ),
    ),
  );
  Future<void> _startCall() async {
    final conversationId =
        _controller.conversationId ?? widget.match.conversationId;
    if (conversationId == null) {
      _notice('This chat is still opening. Try again in a moment.');
      return;
    }
    if (CallCoordinator.instance.screenOpen) return;
    if (!await ensureCallMicrophone(
          context,
          peerName: widget.match.person.name,
        ) ||
        !mounted) {
      return;
    }
    await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => VoiceCallScreen.outgoing(
          api: CallsApi(
            baseUrl: widget.api.baseUrl,
            getSessionToken: widget.api.getSessionToken,
          ),
          conversationId: conversationId,
          peerName: widget.match.person.name,
          peerAvatar: widget.match.person.image,
        ),
      ),
    );
  }

  void _openInfo(BuildContext context) => Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => ChatInfoScreen(
        match: widget.match,
        messages: _controller.messages,
        onAudioCall: () => unawaited(_startCall()),
      ),
    ),
  );

  void _showOptions() => showChatOptionsSheet(
    context,
    onViewProfile: () => Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => MatchedProfileScreen(
          person: widget.match.person,
          chatApi: widget.api,
          onMessage: () => Navigator.pop(context),
        ),
      ),
    ),
    onChatInfo: () => _openInfo(context),
    onSharedMedia: _showSharedMedia,
    onSearch: () => Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ChatSearchScreen(match: widget.match),
      ),
    ),
    onClear: () => _notice('Clearing messages is not available yet.'),
  );

  void _notice(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}
