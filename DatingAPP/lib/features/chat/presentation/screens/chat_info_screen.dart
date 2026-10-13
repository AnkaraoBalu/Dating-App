import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../matches/models/match_model.dart';
import '../../models/chat_models.dart';
import '../widgets/chat_media.dart';
import 'chat_search_screen.dart';
import 'shared_media_screen.dart';

class ChatInfoScreen extends StatelessWidget {
  const ChatInfoScreen({
    super.key,
    required this.match,
    required this.messages,
    this.onAudioCall,
  });
  final MatchRecord match;
  final List<ChatMessage> messages;
  final VoidCallback? onAudioCall;

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
              Icons.videocam_outlined,
              'Video call',
              () => showChatNotice(context, 'Video calls are coming soon.'),
            ),
            _infoAction(
              Icons.notifications_off_outlined,
              'Mute',
              () => showChatNotice(context, 'Muting chats is coming soon.'),
            ),
            _infoAction(
              Icons.search_rounded,
              'Search',
              () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ChatSearchScreen(match: match),
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
        const ListTile(
          leading: Icon(Icons.link_rounded, color: AppColors.textSecondary),
          title: Text(
            'Shared links',
            style: TextStyle(color: AppColors.textPrimary),
          ),
        ),
        const ListTile(
          leading: Icon(
            Icons.location_on_outlined,
            color: AppColors.textSecondary,
          ),
          title: Text(
            'Shared locations',
            style: TextStyle(color: AppColors.textPrimary),
          ),
        ),
        SwitchListTile(
          value: true,
          onChanged: (_) {},
          title: const Text(
            'Notifications',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          activeThumbColor: AppColors.coral,
        ),
        ListTile(
          leading: const Icon(Icons.block_rounded, color: AppColors.error),
          title: const Text('Block', style: TextStyle(color: AppColors.error)),
          onTap: () =>
              showChatNotice(context, 'Block controls are coming soon.'),
        ),
        ListTile(
          leading: const Icon(Icons.flag_outlined, color: AppColors.error),
          title: const Text('Report', style: TextStyle(color: AppColors.error)),
          onTap: () =>
              showChatNotice(context, 'Report controls are coming soon.'),
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
