import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../matches/data/match_controller.dart';
import '../../../matches/models/match_model.dart';
import '../../data/chat_api.dart';
import '../../../vibes/data/vibe_rooms_api.dart';
import '../../../vibes/models/vibe_room.dart';
import '../../../vibes/presentation/screens/live_vibe_room_screen.dart';
import 'conversation_screen.dart';

part '../widgets/chats_list_sections.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({
    super.key,
    required this.controller,
    required this.onExplorePeople,
  });

  final MatchController controller;

  /// Opens Discover from the empty chat list.
  final VoidCallback onExplorePeople;

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatListEntry {
  const _ChatListEntry.individual(MatchRecord value)
    : match = value,
      groupChat = null;

  const _ChatListEntry.group(VibeRoomChat value)
    : match = null,
      groupChat = value;

  final MatchRecord? match;
  final VibeRoomChat? groupChat;

  bool get isGroup => groupChat != null;
  bool get isStarted => isGroup || !match!.isNew;
  int get unreadCount => groupChat?.unreadCount ?? match!.unreadCount;
  DateTime? get lastActivityAt =>
      groupChat != null ? groupChat!.lastActivityAt : match!.lastActivityAt;
  String get title => groupChat?.room.title ?? match!.person.name;
  String get preview => groupChat == null
      ? match!.lastMessage ?? 'You matched! Say hello 👋'
      : groupChat!.lastMessage?.preview ?? 'You joined this room';
  String get activityLabel => groupChat == null
      ? match!.lastActivity
      : _relativeActivity(groupChat!.lastActivityAt);

  static String _relativeActivity(DateTime? activity) {
    if (activity == null) return '';
    final elapsed = DateTime.now().difference(activity);
    if (elapsed.inSeconds < 60) return 'now';
    if (elapsed.inMinutes < 60) return '${elapsed.inMinutes}m';
    if (elapsed.inHours < 24) return '${elapsed.inHours}h';
    if (elapsed.inDays < 7) return '${elapsed.inDays}d';
    return '${activity.month}/${activity.day}';
  }
}

class _GroupChatAvatar extends StatelessWidget {
  const _GroupChatAvatar({required this.chat});

  final VibeRoomChat chat;

  @override
  Widget build(BuildContext context) {
    final image = chat.room.coverImage;
    final provider = image.startsWith('http')
        ? NetworkImage(image) as ImageProvider
        : AssetImage(image);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: AppColors.surfaceSecondary,
          backgroundImage: image.isEmpty ? null : provider,
          child: image.isEmpty
              ? const Icon(Icons.groups_rounded, color: AppColors.textTertiary)
              : null,
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: 19,
            height: 19,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: Text(chat.room.emoji, style: const TextStyle(fontSize: 10)),
          ),
        ),
      ],
    );
  }
}

class _ChatsScreenState extends State<ChatsScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  Timer? _roomChatReload;
  late final VibeRoomsApi _vibeApi;
  List<VibeRoomChat> _roomChats = const [];
  bool _roomChatsLoading = false;
  bool _roomChatsReloadPending = false;
  String? _roomChatsError;
  int _filter = 0;

  @override
  void initState() {
    super.initState();
    _vibeApi = VibeRoomsApi(
      baseUrl: widget.controller.api.baseUrl,
      getSessionToken: widget.controller.api.getSessionToken,
    );
    widget.controller.addListener(_controllerChanged);
    unawaited(_loadRoomChats());
  }

  void _controllerChanged() {
    if (mounted) setState(() {});
    // HomeScreen reloads the shared controller after inbox:changed and socket
    // reconnection events. Refresh room conversations when that reload settles.
    if (!widget.controller.loading) {
      _roomChatReload?.cancel();
      _roomChatReload = Timer(
        const Duration(milliseconds: 350),
        () => unawaited(_loadRoomChats()),
      );
    }
  }

  Future<void> _loadRoomChats() async {
    if (_roomChatsLoading) {
      _roomChatsReloadPending = true;
      return;
    }
    _roomChatsReloadPending = false;
    setState(() => _roomChatsLoading = true);
    try {
      final chats = await _vibeApi.listChats();
      if (!mounted) return;
      setState(() {
        _roomChats = chats;
        _roomChatsError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _roomChatsError = error.toString());
    } finally {
      if (mounted) setState(() => _roomChatsLoading = false);
      if (mounted && _roomChatsReloadPending) {
        unawaited(_loadRoomChats());
      }
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([widget.controller.load(), _loadRoomChats()]);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _roomChatReload?.cancel();
    widget.controller.removeListener(_controllerChanged);
    _search.dispose();
    super.dispose();
  }

  void _searchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () {
      widget.controller.load(query: value.trim());
    });
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final matches = widget.controller.conversations;
      final query = _search.text.trim().toLowerCase();
      final entries =
          <_ChatListEntry>[
            ...matches.map(_ChatListEntry.individual),
            ..._roomChats
                .where((chat) {
                  if (query.isEmpty) return true;
                  return chat.room.title.toLowerCase().contains(query) ||
                      (chat.lastMessage?.text.toLowerCase().contains(query) ??
                          false);
                })
                .map(_ChatListEntry.group),
          ]..sort((a, b) {
            final left = a.lastActivityAt;
            final right = b.lastActivityAt;
            if (left == null && right == null) return 0;
            if (left == null) return 1;
            if (right == null) return -1;
            return right.compareTo(left);
          });
      final chats = switch (_filter) {
        1 => entries.where((chat) => chat.unreadCount > 0).toList(),
        2 => entries.where((chat) => chat.isStarted).toList(),
        _ => entries,
      };
      final unreadCount = entries.where((chat) => chat.unreadCount > 0).length;
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 16, 12),
                child: Row(
                  children: [
                    Text(
                      'Chat',
                      style: AppTypography.h2.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 25,
                      ),
                    ),
                    const Spacer(),
                    _circleButton(Icons.tune_rounded, () => _sort(context)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _filterChip('All', 0),
                    const SizedBox(width: 7),
                    _filterChip('Unread', 1, badge: unreadCount),
                    const SizedBox(width: 7),
                    _filterChip('Started', 2),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: TextField(
                  controller: _search,
                  onChanged: _searchChanged,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search messages...',
                    hintStyle: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    filled: true,
                    fillColor: AppColors.surfaceSecondary,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                  ),
                ),
              ),
              Expanded(
                child:
                    entries.isEmpty &&
                        (widget.controller.loading || _roomChatsLoading)
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.coral,
                        ),
                      )
                    : entries.isEmpty && _roomChatsError != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Could not load your chats.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                            TextButton(
                              onPressed: _refreshAll,
                              child: const Text('Try again'),
                            ),
                          ],
                        ),
                      )
                    : chats.isEmpty
                    ? _emptyState(entries.isEmpty)
                    : RefreshIndicator(
                        onRefresh: _refreshAll,
                        color: AppColors.coral,
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 3, 16, 20),
                          itemCount: chats.length,
                          separatorBuilder: (_, _) => Divider(
                            height: 1,
                            indent: 75,
                            color: AppColors.border,
                          ),
                          itemBuilder: (context, index) =>
                              _chatRow(chats[index]),
                        ),
                      ),
              ),
            ],
          ),
        ),
      );
    },
  );

  Widget _filterChip(String label, int value, {int? badge}) {
    final selected = _filter == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _filter = value),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            color: selected ? AppColors.coral : AppColors.surfaceSecondary,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? AppColors.coral : AppColors.border,
            ),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (badge != null && badge > 0) ...[
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.coralPressed,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$badge',
                      style: const TextStyle(color: Colors.white, fontSize: 9),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chatRow(_ChatListEntry entry) => InkWell(
    onTap: () async {
      final group = entry.groupChat;
      if (group != null) {
        await Navigator.push<void>(
          context,
          MaterialPageRoute<void>(
            builder: (_) => LiveVibeRoomScreen(room: group.room, api: _vibeApi),
          ),
        );
        if (mounted) unawaited(_loadRoomChats());
        return;
      }
      final match = entry.match!;
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => ConversationScreen(
            match: match,
            api: ChatApi(
              baseUrl: widget.controller.api.baseUrl,
              getSessionToken: widget.controller.api.getSessionToken,
            ),
          ),
        ),
      );
      if (mounted) unawaited(widget.controller.load());
    },
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          entry.groupChat == null
              ? _ChatAvatar(match: entry.match!)
              : _GroupChatAvatar(chat: entry.groupChat!),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.label.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (entry.isGroup) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.groups_rounded,
                        size: 14,
                        color: AppColors.textTertiary,
                      ),
                    ],
                    const SizedBox(width: 8),
                    Text(
                      entry.activityLabel,
                      style: const TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.preview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    if (entry.unreadCount > 0) ...[
                      const SizedBox(width: 7),
                      Container(
                        width: 19,
                        height: 19,
                        decoration: const BoxDecoration(
                          color: AppColors.coralPressed,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${entry.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _circleButton(IconData icon, VoidCallback onTap) => Material(
    color: AppColors.surfaceSecondary,
    shape: const CircleBorder(),
    child: InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: SizedBox(
        width: 38,
        height: 38,
        child: Icon(icon, color: AppColors.textPrimary, size: 19),
      ),
    ),
  );

  void _sort(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.schedule_rounded, color: AppColors.coral),
            title: const Text(
              'Recent activity',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(
              Icons.mark_chat_unread_outlined,
              color: AppColors.coral,
            ),
            title: const Text(
              'Unread messages',
              style: TextStyle(color: AppColors.textPrimary),
            ),
            onTap: () {
              setState(() => _filter = 1);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    ),
  );
}
