import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../home/data/home_discover_data.dart';
import '../../../chat/data/chat_api.dart';
import '../../../chat/presentation/screens/conversation_screen.dart';
import '../../data/match_controller.dart';
import '../../models/match_model.dart';
import 'likes_received_screen.dart';

part '../widgets/matches_sections.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({
    super.key,
    required this.controller,
    required this.onExplorePeople,
    this.currentUserImage,
  });
  final MatchController controller;
  final VoidCallback onExplorePeople;
  final String? currentUserImage;

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  int _filter = 0;
  int _sort = 0;

  void _refresh(VoidCallback mutation) => setState(mutation);

  @override
  void initState() {
    super.initState();
    widget.controller.load();
  }

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
      final all = widget.controller.matches;
      final filtered = switch (_filter) {
        1 => all.where((match) => match.isNew).toList(),
        2 => all.where((match) => match.hasConversation).toList(),
        _ => all,
      };
      final visible = [...filtered]
        ..sort(
          (a, b) => switch (_sort) {
            1 => a.person.name.toLowerCase().compareTo(
              b.person.name.toLowerCase(),
            ),
            2 => b.unreadCount.compareTo(a.unreadCount),
            _ => b.lastActivity.compareTo(a.lastActivity),
          },
        );
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 13, 16, 15),
                child: Row(
                  children: [
                    Text(
                      'Matches',
                      style: AppTypography.h2.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 25,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.coral,
                      size: 20,
                    ),
                    const Spacer(),
                    _roundButton(
                      Icons.notifications_none_rounded,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => LikesReceivedScreen(
                            controller: widget.controller,
                            currentUserImage: widget.currentUserImage,
                          ),
                        ),
                      ),
                      badge: widget.controller.incomingLikes.length,
                    ),
                    const SizedBox(width: 9),
                    _roundButton(
                      Icons.tune_rounded,
                      onTap: () => _showFilterSheet(context),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _filterChip('All', all.length, 0),
                    const SizedBox(width: 7),
                    _filterChip('New', all.where((m) => m.isNew).length, 1),
                    const SizedBox(width: 7),
                    _filterChip(
                      'Messages',
                      all.where((m) => m.hasConversation).length,
                      2,
                    ),
                  ],
                ),
              ),
              if (all.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  child: TextField(
                    controller: _search,
                    onChanged: _searchChanged,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search matches...',
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
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                ),
              ],
              Expanded(
                child: widget.controller.loading && all.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.coral,
                        ),
                      )
                    : visible.isEmpty
                    ? _emptyState(
                        isSearching: _search.text.isNotEmpty,
                        hasMatches: all.isNotEmpty,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 22),
                        itemCount: visible.length,
                        separatorBuilder: (_, _) => Divider(
                          height: 1,
                          color: AppColors.border,
                          indent: 76,
                        ),
                        itemBuilder: (context, index) =>
                            _matchTile(context, visible[index]),
                      ),
              ),
            ],
          ),
        ),
      );
    },
  );

  Widget _filterChip(String label, int count, int value) {
    final selected = _filter == value;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => setState(() => _filter = value),
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
                if (count > 0) ...[
                  const SizedBox(width: 5),
                  Text(
                    '$count',
                    style: TextStyle(
                      color: selected
                          ? Colors.white70
                          : AppColors.textSecondary,
                      fontSize: 10,
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

  Widget _matchTile(BuildContext context, MatchRecord match) => InkWell(
    onTap: () async {
      await Navigator.of(context).push(
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
      if (context.mounted) unawaited(widget.controller.load());
    },
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          _avatar(match.person, size: 52),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        match.person.name,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.label.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (match.person.verified) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.verified_rounded,
                        color: Color(0xFF58A5FF),
                        size: 15,
                      ),
                    ],
                    if (match.isNew) ...[
                      const SizedBox(width: 7),
                      const _NewBadge(),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  match.lastMessage ?? 'You matched! Say hello 👋',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                match.lastActivity,
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 6),
              if (match.unreadCount > 0)
                Container(
                  width: 20,
                  height: 20,
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
          ),
        ],
      ),
    ),
  );
}
