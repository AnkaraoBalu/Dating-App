part of '../screens/home_screen.dart';

extension _HomeHeaderFilters on _HomeScreenState {
  Widget _header() => Row(
    children: [
      Expanded(
        child: const Align(
          alignment: Alignment.centerLeft,
          child: BrandLogo(),
        ),
      ),
      _headerAction(
        Icons.favorite_rounded,
        'Likes',
        _matchController?.incomingLikes.length ?? 0,
        _openLikes,
        color: AppColors.coralPressed,
      ),
      _headerAction(
        Icons.notifications_none_rounded,
        'Notifications',
        0,
        _openLikes,
      ),
      GestureDetector(
        onTap: () => _refresh(() => _selectedNav = 4),
        child: Container(
          width: 38,
          height: 38,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.coral, width: 1.5),
          ),
          child: ClipOval(
            child: ProfilePhotoView(
              _memberPhotos.isEmpty ? null : _memberPhotos.first,
            ),
          ),
        ),
      ),
    ],
  );

  Widget _headerAction(
    IconData icon,
    String label,
    int count,
    VoidCallback onTap, {
    Color color = AppColors.textPrimary,
  }) => IconButton(
    tooltip: label,
    onPressed: onTap,
    visualDensity: VisualDensity.compact,
    icon: Badge(
      isLabelVisible: count > 0,
      label: Text(count > 99 ? '99+' : '$count'),
      backgroundColor: AppColors.coralPressed,
      child: Icon(icon, color: color, size: 22),
    ),
  );

  Widget _quickFilters() => Row(
    children: [
      for (var index = 0; index < _HomeScreenState._tabs.length; index++) ...[
        if (index > 0) const SizedBox(width: 7),
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => _selectTab(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _selectedTab == index
                      ? AppColors.coralPressed
                      : AppColors.surfaceSecondary,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _selectedTab == index
                        ? AppColors.coral
                        : AppColors.border,
                  ),
                  boxShadow: _selectedTab == index
                      ? [
                          BoxShadow(
                            color: AppColors.coral.withValues(alpha: .2),
                            blurRadius: 12,
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  _HomeScreenState._tabs[index],
                  maxLines: 1,
                  style: AppTypography.bodySmall.copyWith(
                    color: _selectedTab == index
                        ? Colors.white
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
      const SizedBox(width: 8),
      Material(
        color: AppColors.surface,
        shape: const CircleBorder(side: BorderSide(color: AppColors.border)),
        child: IconButton(
          tooltip: 'Filters',
          visualDensity: VisualDensity.compact,
          onPressed: _openFilters,
          icon: const Icon(
            Icons.tune_rounded,
            color: AppColors.textPrimary,
            size: 20,
          ),
        ),
      ),
    ],
  );
}
