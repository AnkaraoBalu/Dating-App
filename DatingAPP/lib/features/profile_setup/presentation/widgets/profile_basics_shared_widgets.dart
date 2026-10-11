part of '../screens/profile_basics_screen.dart';

extension _ProfileBasicsShared on _ProfileBasicsScreenState {
  BoxDecoration _basicsCardDecoration({Color? color}) => BoxDecoration(
    color: color ?? AppColors.surface,
    border: Border.all(color: AppColors.border),
    borderRadius: BorderRadius.circular(16),
  );

  Widget _choiceTile(
    String title, {
    String? keyName,
    IconData? icon,
    bool selected = false,
    VoidCallback? onTap,
    bool compact = false,
  }) => InkWell(
    borderRadius: BorderRadius.circular(14),
    onTap: onTap ?? (keyName == null ? null : () => _choose(keyName, title)),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      margin: EdgeInsets.only(bottom: compact ? 6 : 8),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 10 : 13,
      ),
      decoration:
          _basicsCardDecoration(
            color: selected ? const Color(0xFFFFF0EC) : AppColors.surface,
          ).copyWith(
            border: Border.all(
              color: selected ? AppColors.coral : AppColors.border,
            ),
          ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 20,
              color: selected
                  ? AppColors.coralPressed
                  : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              title,
              style: AppTypography.body.copyWith(
                color: selected
                    ? AppColors.coralPressed
                    : AppColors.textPrimary,
              ),
            ),
          ),
          Icon(
            selected ? Icons.check_circle_rounded : Icons.circle_outlined,
            size: 21,
            color: selected ? AppColors.coral : AppColors.borderStrong,
          ),
        ],
      ),
    ),
  );

  Widget _searchBox({String hint = 'Search...'}) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.symmetric(horizontal: 13),
    decoration: _basicsCardDecoration(),
    child: Row(
      children: [
        const Icon(
          Icons.search_rounded,
          color: AppColors.textSecondary,
          size: 20,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: TextField(
            controller: _searchController,
            onChanged: (value) => _change(() => _search = value),
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        ),
        if (_search.isNotEmpty)
          IconButton(
            onPressed: () => _change(() {
              _searchController.clear();
              _search = '';
            }),
            icon: const Icon(Icons.close_rounded, size: 18),
            visualDensity: VisualDensity.compact,
          ),
      ],
    ),
  );

  Widget _optionList(String keyName, List<String> options, {IconData? icon}) {
    final filtered = options
        .where((item) => item.toLowerCase().contains(_search.toLowerCase()))
        .toList();
    return Column(
      children: [
        for (final item in filtered)
          _choiceTile(
            item,
            keyName: keyName,
            icon: icon,
            selected: _values[keyName] == item,
          ),
        if (filtered.isEmpty)
          _choiceTile(
            'Use “$_search”',
            icon: icon,
            selected: false,
            onTap: () => _choose(keyName, _search.trim()),
          ),
      ],
    );
  }

  Widget _sectionLabel(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 9, top: 4),
    child: Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: AppTypography.label.copyWith(color: AppColors.textSecondary),
      ),
    ),
  );
}
