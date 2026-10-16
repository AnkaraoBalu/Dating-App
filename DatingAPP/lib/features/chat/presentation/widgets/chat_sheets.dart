import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';

void showChatAttachmentSheet(
  BuildContext context, {
  required VoidCallback onGallery,
  required VoidCallback onCamera,
  required VoidCallback onGif,
  required VoidCallback onLocation,
  required VoidCallback onEmoji,
  required VoidCallback onSharedMedia,
}) => showModalBottomSheet<void>(
  context: context,
  backgroundColor: AppColors.surface,
  showDragHandle: true,
  builder: (context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(18, 4, 18, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Share something',
            style: AppTypography.title.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _attachmentTile(
                context,
                Icons.photo_library_outlined,
                'Gallery',
                onGallery,
              ),
              _attachmentTile(
                context,
                Icons.camera_alt_outlined,
                'Camera',
                onCamera,
              ),
              _attachmentTile(context, Icons.gif_box_outlined, 'GIF', onGif),
              _attachmentTile(
                context,
                Icons.location_on_outlined,
                'Location',
                onLocation,
              ),
              _attachmentTile(
                context,
                Icons.emoji_emotions_outlined,
                'Emoji',
                onEmoji,
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              onSharedMedia();
            },
            icon: const Icon(Icons.collections_outlined),
            label: const Text('Shared media'),
          ),
        ],
      ),
    ),
  ),
);

Widget _attachmentTile(
  BuildContext context,
  IconData icon,
  String label,
  VoidCallback action,
) => InkWell(
  onTap: () {
    Navigator.pop(context);
    action();
  },
  borderRadius: BorderRadius.circular(14),
  child: Container(
    width: 92,
    padding: const EdgeInsets.symmetric(vertical: 13),
    decoration: BoxDecoration(
      color: AppColors.surfaceSecondary,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      children: [
        Icon(icon, color: AppColors.coral),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 11),
        ),
      ],
    ),
  ),
);

void showChatEmojiPicker(BuildContext context, TextEditingController composer) {
  const emojis = [
    '😀',
    '😃',
    '😄',
    '😁',
    '😆',
    '🥹',
    '😂',
    '🤣',
    '😊',
    '😇',
    '🙂',
    '😉',
    '😍',
    '🥰',
    '😘',
    '😋',
    '😎',
    '🤩',
    '🥳',
    '😭',
    '😌',
    '🤗',
    '🫶',
    '❤️',
    '💕',
    '💖',
    '💘',
    '💌',
    '👍',
    '👏',
    '🙏',
    '✨',
    '🔥',
    '🌹',
    '☕',
    '🌙',
    '🎉',
    '💯',
    '🥺',
    '🤔',
  ];
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: SizedBox(
        height: 280,
        child: GridView.count(
          crossAxisCount: 7,
          children: emojis
              .map(
                (emoji) => IconButton(
                  onPressed: () {
                    final value = composer.text;
                    final selection = composer.selection;
                    final start = selection.isValid
                        ? selection.start
                        : value.length;
                    final end = selection.isValid
                        ? selection.end
                        : value.length;
                    composer.value = TextEditingValue(
                      text: value.replaceRange(start, end, emoji),
                      selection: TextSelection.collapsed(
                        offset: start + emoji.length,
                      ),
                    );
                    Navigator.pop(context);
                  },
                  icon: Text(emoji, style: const TextStyle(fontSize: 25)),
                ),
              )
              .toList(),
        ),
      ),
    ),
  );
}

void showChatOptionsSheet(
  BuildContext context, {
  required VoidCallback onViewProfile,
  required VoidCallback onChatInfo,
  required VoidCallback onSharedMedia,
  required VoidCallback onSearch,
  VoidCallback? onClear,
}) => showModalBottomSheet<void>(
  context: context,
  backgroundColor: AppColors.surface,
  showDragHandle: true,
  builder: (context) => SafeArea(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.person_outline_rounded),
          title: const Text('View profile'),
          onTap: () {
            Navigator.pop(context);
            onViewProfile();
          },
        ),
        ListTile(
          leading: const Icon(Icons.info_outline_rounded),
          title: const Text('Chat info'),
          onTap: () {
            Navigator.pop(context);
            onChatInfo();
          },
        ),
        ListTile(
          leading: const Icon(Icons.collections_outlined),
          title: const Text('Shared media'),
          onTap: () {
            Navigator.pop(context);
            onSharedMedia();
          },
        ),
        ListTile(
          leading: const Icon(Icons.search_rounded),
          title: const Text('Search in chat'),
          onTap: () {
            Navigator.pop(context);
            onSearch();
          },
        ),
        if (onClear != null)
          ListTile(
            leading: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.error,
            ),
            title: const Text('Clear chat'),
            onTap: () {
              Navigator.pop(context);
              onClear();
            },
          ),
      ],
    ),
  ),
);
