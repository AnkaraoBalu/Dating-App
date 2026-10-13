import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../data/vibe_rooms_api.dart';
import '../../data/vibe_categories.dart';
import '../../data/vibe_artwork.dart';
import '../../data/vibe_room_store.dart';
import 'room_detail_screen.dart';

class CreateVibeRoomScreen extends StatefulWidget {
  const CreateVibeRoomScreen({super.key, this.api, this.initialCategoryId});

  final VibeRoomsApi? api;
  final String? initialCategoryId;

  @override
  State<CreateVibeRoomScreen> createState() => _CreateVibeRoomScreenState();
}

class _CreateVibeRoomScreenState extends State<CreateVibeRoomScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late String _categoryId;
  late String _coverAsset;
  bool _pickedCover = false;
  int _maxParticipants = 25;
  bool _inviteOnly = false;
  bool _creating = false;

  static const _covers = VibeArtwork.covers;

  @override
  void initState() {
    super.initState();
    _categoryId =
        VibeCategories.byId(widget.initialCategoryId ?? '')?.id ??
        VibeCategories.all.first.id;
    _coverAsset = VibeArtwork.forCategory(_categoryId);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final category = VibeCategories.byId(_categoryId)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        title: Text(
          'Create a vibe room',
          style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(19, 8, 19, 24),
            children: [
              Text(
                'Give your room a welcoming first impression.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              _coverPicker(),
              const SizedBox(height: 17),
              _label('Room name'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                maxLength: 40,
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Add a room name.'
                    : null,
                decoration: _decoration('e.g. Coffee & Conversations'),
              ),
              const SizedBox(height: 7),
              _label('Description'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descriptionController,
                minLines: 2,
                maxLines: 3,
                maxLength: 140,
                decoration: _decoration('What’s this room about?'),
              ),
              const SizedBox(height: 12),
              _label('Category'),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _categoryId,
                decoration: _decoration(null),
                items: [
                  for (final item in VibeCategories.all)
                    DropdownMenuItem(
                      value: item.id,
                      child: Text('${item.emoji}  ${item.title}'),
                    ),
                ],
                onChanged: (value) => setState(() {
                  _categoryId = value ?? _categoryId;
                  if (!_pickedCover) {
                    _coverAsset = VibeArtwork.forCategory(_categoryId);
                  }
                }),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _label('Maximum participants')),
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
              const SizedBox(height: 4),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Invite-only room',
                  style: AppTypography.label.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  'Only people with your invite can join.',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                value: _inviteOnly,
                activeTrackColor: AppColors.coral,
                onChanged: (value) => setState(() => _inviteOnly = value),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.peachSoft,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  '${category.emoji}  Your room will appear under ${category.title}. You can edit settings after creating it.',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 11),
          child: FilledButton(
            onPressed: _creating ? null : _create,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.coral,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
            ),
            child: _creating
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Create room'),
          ),
        ),
      ),
    );
  }

  Widget _coverPicker() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Room cover',
        style: AppTypography.label.copyWith(color: AppColors.textPrimary),
      ),
      const SizedBox(height: 7),
      SizedBox(
        height: 100,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _covers.length,
          separatorBuilder: (_, _) => const SizedBox(width: 9),
          itemBuilder: (context, index) {
            final cover = _covers[index];
            final asset = cover.asset;
            final selected = _coverAsset == asset;
            return Semantics(
              label: cover.label,
              button: true,
              selected: selected,
              child: InkWell(
                onTap: () => setState(() {
                  _coverAsset = asset;
                  _pickedCover = true;
                }),
                child: Container(
                  width: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: selected ? AppColors.coral : AppColors.border,
                      width: selected ? 3 : 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(
                              asset,
                              fit: BoxFit.cover,
                              excludeFromSemantics: true,
                            ),
                            if (selected)
                              const Positioned(
                                top: 5,
                                right: 5,
                                child: Icon(
                                  Icons.check_circle,
                                  color: AppColors.coral,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(7),
                        child: Text(
                          cover.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ],
  );

  Widget _label(String text) => Text(
    text,
    style: AppTypography.label.copyWith(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w800,
    ),
  );

  InputDecoration _decoration(String? hint) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: AppColors.surface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.border),
    ),
  );

  Future<void> _create() async {
    if (!_formKey.currentState!.validate()) return;
    final category = VibeCategories.byId(_categoryId)!;
    final title = _nameController.text.trim();
    final description = _descriptionController.text.trim().isEmpty
        ? 'A welcoming space to meet people who share your vibe.'
        : _descriptionController.text.trim();
    setState(() => _creating = true);
    try {
      final room = widget.api == null
          ? VibeRoomStore.instance.create(
              title: title,
              description: description,
              categoryId: category.id,
              emoji: category.emoji,
              coverAsset: _coverAsset,
              tags: [category.title, ...category.interests.take(2)],
              maxParticipants: _maxParticipants,
              inviteOnly: _inviteOnly,
            )
          : await widget.api!.createRoom(
              title: title,
              description: description,
              categoryId: category.id,
              emoji: category.emoji,
              coverAsset: _coverAsset,
              tags: [category.title, ...category.interests.take(2)],
              maxParticipants: _maxParticipants,
              inviteOnly: _inviteOnly,
            );
      if (widget.api != null) VibeRoomStore.instance.cacheRoom(room);
      if (!mounted) return;
      // Back to the screen that opened this one (Vibes or a category), which
      // shows the new room from the store; offer a shortcut into the room.
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text('“${room.title}” created ✨'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Open',
            onPressed: () => navigator.push<void>(
              MaterialPageRoute<void>(
                builder: (_) => RoomDetailScreen(room: room, api: widget.api),
              ),
            ),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _creating = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not create room: $error')));
    }
  }
}
