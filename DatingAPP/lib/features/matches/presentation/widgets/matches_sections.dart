part of '../screens/matches_screen.dart';

// Empty states, round buttons, filter sheet and small match widgets.
extension _MatchesSections on _MatchesScreenState {
  Widget _emptyState({
    required bool isSearching,
    required bool hasMatches,
  }) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 118,
                  height: 118,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.coral.withValues(alpha: .1),
                    border: Border.all(
                      color: AppColors.coral.withValues(alpha: .25),
                    ),
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: AppColors.coral,
                    size: 56,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _emptyTitle(isSearching: isSearching, hasMatches: hasMatches),
                  style: AppTypography.h3.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 19,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  _emptyDescription(
                    isSearching: isSearching,
                    hasMatches: hasMatches,
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                if (!isSearching && !(_filter == 2 && hasMatches)) ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: widget.onExplorePeople,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.coral,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      child: const Text('Explore People'),
                    ),
                  ),
                  if (!hasMatches) ...[
                    const SizedBox(height: 22),
                    const _MatchTipsCard(),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );

  String _emptyTitle({required bool isSearching, required bool hasMatches}) {
    if (isSearching) return 'No matches found';
    if (_filter == 2 && hasMatches) return 'No messages yet';
    if (_filter == 1 && hasMatches) return 'No new matches yet';
    return 'No matches yet';
  }

  String _emptyDescription({
    required bool isSearching,
    required bool hasMatches,
  }) {
    if (isSearching) return 'Try a different name.';
    if (_filter == 2 && hasMatches) {
      return 'Your matches will appear here when you start a conversation.';
    }
    if (_filter == 1 && hasMatches) {
      return 'Keep exploring. New matches will show up here.';
    }
    return 'Keep exploring and be yourself. Your next connection could be just around the corner.';
  }

  Widget _roundButton(
    IconData icon, {
    required VoidCallback onTap,
    int badge = 0,
  }) => Material(
    color: AppColors.surfaceSecondary,
    shape: const CircleBorder(),
    child: InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: SizedBox(
        width: 38,
        height: 38,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(child: Icon(icon, color: AppColors.textPrimary, size: 20)),
            if (badge > 0)
              Positioned(
                right: -2,
                top: -3,
                child: Container(
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: const BoxDecoration(
                    color: AppColors.coral,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      badge > 99 ? '99+' : '$badge',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );

  void _showFilterSheet(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter matches',
              style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 18),
            for (var index = 0; index < 3; index++)
              ListTile(
                leading: Icon(
                  index == 0
                      ? Icons.schedule_rounded
                      : index == 1
                      ? Icons.sort_by_alpha_rounded
                      : Icons.mark_chat_unread_outlined,
                  color: AppColors.coral,
                ),
                title: Text(
                  [
                    'Recent activity',
                    'Alphabetical (A–Z)',
                    'Unread messages',
                  ][index],
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
                trailing: _sort == index
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.coral,
                      )
                    : null,
                onTap: () {
                  _refresh(() => _sort = index);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    ),
  );
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.person, required this.size});
  final HomePerson person;
  final double size;

  @override
  Widget build(BuildContext context) {
    final image = person.image;
    final provider = image.startsWith('http')
        ? NetworkImage(image) as ImageProvider
        : AssetImage(image);
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.coral, width: 1.4),
      ),
      child: CircleAvatar(
        backgroundColor: AppColors.surfaceSecondary,
        backgroundImage: image.isEmpty ? null : provider,
        child: image.isEmpty
            ? const Icon(Icons.person, color: AppColors.textTertiary)
            : null,
      ),
    );
  }
}

Widget _avatar(HomePerson person, {required double size}) =>
    _Avatar(person: person, size: size);

class _NewBadge extends StatelessWidget {
  const _NewBadge();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: AppColors.coral,
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Text(
      'NEW',
      style: TextStyle(
        color: Colors.white,
        fontSize: 8,
        fontWeight: FontWeight.w800,
        letterSpacing: .3,
      ),
    ),
  );
}

class _MatchTipsCard extends StatelessWidget {
  const _MatchTipsCard();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tips to get more matches',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 10),
        for (final item in [
          (
            'Complete your profile',
            'Add a few more photos',
            Icons.photo_camera_outlined,
          ),
          (
            'Add your interests',
            'Get better matches',
            Icons.interests_outlined,
          ),
          ('Be active', 'People notice active users', Icons.bolt_rounded),
        ])
          Padding(
            padding: const EdgeInsets.only(top: 9),
            child: Row(
              children: [
                Icon(item.$3, color: AppColors.coral, size: 18),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.$1,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      item.$2,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    ),
  );
}
