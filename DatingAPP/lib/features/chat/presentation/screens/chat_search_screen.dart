import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../matches/models/match_model.dart';
import '../../models/chat_models.dart';

class ChatSearchScreen extends StatefulWidget {
  const ChatSearchScreen({
    super.key,
    required this.match,
    required this.messages,
    this.olderMessagesAvailable = false,
  });
  final MatchRecord match;

  /// The messages loaded in the conversation; older pages are not fetched here.
  final List<ChatMessage> messages;
  final bool olderMessagesAvailable;
  @override
  State<ChatSearchScreen> createState() => _ChatSearchScreenState();
}

class _ChatSearchScreenState extends State<ChatSearchScreen> {
  final _search = TextEditingController();
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    // Photos, voice notes and locations have no text to search.
    final results =
        widget.messages
            .where(
              (message) =>
                  message.text.trim().isNotEmpty &&
                  (query.isEmpty || message.text.toLowerCase().contains(query)),
            )
            .toList()
          ..sort((a, b) => b.sentAt.compareTo(a.sentAt));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: TextField(
          controller: _search,
          autofocus: true,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'Search in conversation...',
            hintStyle: TextStyle(color: AppColors.textTertiary),
            // Plain field in the app bar: no theme outline or fill.
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '${results.length} ${results.length == 1 ? 'result' : 'results'}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          if (widget.olderMessagesAvailable) ...[
            const SizedBox(height: 4),
            const Text(
              'Searching loaded messages. Scroll up in the chat to load older ones.',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          for (final message in results)
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.surfaceSecondary,
                child: Icon(
                  Icons.chat_bubble_outline,
                  color: AppColors.textSecondary,
                  size: 17,
                ),
              ),
              title: Text(
                message.fromMe ? 'You' : widget.match.person.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                ),
              ),
              subtitle: Text(
                message.text,
                maxLines: 2,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              trailing: Text(
                _when(context, message.sentAt),
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 10,
                ),
              ),
            ),
        ],
      ),
    );
  }

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// Time for today's messages, the date for older ones.
  String _when(BuildContext context, DateTime sentAt) {
    final now = DateTime.now();
    if (sentAt.year == now.year &&
        sentAt.month == now.month &&
        sentAt.day == now.day) {
      return TimeOfDay.fromDateTime(sentAt).format(context);
    }
    final date = '${sentAt.day} ${_months[sentAt.month - 1]}';
    return sentAt.year == now.year ? date : '$date ${sentAt.year}';
  }
}
