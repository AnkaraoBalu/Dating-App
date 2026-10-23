import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/theme.dart';
import '../../../matches/models/match_model.dart';
import '../../models/chat_models.dart';
import '../widgets/chat_media.dart';

enum SharedItemKind { links, locations }

final _linkPattern = RegExp(
  r'(?:https?://|www\.)[^\s<>"]+',
  caseSensitive: false,
);

/// A link or location found in the conversation, newest first.
class SharedItem {
  const SharedItem({
    required this.title,
    required this.uri,
    required this.message,
  });
  final String title;
  final Uri uri;
  final ChatMessage message;
}

List<SharedItem> sharedItems(List<ChatMessage> messages, SharedItemKind kind) {
  final items = <SharedItem>[];
  final newestFirst = [...messages]
    ..sort((a, b) => b.sentAt.compareTo(a.sentAt));
  for (final message in newestFirst) {
    if (kind == SharedItemKind.locations) {
      final lat = message.latitude;
      final lng = message.longitude;
      if (message.type != 'location' || lat == null || lng == null) continue;
      items.add(
        SharedItem(
          title: '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
          uri: Uri.parse('https://maps.google.com/?q=$lat,$lng'),
          message: message,
        ),
      );
      continue;
    }
    for (final match in _linkPattern.allMatches(message.text)) {
      // Drop punctuation that ends the sentence rather than the link.
      final raw = match.group(0)!.replaceFirst(RegExp(r'[.,!?;:)\]]+$'), '');
      final uri = Uri.tryParse(
        raw.toLowerCase().startsWith('www.') ? 'https://$raw' : raw,
      );
      if (uri == null || uri.host.isEmpty) continue;
      items.add(SharedItem(title: raw, uri: uri, message: message));
    }
  }
  return items;
}

class SharedItemsScreen extends StatelessWidget {
  const SharedItemsScreen({
    super.key,
    required this.match,
    required this.messages,
    required this.kind,
  });
  final MatchRecord match;
  final List<ChatMessage> messages;
  final SharedItemKind kind;

  bool get _links => kind == SharedItemKind.links;

  Future<void> _open(BuildContext context, Uri uri) async {
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened && context.mounted) {
        showChatNotice(context, 'Nothing on this phone could open that.');
      }
    } catch (_) {
      if (context.mounted) showChatNotice(context, 'Could not open that.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = sharedItems(messages, kind);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        title: Text(_links ? 'Shared links' : 'Shared locations'),
      ),
      body: items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _links
                      ? 'No links shared with ${match.person.name} yet.'
                      : 'No locations shared with ${match.person.name} yet.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: items.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: AppColors.border),
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  leading: Icon(
                    _links ? Icons.link_rounded : Icons.location_on_outlined,
                    color: AppColors.coral,
                  ),
                  title: Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  subtitle: Text(
                    item.message.fromMe ? 'You' : match.person.name,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  trailing: const Icon(
                    Icons.open_in_new_rounded,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                  onTap: () => _open(context, item.uri),
                );
              },
            ),
    );
  }
}
