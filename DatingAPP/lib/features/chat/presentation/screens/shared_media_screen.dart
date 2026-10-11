import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../matches/models/match_model.dart';
import '../../models/chat_models.dart';
import 'chat_image_viewer.dart';

class SharedMediaScreen extends StatelessWidget {
  const SharedMediaScreen({
    super.key,
    required this.match,
    required this.messages,
  });
  final MatchRecord match;
  final List<ChatMessage> messages;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      surfaceTintColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: const Text('Shared media'),
    ),
    body: Column(
      children: [
        const _MediaTabs(),
        Expanded(
          child: _photos.isEmpty
              ? const Center(
                  child: Text(
                    'Photos shared in this chat will appear here.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 7,
                    mainAxisSpacing: 7,
                  ),
                  itemCount: _photos.length,
                  itemBuilder: (context, index) {
                    final message = _photos[index];
                    final image =
                        message.mediaUrl ?? message.mediaLocalPath ?? '';
                    return InkWell(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => ChatImageViewer(image: image),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Image.network(
                          image,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const ColoredBox(
                            color: AppColors.surfaceSecondary,
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    ),
  );

  List<ChatMessage> get _photos => messages
      .where((message) => message.type == 'image' && message.mediaUrl != null)
      .toList(growable: false);
}

class _MediaTabs extends StatefulWidget {
  const _MediaTabs();
  @override
  State<_MediaTabs> createState() => _MediaTabsState();
}

class _MediaTabsState extends State<_MediaTabs> {
  int selected = 0;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    child: Row(
      children: ['Photos', 'Videos', 'Links', 'Files'].indexed.map((entry) {
        final active = entry.$1 == selected;
        return Expanded(
          child: InkWell(
            onTap: () => setState(() => selected = entry.$1),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: active ? AppColors.coral : AppColors.surfaceSecondary,
                borderRadius: BorderRadius.circular(19),
              ),
              child: Center(
                child: Text(
                  entry.$2,
                  style: TextStyle(
                    color: active ? Colors.white : AppColors.textPrimary,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    ),
  );
}
