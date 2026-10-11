part of '../screens/chats_screen.dart';

// Empty state and avatar for the chat list.
extension _ChatsListSections on _ChatsScreenState {
  Widget _emptyState(bool noMatches) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.coral.withValues(alpha: .1),
            ),
            child: const Icon(
              Icons.forum_rounded,
              color: AppColors.coral,
              size: 54,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            noMatches ? 'No conversations yet' : 'No chats here',
            style: AppTypography.h3.copyWith(
              color: AppColors.textPrimary,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            noMatches
                ? 'When you match with someone, you can start a conversation here.'
                : 'There are no chats in this filter right now.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          if (noMatches) ...[
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Explore people to meet someone new.'),
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.coral,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Explore People'),
              ),
            ),
          ],
        ],
      ),
    ),
  );
}

class _ChatAvatar extends StatelessWidget {
  const _ChatAvatar({required this.match});
  final MatchRecord match;

  @override
  Widget build(BuildContext context) {
    final image = match.person.image;
    final provider = image.startsWith('http')
        ? NetworkImage(image) as ImageProvider
        : AssetImage(image);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: AppColors.surfaceSecondary,
          backgroundImage: image.isEmpty ? null : provider,
          child: image.isEmpty
              ? const Icon(Icons.person, color: AppColors.textTertiary)
              : null,
        ),
        if (match.person.online)
          const Positioned(
            right: 0,
            bottom: 0,
            child: CircleAvatar(
              radius: 6,
              backgroundColor: Color(0xFF27C98B),
              child: CircleAvatar(
                radius: 3.2,
                backgroundColor: Color(0xFF27C98B),
              ),
            ),
          ),
      ],
    );
  }
}
