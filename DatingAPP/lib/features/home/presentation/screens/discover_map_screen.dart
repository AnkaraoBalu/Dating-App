import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../data/home_discover_data.dart';
import '../../data/discover_api.dart';
import 'profile_quick_preview_screen.dart';
import '../widgets/home_person_photo.dart';

class DiscoverMapScreen extends StatefulWidget {
  const DiscoverMapScreen({
    super.key,
    this.people = const [],
    this.peopleFuture,
    this.api,
  });

  final List<HomePerson> people;
  final Future<List<HomePerson>>? peopleFuture;
  final DiscoverApi? api;

  @override
  State<DiscoverMapScreen> createState() => _DiscoverMapScreenState();
}

class _DiscoverMapScreenState extends State<DiscoverMapScreen> {
  late List<HomePerson> _people;
  HomePerson? _selected;
  bool _loading = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _people = widget.people;
    final peopleFuture = widget.peopleFuture;
    if (_people.isEmpty && peopleFuture != null) {
      _loading = true;
      unawaited(_loadPeople(peopleFuture));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_showLocationNotice());
    });
  }

  Future<void> _loadPeople(Future<List<HomePerson>> future) async {
    try {
      final people = await future;
      if (!mounted) return;
      setState(() {
        _people = people;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Could not load profiles. Go back and try again.';
        _loading = false;
      });
    }
  }

  Future<void> _showLocationNotice() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.surface,
      icon: const Icon(
        Icons.location_on_rounded,
        color: AppColors.coral,
        size: 30,
      ),
      title: Text(
        'Approximate locations',
        style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
      ),
      content: Text(
        'Map pins show an approximate area to protect everyone’s privacy. '
        'Tap a photo to preview that profile.',
        textAlign: TextAlign.center,
        style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.coral,
              foregroundColor: Colors.white,
            ),
            child: const Text('Got it'),
          ),
        ),
      ],
      actionsAlignment: MainAxisAlignment.center,
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.background,
    appBar: AppBar(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      title: Text(
        'People around you',
        style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
      ),
    ),
    body: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/images/location/location.png', fit: BoxFit.cover),
        if (_people.isEmpty)
          Center(
            child: Container(
              margin: const EdgeInsets.all(28),
              padding: const EdgeInsets.all(20),
              decoration: _cardDecoration(),
              child: _loading
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.coral,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Finding people nearby…'),
                      ],
                    )
                  : Text(
                      _loadError ??
                          'No profiles with shared location in this area yet.',
                      textAlign: TextAlign.center,
                      style: AppTypography.body.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
            ),
          )
        else
          ..._markers(),
        if (_selected == null && _people.isNotEmpty)
          const Align(
            alignment: Alignment.center,
            child: Icon(
              Icons.my_location_rounded,
              color: AppColors.coralPressed,
              size: 26,
            ),
          ),
        if (_selected != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.viewPaddingOf(context).bottom + 14,
            child: _selectedCard(_selected!),
          ),
      ],
    ),
  );

  List<Widget> _markers() {
    final withCoordinates = _people
        .where((p) => p.latitude != null && p.longitude != null)
        .toList();
    if (withCoordinates.isEmpty) return const [];
    final minLat = withCoordinates
        .map((p) => p.latitude!)
        .reduce((a, b) => a < b ? a : b);
    final maxLat = withCoordinates
        .map((p) => p.latitude!)
        .reduce((a, b) => a > b ? a : b);
    final minLng = withCoordinates
        .map((p) => p.longitude!)
        .reduce((a, b) => a < b ? a : b);
    final maxLng = withCoordinates
        .map((p) => p.longitude!)
        .reduce((a, b) => a > b ? a : b);
    return List.generate(withCoordinates.length, (index) {
      final person = withCoordinates[index];
      final x = maxLng == minLng
          ? .5
          : (person.longitude! - minLng) / (maxLng - minLng);
      final y = maxLat == minLat
          ? .5
          : 1 - (person.latitude! - minLat) / (maxLat - minLat);
      // Offset identical rounded coordinates into a small cluster so every photo remains tappable.
      final peersBefore = withCoordinates
          .take(index)
          .where(
            (p) =>
                p.latitude == person.latitude &&
                p.longitude == person.longitude,
          )
          .length;
      final angle = peersBefore * 1.3;
      final radius = peersBefore == 0 ? 0.0 : .045;
      final dx =
          (x * 1.5) - .75 + radius * (peersBefore == 0 ? 0 : math.cos(angle));
      final dy =
          (y * 1.5) - .75 + radius * (peersBefore == 0 ? 0 : math.sin(angle));
      return Align(
        alignment: Alignment(dx.clamp(-.82, .82), dy.clamp(-.78, .68)),
        child: GestureDetector(
          onTap: () => setState(() => _selected = person),
          child: Container(
            width: _selected?.id == person.id ? 64 : 54,
            height: _selected?.id == person.id ? 64 : 54,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.coral,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: _selected?.id == person.id ? 2 : 1,
              ),
              boxShadow: const [
                BoxShadow(color: Colors.black54, blurRadius: 10),
              ],
            ),
            child: ClipOval(
              child: HomePersonPhoto.imageFor(
                person.image,
                personName: person.name,
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _selectedCard(HomePerson person) => InkWell(
    onTap: () => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ProfileQuickPreviewScreen(person: person, api: widget.api),
      ),
    ),
    borderRadius: BorderRadius.circular(18),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 52,
              height: 58,
              child: HomePersonPhoto.imageFor(
                person.image,
                personName: person.name,
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${person.name}, ${person.age}',
                  style: AppTypography.label.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${person.distance} · ${person.match}% match',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: AppColors.textSecondary,
          ),
        ],
      ),
    ),
  );

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: AppColors.border),
  );
}
