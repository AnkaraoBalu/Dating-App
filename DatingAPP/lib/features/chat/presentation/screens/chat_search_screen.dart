import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../matches/models/match_model.dart';
import '../../models/chat_models.dart';

class ChatSearchScreen extends StatefulWidget {
  const ChatSearchScreen({super.key, required this.match});
  final MatchRecord match;
  @override
  State<ChatSearchScreen> createState() => _ChatSearchScreenState();
}

class _ChatSearchScreenState extends State<ChatSearchScreen> {
  final _search = TextEditingController();
  late final List<ChatMessage> _messages = ChatDemoData.messagesFor(
    widget.match,
  );
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.toLowerCase();
    final results = _messages
        .where(
          (message) =>
              query.isEmpty || message.text.toLowerCase().contains(query),
        )
        .toList();
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
            border: InputBorder.none,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            '${results.length} results',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
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
                TimeOfDay.fromDateTime(message.sentAt).format(context),
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
}
