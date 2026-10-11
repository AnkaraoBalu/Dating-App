import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../../../core/theme/theme.dart';

Future<bool?> confirmChatLocationShare(
  BuildContext context,
) => showDialog<bool>(
  context: context,
  builder: (context) => AlertDialog(
    backgroundColor: AppColors.surface,
    title: const Text(
      'Share your location?',
      style: TextStyle(color: AppColors.textPrimary),
    ),
    content: const Text(
      'This sends your approximate current location once to this match. It will not keep tracking you.',
      style: TextStyle(color: AppColors.textSecondary),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context, false),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, true),
        child: const Text('Share once'),
      ),
    ],
  ),
);

/// Reads the device location once and rounds it to roughly 100 m, so precise
/// coordinates are never sent or persisted.
Future<(double, double)> currentApproximatePosition() async {
  if (!await Geolocator.isLocationServiceEnabled()) {
    throw Exception('Turn on device location to share it.');
  }
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.deniedForever) {
    throw Exception('Allow location access in device settings.');
  }
  if (permission == LocationPermission.denied) {
    throw Exception('Location permission was not granted.');
  }
  final position = await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.low,
      timeLimit: Duration(seconds: 15),
    ),
  );
  return (
    (position.latitude * 1000).round() / 1000,
    (position.longitude * 1000).round() / 1000,
  );
}
