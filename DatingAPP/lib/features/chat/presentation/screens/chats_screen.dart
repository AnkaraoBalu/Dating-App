import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../matches/data/match_controller.dart';
import '../../../matches/models/match_model.dart';
import '../../data/chat_api.dart';
import 'conversation_screen.dart';

part '../widgets/chats_list_sections.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key, required this.controller});

  final MatchController controller;

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  int _filter = 0;

  @override
  void dispose() {
    _debounce?.cancel();
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
      final chats = switch (_filter) {
        1 => matches.where((match) => match.unreadCount > 0).toList(),
        2 => matches.where((match) => !match.isNew).toList(),
        _ => matches,
      };
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
                    _circleButton(
                      Icons.tune_rounded,
                      () => _sort(context, matches),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _filterChip('All', 0),
                    const SizedBox(width: 7),
                    _filterChip(
                      'Unread',
                      1,
                      badge: matches.where((m) => m.unreadCount > 0).length,
                    ),
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
                child: widget.controller.loading && matches.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.coral,
                        ),
                      )
                    : chats.isEmpty
                    ? _emptyState(matches.isEmpty)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 3, 16, 20),
                        itemCount: chats.length,
                        separatorBuilder: (_, _) => Divider(
                          height: 1,
                          indent: 75,
                          color: AppColors.border,
                        ),
                        itemBuilder: (context, index) => _chatRow(chats[index]),
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

  Widget _chatRow(MatchRecord match) => InkWell(
    onTap: () async {
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
          _ChatAvatar(match: match),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        match.person.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.label.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      match.lastActivity,
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
                        match.lastMessage ?? 'You matched! Say hello 👋',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    if (match.unreadCount > 0) ...[
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
                            '${match.unreadCount}',
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

  void _sort(BuildContext context, List<MatchRecord> matches) =>
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: AppColors.surface,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.schedule_rounded,
                  color: AppColors.coral,
                ),
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
