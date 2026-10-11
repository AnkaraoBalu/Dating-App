import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/profile_controller.dart';
import '../../models/member_profile.dart';
import '../widgets/profile_widgets.dart';
import 'profile_photo_edit_screen.dart';

class ProfilePhotoGalleryScreen extends StatelessWidget {
  const ProfilePhotoGalleryScreen({super.key, required this.controller});
  final ProfileController controller;
  Future<void> _add(BuildContext context) async {
    await profileAction(context, () async {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        maxHeight: 1800,
        imageQuality: 85,
      );
      if (image != null) await controller.addPhoto(File(image.path));
    });
  }

  Future<void> _options(
    BuildContext context,
    MemberPhoto photo,
    bool main,
  ) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: profileSurface,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.crop, color: profileTextPrimary),
              title: const Text(
                'Edit photo',
                style: const TextStyle(color: profileTextPrimary),
              ),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            if (!main)
              ListTile(
                leading: const Icon(
                  Icons.star_outline,
                  color: profileTextPrimary,
                ),
                title: const Text(
                  'Make main photo',
                  style: const TextStyle(color: profileTextPrimary),
                ),
                onTap: () => Navigator.pop(context, 'main'),
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: profileAccent),
              title: const Text(
                'Remove photo',
                style: TextStyle(color: profileAccent),
              ),
              onTap: () => Navigator.pop(context, 'remove'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    if (action == 'edit') {
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) =>
              ProfilePhotoEditScreen(controller: controller, photo: photo),
        ),
      );
      return;
    }
    if (action == 'main') {
      await profileAction(context, () => controller.makeMain(photo.id));
      return;
    }
    if (action == 'remove') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Remove this photo?'),
          content: const Text('You can upload it again later.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove'),
            ),
          ],
        ),
      );
      if (confirmed == true && context.mounted) {
        await profileAction(context, () => controller.deletePhoto(photo.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (_, _) {
      final photos = controller.profile!.photos;
      return ProfilePage(
        title: 'My Photos',
        bottom: ProfileButton(
          label: photos.length >= 6 ? '6 of 6 photos added' : 'Add photos',
          busy: controller.saving,
          onPressed: photos.length >= 6 ? null : () => _add(context),
        ),
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            ProfileSection(
              '${photos.length}/6 photos',
              subtitle: 'Tap a photo to edit it or choose your main photo',
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: photos.length + (photos.length < 6 ? 1 : 0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: .78,
              ),
              itemBuilder: (_, i) {
                if (i == photos.length) {
                  return InkWell(
                    onTap: controller.saving ? null : () => _add(context),
                    child: Container(
                      decoration: BoxDecoration(
                        color: profileSurface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: profileBorder),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, size: 34, color: profileTextPrimary),
                          SizedBox(height: 8),
                          Text(
                            'Add photo',
                            style: TextStyle(color: profileTextPrimary),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return InkWell(
                  onTap: controller.saving
                      ? null
                      : () => _options(context, photos[i], i == 0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ProfilePhotoView(photos[i].url),
                        Positioned(
                          left: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              i == 0 ? 'Main photo' : 'Photo ${i + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const Positioned(
                          right: 8,
                          top: 8,
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.black54,
                            child: Icon(
                              Icons.more_horiz,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );
    },
  );
}
