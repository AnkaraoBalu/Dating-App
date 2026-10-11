part of '../screens/profile_edit_screen.dart';

class _ProfileEditSheet extends StatefulWidget {
  const _ProfileEditSheet({
    required this.title,
    required this.fields,
    required this.onSave,
  });

  final String title;
  final Widget fields;
  final Future<bool> Function() onSave;

  @override
  State<_ProfileEditSheet> createState() => _ProfileEditSheetState();
}

class _ProfileEditSheetState extends State<_ProfileEditSheet> {
  bool _saving = false;

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final saved = await widget.onSave();
    if (!mounted) return;
    if (saved) Navigator.pop(context);
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    color: profileTextPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Close',
                onPressed: _saving ? null : () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ),
        Flexible(
          fit: FlexFit.loose,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: widget.fields,
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            child: ProfileButton(
              label: 'Save changes',
              busy: _saving,
              onPressed: _saving ? null : _save,
            ),
          ),
        ),
      ],
    ),
  );
}

class _PromptDraft {
  _PromptDraft(String question, String answer)
    : question = TextEditingController(text: question),
      answer = TextEditingController(text: answer);

  final TextEditingController question;
  final TextEditingController answer;

  void dispose() {
    question.dispose();
    answer.dispose();
  }
}

Widget _editorLabel(String value) => Padding(
  padding: const EdgeInsets.only(bottom: 10),
  child: Align(
    alignment: Alignment.centerLeft,
    child: Text(
      value,
      style: const TextStyle(
        color: profileTextPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
    ),
  ),
);

Widget _dropdownField({
  required String label,
  required String? value,
  required List<(String, String)> items,
  required ValueChanged<String?> onChanged,
}) => DropdownButtonFormField<String>(
  isExpanded: true,
  initialValue: items.any((item) => item.$1 == value) ? value : null,
  dropdownColor: profileSurface,
  style: const TextStyle(color: profileTextPrimary, fontSize: 15),
  iconEnabledColor: profileTextSecondary,
  decoration: InputDecoration(labelText: label),
  items: [
    DropdownMenuItem<String>(
      value: null,
      child: Text('Not added', style: TextStyle(color: profileTextSecondary)),
    ),
    for (final item in items)
      DropdownMenuItem(
        value: item.$1,
        child: Text(item.$2, style: const TextStyle(color: profileTextPrimary)),
      ),
  ],
  onChanged: onChanged,
);
