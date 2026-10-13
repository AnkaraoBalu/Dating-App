import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/voice_note/voice_note_composer.dart';
import '../../../../core/widgets/voice_note/voice_note_player.dart';
import '../../models/vibe_room.dart';
import 'vibe_room_widgets.dart';

class LiveVibeSpeakerStrip extends StatelessWidget {
  const LiveVibeSpeakerStrip({
    super.key,
    required this.room,
    required this.onTap,
  });

  final VibeRoom room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(15, 10, 12, 11),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Speakers (${room.members.where((m) => m.role != 'Listener').length})',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 19,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 74,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: room.members.length,
                separatorBuilder: (_, _) => const SizedBox(width: 15),
                itemBuilder: (context, index) {
                  final member = room.members[index];
                  return SizedBox(
                    width: 54,
                    child: Column(
                      children: [
                        VibeRoomAvatar(
                          image: member.avatar,
                          size: 44,
                          borderColor: member.role == 'Host'
                              ? AppColors.coral
                              : null,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          member.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textPrimary,
                            fontSize: 9,
                          ),
                        ),
                        if (member.role == 'Host')
                          Text(
                            'Host',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.coralPressed,
                              fontSize: 8,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class LiveVibeTopicCard extends StatelessWidget {
  const LiveVibeTopicCard({
    super.key,
    required this.room,
    required this.onOpenGames,
  });

  final VibeRoom room;
  final VoidCallback onOpenGames;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 11, 14, 8),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.peachSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('✨', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today’s topic',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'What’s your favourite ${room.categoryId == 'coffee_chats' ? 'café' : 'way to spend an evening'} nearby?',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Icebreaker games',
            onPressed: onOpenGames,
            icon: const Icon(
              Icons.sports_esports_outlined,
              color: AppColors.coralPressed,
            ),
          ),
        ],
      ),
    ),
  );
}

class LiveVibeComposer extends StatelessWidget {
  const LiveVibeComposer({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onSendVoice,
    required this.onOpenGames,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final ValueChanged<VoiceNote> onSendVoice;
  final VoidCallback onOpenGames;

  @override
  Widget build(BuildContext context) => VoiceNoteComposer(
    textController: controller,
    onSendText: onSend,
    onSendVoice: onSendVoice,
    sendButtonSize: 19,
    builder: _row,
  );

  Widget _row(BuildContext context, Widget actionButton) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          IconButton.filledTonal(
            onPressed: onOpenGames,
            tooltip: 'Play an icebreaker game',
            icon: const Icon(Icons.extension_rounded),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: controller,
              onSubmitted: (_) => onSend(),
              textInputAction: TextInputAction.send,
              decoration: InputDecoration(
                hintText: 'Type a message…',
                filled: true,
                fillColor: AppColors.surfaceSecondary,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 11,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          actionButton,
        ],
      ),
    ),
  );
}

class LiveVibeMessageTile extends StatelessWidget {
  const LiveVibeMessageTile({super.key, required this.message});

  final VibeRoomMessage message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      mainAxisAlignment: message.isMe
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!message.isMe) ...[
          VibeRoomAvatar(image: message.avatar, size: 35),
          const SizedBox(width: 9),
        ],
        Flexible(
          child: Column(
            crossAxisAlignment: message.isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: message.isMe
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                children: [
                  Text(
                    message.sender,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    message.time,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              if (message.isVoice)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.fromLTRB(4, 2, 12, 2),
                  decoration: BoxDecoration(
                    color: message.isMe
                        ? AppColors.coral
                        : AppColors.surfaceSecondary,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: VoiceNotePlayer(
                    url: message.mediaUrl,
                    localPath: message.mediaLocalPath,
                    duration: Duration(milliseconds: message.durationMs ?? 0),
                    onAccent: message.isMe,
                  ),
                )
              else
                Text(
                  message.text,
                  textAlign: message.isMe ? TextAlign.right : TextAlign.left,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
            ],
          ),
        ),
        if (message.isMe) ...[
          const SizedBox(width: 9),
          VibeRoomAvatar(image: message.avatar, size: 35),
        ],
      ],
    ),
  );
}
