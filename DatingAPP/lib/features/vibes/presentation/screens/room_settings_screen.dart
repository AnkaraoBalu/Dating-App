import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../data/vibe_categories.dart';
import '../../data/vibe_room_store.dart';
import '../../models/vibe_room.dart';

class RoomSettingsScreen extends StatefulWidget {
  const RoomSettingsScreen({super.key, required this.room});

  final VibeRoom room;

  @override
  State<RoomSettingsScreen> createState() => _RoomSettingsScreenState();
}

class _RoomSettingsScreenState extends State<RoomSettingsScreen> {
  late final _nameController = TextEditingController(text: widget.room.title);
  late final _descriptionController = TextEditingController(
    text: widget.room.description,
  );
  late bool _inviteOnly = widget.room.inviteOnly;
  late int _maxParticipants = widget.room.maxParticipants;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      title: Text(
        'Room settings',
        style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
      ),
      actions: [TextButton(onPressed: _save, child: const Text('Save'))],
    ),
    body: SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 9, 18, 24),
        children: [
          _SectionLabel('Room details'),
          const SizedBox(height: 7),
          TextField(
            controller: _nameController,
            maxLength: 40,
            decoration: _input('Room name'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            minLines: 2,
            maxLines: 3,
            maxLength: 140,
            decoration: _input('Description'),
          ),
          const SizedBox(height: 15),
          _SectionLabel('Room category'),
          const SizedBox(height: 9),
          _SettingRow(
            icon: Icons.category_outlined,
            title: 'Category',
            value:
                '${widget.room.emoji} ${VibeCategories.byId(widget.room.categoryId)?.title ?? 'Other'}',
            onTap: _editCategory,
          ),
          const SizedBox(height: 14),
          _SectionLabel('Access and capacity'),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Invite-only room',
              style: AppTypography.label.copyWith(color: AppColors.textPrimary),
            ),
            subtitle: Text(
              _inviteOnly
                  ? 'Only invited people can join.'
                  : 'Anyone can find and join this room.',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            value: _inviteOnly,
            activeTrackColor: AppColors.coral,
            onChanged: (value) => setState(() => _inviteOnly = value),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Maximum participants',
                  style: AppTypography.label.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '$_maxParticipants',
                style: AppTypography.label.copyWith(
                  color: AppColors.coralPressed,
                ),
              ),
            ],
          ),
          Slider(
            value: _maxParticipants.toDouble(),
            min: 10,
            max: 100,
            divisions: 9,
            activeColor: AppColors.coral,
            onChanged: (value) =>
                setState(() => _maxParticipants = value.round()),
          ),
          const SizedBox(height: 11),
          _SectionLabel('Community'),
          _SettingRow(
            icon: Icons.shield_outlined,
            title: 'Room guidelines',
            value: '${widget.room.guidelines.length} rules',
            onTap: _editGuidelines,
          ),
          _SettingRow(
            icon: Icons.people_outline_rounded,
            title: 'Moderators',
            value: '3',
            onTap: () => _notice('Moderator management is a local preview.'),
          ),
          _SettingRow(
            icon: Icons.block_rounded,
            title: 'Blocked users',
            value: '1',
            onTap: () => _notice('No blocked users in this demo room.'),
          ),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: _delete,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.error,
              alignment: Alignment.centerLeft,
            ),
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Delete room'),
          ),
        ],
      ),
    ),
  );

  InputDecoration _input(String hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: AppColors.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.border),
    ),
  );

  void _save() {
    if (_nameController.text.trim().isEmpty) {
      _notice('Room name can’t be empty.');
      return;
    }
    VibeRoomStore.instance.updateRoom(
      widget.room,
      title: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      inviteOnly: _inviteOnly,
      maxParticipants: _maxParticipants,
    );
    Navigator.pop(context);
  }

  Future<void> _editGuidelines() async {
    final controller = TextEditingController(
      text: widget.room.guidelines.join('\n'),
    );
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Room guidelines'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(hintText: 'One guideline per line'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null) return;
    VibeRoomStore.instance.updateRoom(
      widget.room,
      guidelines: value
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList(),
    );
    if (mounted) setState(() {});
  }

  Future<void> _editCategory() async {
    final categoryId = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 9),
              child: Text(
                'Choose a category',
                style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
              ),
            ),
            for (final category in VibeCategories.all)
              ListTile(
                leading: Text(
                  category.emoji,
                  style: const TextStyle(fontSize: 23),
                ),
                title: Text(category.title),
                trailing: category.id == widget.room.categoryId
                    ? const Icon(Icons.check_rounded, color: AppColors.coral)
                    : null,
                onTap: () => Navigator.pop(context, category.id),
              ),
          ],
        ),
      ),
    );
    if (categoryId == null || !mounted) return;
    final category = VibeCategories.byId(categoryId)!;
    VibeRoomStore.instance.updateRoom(
      widget.room,
      categoryId: category.id,
      emoji: category.emoji,
    );
    setState(() {});
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete this room?'),
        content: const Text(
          'This removes the room from your local room lists.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    VibeRoomStore.instance.delete(widget.room);
    Navigator.of(context).pop();
  }

  void _notice(String message) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message)));
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: AppTypography.label.copyWith(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w800,
    ),
  );
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    required this.value,
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    onTap: onTap,
    leading: Icon(icon, color: AppColors.textSecondary),
    title: Text(
      title,
      style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
    ),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
        ),
        if (onTap != null)
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textTertiary,
          ),
      ],
    ),
  );
}
