import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/voice_note/voice_note_composer.dart';

class ChatComposerBar extends StatelessWidget {
  const ChatComposerBar({
    super.key,
    required this.controller,
    required this.onAttach,
    required this.onSend,
    required this.onSendVoice,
  });

  final TextEditingController controller;
  final VoidCallback onAttach;
  final VoidCallback onSend;
  final ValueChanged<VoiceNote> onSendVoice;

  @override
  Widget build(BuildContext context) => VoiceNoteComposer(
    textController: controller,
    onSendText: onSend,
    onSendVoice: onSendVoice,
    builder: _row,
  );

  Widget _row(BuildContext context, Widget actionButton) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: onAttach,
            icon: const Icon(
              Icons.add_circle_outline_rounded,
              color: AppColors.textSecondary,
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              maxLength: 4000,
              maxLines: 4,
              minLines: 1,
              buildCounter:
                  (
                    context, {
                    required currentLength,
                    required isFocused,
                    maxLength,
                  }) => null,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                ),
                filled: true,
                fillColor: AppColors.surfaceSecondary,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(26),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(26),
                  borderSide: BorderSide(color: AppColors.border),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: onAttach,
            icon: const Icon(
              Icons.image_outlined,
              color: AppColors.textSecondary,
              size: 21,
            ),
          ),
          actionButton,
        ],
      ),
    ),
  );
}
