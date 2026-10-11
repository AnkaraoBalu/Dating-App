part of '../screens/home_screen.dart';

extension _HomeBottomNavigation on _HomeScreenState {
  Widget _bottomNavigation() => Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border(top: const BorderSide(color: AppColors.border)),
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 7, 8, 4),
        child: Row(
          children: List.generate(_HomeScreenState._navLabels.length, (index) {
            final active = _selectedNav == index;
            return Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(17),
                onTap: () {
                  _refresh(() => _selectedNav = index);
                  if (index == 2 || index == 3) _matchController?.load();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 3,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: active ? AppColors.coralSoft : Colors.transparent,
                    borderRadius: BorderRadius.circular(15),
                    border: active
                        ? Border.all(
                            color: AppColors.coral.withValues(alpha: .22),
                          )
                        : null,
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color: AppColors.coral.withValues(alpha: .12),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : const [],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          AnimatedScale(
                            scale: active ? 1.08 : 1,
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOutBack,
                            child: Icon(
                              active
                                  ? _HomeScreenState._selectedNavIcons[index]
                                  : _HomeScreenState._navIcons[index],
                              color: active
                                  ? AppColors.coralPressed
                                  : AppColors.textSecondary,
                              size: 23,
                            ),
                          ),
                          if (index == 2 ||
                              (index == 4 &&
                                  _matchController != null &&
                                  _matchController!.incomingLikes.isNotEmpty))
                            Positioned(
                              right: -3,
                              top: 0,
                              child: index == 4
                                  ? _UnreadChatBadge(
                                      count: _matchController!
                                          .incomingLikes
                                          .length,
                                    )
                                  : const CircleAvatar(
                                      radius: 3,
                                      backgroundColor: AppColors.coral,
                                    ),
                            ),
                          if (index == 3 && _unreadChatCount > 0)
                            Positioned(
                              right: -8,
                              top: -7,
                              child: _UnreadChatBadge(count: _unreadChatCount),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _HomeScreenState._navLabels[index],
                        style: AppTypography.caption.copyWith(
                          color: active
                              ? AppColors.coralPressed
                              : AppColors.textSecondary,
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    ),
  );
}

class _UnreadChatBadge extends StatelessWidget {
  const _UnreadChatBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: const BoxDecoration(
        color: AppColors.coral,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          count > 99 ? '99+' : '$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
