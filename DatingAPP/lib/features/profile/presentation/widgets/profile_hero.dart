import 'package:flutter/material.dart';
import '../../models/member_profile.dart';
import 'profile_widgets.dart';

class ProfileHero extends StatelessWidget {
  const ProfileHero({
    super.key,
    required this.profile,
    required this.onOptions,
    required this.onSettings,
    required this.onPhotos,
  });
  final MemberProfile profile;
  final VoidCallback onOptions, onSettings, onPhotos;
  @override
  Widget build(BuildContext context) {
    final heroHeight = (MediaQuery.sizeOf(context).height * 0.58)
        .clamp(360.0, 560.0)
        .toDouble();

    return SizedBox(
      height: heroHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ProfilePhotoView(
            profile.photos.isEmpty ? null : profile.photos.first.url,
            fit: BoxFit.cover,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black26, Colors.transparent, Color(0xE5080A09)],
                stops: [0, .4, 1],
              ),
            ),
          ),
          Positioned(
            top: 8,
            left: 16,
            child: const Text(
              'My Profile',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 10,
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Profile options',
                  onPressed: onOptions,
                  icon: const Icon(Icons.more_horiz, color: Colors.white),
                ),
                IconButton(
                  tooltip: 'Profile settings',
                  onPressed: onSettings,
                  icon: const Icon(
                    Icons.settings_outlined,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            child: OutlinedButton.icon(
              onPressed: onPhotos,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.black45,
                side: const BorderSide(color: Colors.white38),
              ),
              icon: const Icon(Icons.camera_alt_outlined, size: 16),
              label: const Text('Edit photos'),
            ),
          ),
        ],
      ),
    );
  }
}
