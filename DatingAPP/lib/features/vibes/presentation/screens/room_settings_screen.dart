import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../data/vibe_categories.dart';
import '../../data/vibe_room_store.dart';
import '../../data/vibe_rooms_api.dart';
import '../../models/vibe_room.dart';

class RoomSettingsScreen extends StatefulWidget {
  const RoomSettingsScreen({super.key, required this.room, this.api});

  final VibeRoom room;
  final VibeRoomsApi? api;

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
  late String _categoryId = widget.room.categoryId;
  late String _emoji = widget.room.emoji;
  bool _saving = false;
  bool _deleting = false;

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
      actions: [
        TextButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving…' : 'Save'),
        ),
      ],
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
                '$_emoji ${VibeCategories.byId(_categoryId)?.title ?? 'Other'}',
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
          // Only the person who created the room can delete it.
          if (widget.room.isHostedByMe) ...[
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: _deleting ? null : _delete,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.error,
                alignment: Alignment.centerLeft,
              ),
              icon: _deleting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline_rounded),
              label: Text(_deleting ? 'Deleting…' : 'Delete room'),
            ),
          ],
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

  Future<void> _save() async {
    final title = _nameController.text.trim();
    if (title.isEmpty) {
      _notice('Room name can’t be empty.');
      return;
    }
    final description = _descriptionController.text.trim();
    final api = widget.api;
    if (api == null) {
      VibeRoomStore.instance.updateRoom(
        widget.room,
        title: title,
        description: description,
        inviteOnly: _inviteOnly,
        maxParticipants: _maxParticipants,
        categoryId: _categoryId,
        emoji: _emoji,
      );
      Navigator.pop(context);
      return;
    }
    setState(() => _saving = true);
    try {
      final updated = await api.updateRoom(
        widget.room.id,
        title: title,
        description: description.isEmpty ? null : description,
        inviteOnly: _inviteOnly,
        maxParticipants: _maxParticipants,
        categoryId: _categoryId,
        emoji: _emoji,
      );
      VibeRoomStore.instance.cacheRoom(updated);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      _notice('Could not save room settings: $error');
    }
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
                trailing: category.id == _categoryId
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
    setState(() {
      _categoryId = category.id;
      _emoji = category.emoji;
    });
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete this room?'),
        content: const Text(
          'This deletes the room and its chat for everyone. It can’t be undone.',
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
    final api = widget.api;
    if (api == null) {
      _notice('Could not delete this room. Try again.');
      return;
    }
    setState(() => _deleting = true);
    try {
      await api.deleteRoom(widget.room.id);
    } catch (error) {
      if (!mounted) return;
      setState(() => _deleting = false);
      _notice('Could not delete this room: $error');
      return;
    }
    VibeRoomStore.instance.delete(widget.room);
    if (mounted) Navigator.of(context).pop();
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
