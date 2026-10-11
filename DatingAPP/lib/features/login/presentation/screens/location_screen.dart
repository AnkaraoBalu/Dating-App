import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/theme.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key, this.onAllow, this.onSkip});

  final Future<void> Function(double latitude, double longitude)? onAllow;
  final Future<void> Function()? onSkip;

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  bool _busy = false;

  Future<void> _requestLocation() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        await Geolocator.openLocationSettings();
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        await Geolocator.openAppSettings();
        throw Exception(
          'Enable location access for Matchify in device settings.',
        );
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
      await widget.onAllow?.call(
        (position.latitude * 100).roundToDouble() / 100,
        (position.longitude * 100).roundToDouble() / 100,
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.darkBackground,
    body: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(AppAssets.locationBackground, fit: BoxFit.cover),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x75081714), Color(0x22081714), Color(0xB5081714)],
              stops: [0, 0.48, 1],
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 26),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    tooltip: 'Back',
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Spacer(flex: 5),
                Text(
                  'Enable location',
                  textAlign: TextAlign.center,
                  style: AppTypography.h1.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  'We’ll only show your approximate location.',
                  textAlign: TextAlign.center,
                  style: AppTypography.body.copyWith(
                    color: Colors.white.withValues(alpha: 0.86),
                  ),
                ),
                const Spacer(flex: 4),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.peach, Color(0xFFFFDAB6)],
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextButton(
                      onPressed: _busy ? null : _requestLocation,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.forestDeep,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: _busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              'Enable location',
                              style: AppTypography.button.copyWith(
                                color: AppColors.forestDeep,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: widget.onSkip == null || _busy
                      ? null
                      : () => widget.onSkip!.call(),
                  child: Text(
                    'Not now',
                    style: AppTypography.body.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
