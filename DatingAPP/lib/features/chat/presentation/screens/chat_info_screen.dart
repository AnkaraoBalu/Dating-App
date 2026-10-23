import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../matches/models/match_model.dart';
import '../../../safety/data/safety_api.dart';
import '../../../safety/presentation/safety_actions.dart';
import '../../models/chat_models.dart';
import '../widgets/chat_media.dart';
import 'chat_search_screen.dart';
import 'shared_items_screen.dart';
import 'shared_media_screen.dart';

class ChatInfoScreen extends StatelessWidget {
  const ChatInfoScreen({
    super.key,
    required this.match,
    required this.messages,
    required this.safetyApi,
    this.onAudioCall,
    this.olderMessagesAvailable = false,
  });
  final MatchRecord match;
  final List<ChatMessage> messages;
  final bool olderMessagesAvailable;
  final SafetyApi safetyApi;
  final VoidCallback? onAudioCall;

  /// The chat no longer exists after a block or report; return to the tabs.
  void _leaveChat(BuildContext context, bool removed) {
    if (removed) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Widget _sharedMediaPreview() {
    final sharedPhotos = messages
        .where((message) => message.type == 'image' && message.mediaUrl != null)
        .take(4)
        .toList();
    if (sharedPhotos.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 120,
      child: Row(
        children: sharedPhotos
            .map(
              (message) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Image.network(
                      message.mediaUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const ColoredBox(
                        color: AppColors.surfaceSecondary,
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      surfaceTintColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: const Text('Chat info'),
    ),
    body: ListView(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      children: [
        const SizedBox(height: 10),
        Center(child: chatPersonAvatar(match.person, radius: 48)),
        const SizedBox(height: 10),
        Center(
          child: Text(
            match.person.name,
            style: AppTypography.title.copyWith(color: AppColors.textPrimary),
          ),
        ),
        Center(
          child: Text(
            match.person.online ? 'Online now' : match.person.distance,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
        if (match.person.photos.isNotEmpty) ...[
          const SizedBox(height: 22),
          const Text(
            'Profile photos',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 118,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: match.person.photos.length,
              separatorBuilder: (_, _) => const SizedBox(width: 9),
              itemBuilder: (context, index) =>
                  chatProfilePhotoPreview(context, match.person.photos[index]),
            ),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _infoAction(
              Icons.call_outlined,
              'Audio call',
              onAudioCall ??
                  () => showChatNotice(context, 'Voice calls are unavailable.'),
            ),
            _infoAction(
              Icons.search_rounded,
              'Search',
              () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ChatSearchScreen(
                    match: match,
                    messages: messages,
                    olderMessagesAvailable: olderMessagesAvailable,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ListTile(
          title: const Text(
            'Photos & media',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right,
            color: AppColors.textSecondary,
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (_) =>
                  SharedMediaScreen(match: match, messages: messages),
            ),
          ),
        ),
        _sharedMediaPreview(),
        const Divider(color: AppColors.border),
        for (final (kind, icon, label) in const [
          (SharedItemKind.links, Icons.link_rounded, 'Shared links'),
          (
            SharedItemKind.locations,
            Icons.location_on_outlined,
            'Shared locations',
          ),
        ])
          ListTile(
            leading: Icon(icon, color: AppColors.textSecondary),
            title: Text(
              label,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            trailing: Text(
              '${sharedItems(messages, kind).length}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => SharedItemsScreen(
                  match: match,
                  messages: messages,
                  kind: kind,
                ),
              ),
            ),
          ),
        ListTile(
          leading: const Icon(Icons.block_rounded, color: AppColors.error),
          title: const Text('Block', style: TextStyle(color: AppColors.error)),
          onTap: () async {
            final removed = await confirmAndBlock(
              context,
              api: safetyApi,
              userId: match.person.id,
              name: match.person.name,
            );
            if (context.mounted) _leaveChat(context, removed);
          },
        ),
        ListTile(
          leading: const Icon(Icons.flag_outlined, color: AppColors.error),
          title: const Text('Report', style: TextStyle(color: AppColors.error)),
          onTap: () async {
            final removed = await showReportFlow(
              context,
              api: safetyApi,
              userId: match.person.id,
              name: match.person.name,
              source: 'chat',
            );
            if (context.mounted) _leaveChat(context, removed);
          },
        ),
      ],
    ),
  );
}

Widget _infoAction(IconData icon, String label, VoidCallback onTap) => InkWell(
  onTap: onTap,
  child: Column(
    children: [
      CircleAvatar(
        backgroundColor: AppColors.surfaceSecondary,
        child: Icon(icon, color: AppColors.textPrimary),
      ),
      const SizedBox(height: 5),
      Text(
        label,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 9),
      ),
    ],
  ),
);
