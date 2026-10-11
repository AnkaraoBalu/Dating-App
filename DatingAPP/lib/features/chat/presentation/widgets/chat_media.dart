import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../home/data/home_discover_data.dart';
import '../screens/chat_image_viewer.dart';

Widget chatPersonAvatar(HomePerson person, {required double radius}) {
  final image = person.image;
  return CircleAvatar(
    radius: radius,
    backgroundColor: AppColors.surfaceSecondary,
    child: ClipOval(
      child: SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: image.isEmpty
            ? const Icon(Icons.person, color: AppColors.textTertiary)
            : chatPhoto(image),
      ),
    ),
  );
}

Widget chatProfilePhotoPreview(BuildContext context, String image) => InkWell(
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute<void>(builder: (_) => ChatImageViewer(image: image)),
  ),
  borderRadius: BorderRadius.circular(12),
  child: SizedBox(
    width: 104,
    height: 118,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: chatPhoto(image),
    ),
  ),
);

Widget chatPhoto(String path) {
  Widget fallback() => const ColoredBox(
    color: AppColors.surfaceSecondary,
    child: Center(
      child: Icon(Icons.person_outline_rounded, color: AppColors.textTertiary),
    ),
  );
  return path.startsWith('http')
      ? Image.network(
          path,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => fallback(),
        )
      : Image.asset(
          path,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => fallback(),
        );
}

void showChatNotice(BuildContext context, String message) =>
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
