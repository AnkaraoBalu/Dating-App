import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/voice_note/voice_note_player.dart';
import '../../../home/data/home_discover_data.dart';
import '../../models/chat_models.dart';
import '../screens/chat_image_viewer.dart';
import 'chat_media.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.person,
    required this.onRetry,
    this.onSave,
  });

  final ChatMessage message;
  final HomePerson person;
  final VoidCallback onRetry;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final time = TimeOfDay.fromDateTime(message.sentAt).format(context);
    final picture = message.mediaUrl ?? message.mediaLocalPath;
    return GestureDetector(
      onLongPress: message.pending || message.failed ? null : onSave,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 11),
        child: Row(
          mainAxisAlignment: message.fromMe
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!message.fromMe) ...[
              chatPersonAvatar(person, radius: 17),
              const SizedBox(width: 7),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment: message.fromMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Container(
                    constraints: const BoxConstraints(maxWidth: 285),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: message.fromMe
                          ? AppColors.coral
                          : AppColors.surfaceSecondary,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(message.fromMe ? 16 : 4),
                        bottomRight: Radius.circular(message.fromMe ? 4 : 16),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (message.type == 'image' && picture != null)
                          InkWell(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => ChatImageViewer(
                                  image: picture,
                                  localFile: message.mediaLocalPath != null,
                                ),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: ChatMessageBubble.image(
                                message,
                                width: 235,
                                height: 155,
                              ),
                            ),
                          ),
                        if (message.type == 'location')
                          _locationBubble(context),
                        if (message.type == 'voice')
                          VoiceNotePlayer(
                            url: message.mediaUrl,
                            localPath: message.mediaLocalPath,
                            duration: Duration(
                              milliseconds: message.durationMs ?? 0,
                            ),
                            onAccent: message.fromMe,
                          ),
                        if (message.type == 'call') _callLine(),
                        if (message.text.isNotEmpty &&
                            message.type != 'location' &&
                            message.type != 'call')
                          Text(
                            message.text,
                            style: TextStyle(
                              color: message.fromMe
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        time,
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 9,
                        ),
                      ),
                      if (message.savedInChat) ...[
                        const SizedBox(width: 5),
                        const Icon(
                          Icons.bookmark,
                          size: 12,
                          color: AppColors.textSecondary,
                        ),
                        const Text(
                          'Saved in Chat',
                          style: TextStyle(
                            fontSize: 9,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      if (message.fromMe && message.readAt != null) ...[
                        const SizedBox(width: 5),
                        const Text(
                          'Seen',
                          style: TextStyle(
                            color: Color(0xFF9ED6FF),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (message.fromMe && message.pending)
                    const Text(
                      'Sending…',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 9,
                      ),
                    ),
                  if (message.fromMe && message.failed)
                    TextButton(
                      onPressed: onRetry,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Not sent · Tap to retry',
                        style: TextStyle(
                          color: AppColors.coralPressed,
                          fontSize: 9,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (message.fromMe) const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }

  static Widget image(
    ChatMessage message, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    final path = message.mediaLocalPath ?? message.mediaUrl ?? '';
    final image = message.mediaLocalPath != null
        ? Image.file(File(path), width: width, height: height, fit: fit)
        : path.startsWith('http')
        ? Image.network(
            path,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (_, _, _) => _imageError(width, height),
          )
        : Image.asset(path, width: width, height: height, fit: fit);
    return image;
  }

  static Widget _imageError(double? width, double? height) => Container(
    width: width,
    height: height,
    color: AppColors.surfaceSecondary,
    alignment: Alignment.center,
    child: const Icon(
      Icons.broken_image_outlined,
      color: AppColors.textSecondary,
    ),
  );

  /// "Voice call · 4:12", "Missed voice call", etc. The message's text is
  /// the call's outcome and its sender is the caller.
  Widget _callLine() {
    final missed = message.text == 'missed';
    final declined = message.text == 'declined';
    final label = missed
        ? (message.fromMe ? 'No answer' : 'Missed voice call')
        : declined
        ? (message.fromMe ? 'Call declined' : 'Declined voice call')
        : 'Voice call';
    final duration = message.durationMs;
    final detail = !missed && !declined && duration != null
        ? ' · ${_callDuration(Duration(milliseconds: duration))}'
        : '';
    final foreground = message.fromMe ? Colors.white : AppColors.textPrimary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          missed || declined
              ? Icons.call_missed_rounded
              : message.fromMe
              ? Icons.call_made_rounded
              : Icons.call_received_rounded,
          size: 18,
          color: (missed || declined) && !message.fromMe
              ? AppColors.error
              : foreground,
        ),
        const SizedBox(width: 8),
        Text(
          '$label$detail',
          style: TextStyle(
            color: foreground,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  static String _callDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Widget _locationBubble(BuildContext context) {
    final latitude = message.latitude;
    final longitude = message.longitude;
    final foreground = message.fromMe ? Colors.white : AppColors.textPrimary;
    final secondary = message.fromMe ? Colors.white70 : AppColors.textSecondary;
    return InkWell(
      onTap: latitude == null || longitude == null
          ? null
          : () => _openMap(context, latitude, longitude),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 230,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: message.fromMe
              ? Colors.black.withValues(alpha: .18)
              : AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.location_on_rounded, color: foreground, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Approximate location',
                    style: TextStyle(
                      color: foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Tap to open map',
                    style: TextStyle(color: secondary, fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(Icons.open_in_new_rounded, color: secondary, size: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _openMap(
    BuildContext context,
    double latitude,
    double longitude,
  ) async {
    try {
      final opened = await launchUrl(
        Uri.parse('https://maps.google.com/?q=$latitude,$longitude'),
        mode: LaunchMode.externalApplication,
      );
      if (!opened && context.mounted) {
        showChatNotice(context, 'No map app could open this location.');
      }
    } catch (_) {
      if (context.mounted) showChatNotice(context, 'Could not open the map.');
    }
  }
}
