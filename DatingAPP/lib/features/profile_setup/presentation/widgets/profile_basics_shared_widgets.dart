part of '../screens/profile_basics_screen.dart';

bool _isOtherOption(String option) =>
    option == 'Other' || option == 'Other city';

const _otherPrompts = {
  'location': 'Enter your city',
  'education': 'Enter your education',
  'fieldOfStudy': 'Enter your field of study',
  'jobTitle': 'Enter your job title',
  'company': 'Enter your company',
  'languages': 'Add a language',
};

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
              // Turn off the theme's outline and fill; the parent draws the box.
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
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
          _isOtherOption(item)
              ? _otherTile(keyName, item, options, icon: icon)
              : _choiceTile(
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

  /// A value the member typed in, i.e. one that is not a listed option.
  String? _customValue(String keyName, List<String> options) {
    final value = _values[keyName]?.trim() ?? '';
    return value.isEmpty ||
            options.contains(value) ||
            value == 'Current location'
        ? null
        : value;
  }

  /// "Other" opens a popup for the member's own value instead of saving
  /// the word "Other". Once saved, the tile shows that value.
  Widget _otherTile(
    String keyName,
    String item,
    List<String> options, {
    IconData? icon,
  }) {
    final custom = _customValue(keyName, options);
    return _choiceTile(
      custom == null ? item : '$item: $custom',
      icon: icon,
      selected: custom != null || _values[keyName] == item,
      onTap: () async {
        final value = await _askOtherValue(
          _otherPrompts[keyName] ?? 'Enter your own',
          initial: custom,
        );
        if (value != null && mounted) _choose(keyName, value);
      },
    );
  }

  Future<String?> _askOtherValue(
    String title, {
    String? initial,
    int maxLength = 60,
  }) => showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) =>
        _OtherValueSheet(title: title, initial: initial, maxLength: maxLength),
  );

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

class _OtherValueSheet extends StatefulWidget {
  const _OtherValueSheet({
    required this.title,
    required this.initial,
    required this.maxLength,
  });

  final String title;
  final String? initial;
  final int maxLength;

  @override
  State<_OtherValueSheet> createState() => _OtherValueSheetState();
}

class _OtherValueSheetState extends State<_OtherValueSheet> {
  late final _value = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  void _save() {
    final value = _value.text.trim();
    if (value.isNotEmpty) Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      20,
      20,
      20,
      16 + MediaQuery.viewInsetsOf(context).bottom,
    ),
    child: ValueListenableBuilder<TextEditingValue>(
      valueListenable: _value,
      builder: (context, value, _) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.title, style: AppTypography.h3),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('other-value-field'),
            controller: _value,
            autofocus: true,
            maxLength: widget.maxLength,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 8),
          FilledButton(
            key: const ValueKey('other-value-save'),
            onPressed: value.text.trim().isEmpty ? null : _save,
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}
