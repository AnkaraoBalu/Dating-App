import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/theme.dart';
import '../../data/profile_controller.dart';
import '../screens/profile_edit_screen.dart';
import '../screens/profile_preview_screen.dart';
import 'profile_widgets.dart';

Future<void> showProfileOptions(
  BuildContext context,
  ProfileController controller,
) async {
  final action = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final item in [
                ('edit', 'Edit profile', Icons.edit_outlined),
                ('copy', 'Copy profile summary', Icons.copy_outlined),
                ('preview', 'Preview profile', Icons.visibility_outlined),
                (
                  'pause',
                  controller.profile!.flag('showProfile')
                      ? 'Pause profile'
                      : 'Resume profile',
                  Icons.pause_circle_outline,
                ),
              ])
                ListTile(
                  leading: Icon(item.$3, color: AppColors.textPrimary),
                  title: Text(
                    item.$2,
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  onTap: () => Navigator.pop(context, item.$1),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  if (!context.mounted) return;
  if (action == 'edit') {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/profile/edit'),
        builder: (_) => ProfileEditScreen(controller: controller),
      ),
    );
    return;
  }
  if (action == 'preview') {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => ProfilePreviewScreen(controller: controller),
      ),
    );
    return;
  }
  if (action == 'copy') {
    final p = controller.profile!;
    await Clipboard.setData(
      ClipboardData(
        text:
            '${p.name}${p.age == null ? '' : ', ${p.age}'}\n${p.text('location')}\n${p.text('bio')}',
      ),
    );
    if (context.mounted) profileNotice(context, 'Profile summary copied.');
    return;
  }
  if (action == 'pause') {
    await profileAction(
      context,
      () => controller.update({
        'showProfile': !controller.profile!.flag('showProfile'),
      }),
    );
  }
}
