import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../chat/data/chat_api.dart';
import '../../../matches/presentation/navigation/match_navigation.dart';
import '../../data/discover_api.dart';
import '../../data/home_discover_data.dart';

/// The like action shared by profile previews and full profiles.
class ProfileLikeButton extends StatefulWidget {
  const ProfileLikeButton({super.key, required this.person, required this.api});

  final HomePerson person;
  final DiscoverApi? api;

  @override
  State<ProfileLikeButton> createState() => _ProfileLikeButtonState();
}

class _ProfileLikeButtonState extends State<ProfileLikeButton> {
  bool _busy = false;
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    widget.api?.addListener(_likesUpdated);
  }

  void _likesUpdated() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant ProfileLikeButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.api != widget.api) {
      oldWidget.api?.removeListener(_likesUpdated);
      widget.api?.addListener(_likesUpdated);
    }
  }

  @override
  void dispose() {
    widget.api?.removeListener(_likesUpdated);
    super.dispose();
  }

  Future<void> _like() async {
    final api = widget.api;
    if (_busy ||
        _sent ||
        api == null ||
        widget.person.id.isEmpty ||
        api.hasLiked(widget.person.id)) {
      return;
    }
    setState(() => _busy = true);
    bool didMatch;
    try {
      didMatch = await api.like(widget.person.id);
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not send like: $error')));
      return;
    }
    if (!mounted) return;
    setState(() {
      _sent = true;
      _busy = false;
    });
    if (didMatch) {
      await MatchNavigation.celebrate(
        context,
        person: widget.person,
        chatApi: ChatApi(
          baseUrl: api.baseUrl,
          getSessionToken: api.getSessionToken,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sent = _sent || (widget.api?.hasLiked(widget.person.id) ?? false);
    return FilledButton.icon(
      onPressed: _busy || sent || widget.api == null || widget.person.id.isEmpty
          ? null
          : _like,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.coral,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.coral.withValues(alpha: .35),
        disabledForegroundColor: Colors.white70,
        minimumSize: const Size.fromHeight(48),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
        shape: const StadiumBorder(),
      ),
      icon: _busy
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(sent ? Icons.check_rounded : Icons.favorite_rounded),
      label: Text(
        _busy
            ? 'Sending…'
            : sent
            ? 'Liked'
            : 'Like',
      ),
    );
  }
}
