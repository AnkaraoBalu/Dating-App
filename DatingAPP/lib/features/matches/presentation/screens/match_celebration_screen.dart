import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/theme.dart';
import '../../../home/data/home_discover_data.dart';
import '../../data/match_api.dart';
import '../../../chat/data/chat_api.dart';
import '../../../chat/presentation/screens/conversation_screen.dart';
import '../widgets/match_sparkle_painter.dart';
import 'matched_profile_screen.dart';
import '../../models/match_model.dart';
import '../../../home/presentation/widgets/home_person_photo.dart';

part '../widgets/match_celebration_sections.dart';

class MatchCelebrationScreen extends StatefulWidget {
  const MatchCelebrationScreen({
    super.key,
    required this.person,
    required this.chatApi,
    this.currentUserImage,
    this.currentUserName,
  });

  final HomePerson person;
  final ChatApi chatApi;
  final String? currentUserImage;
  final String? currentUserName;

  @override
  State<MatchCelebrationScreen> createState() => _MatchCelebrationScreenState();
}

class _MatchCelebrationScreenState extends State<MatchCelebrationScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final AnimationController _sparkles = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  );
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  String? _currentUserImage;
  String? _currentUserName;

  @override
  void initState() {
    super.initState();
    _currentUserImage = widget.currentUserImage;
    _currentUserName = widget.currentUserName;
    if (_currentUserImage?.trim().isNotEmpty != true ||
        _currentUserName == null) {
      unawaited(_loadOwnPhoto());
    }
  }

  Future<void> _loadOwnPhoto() async {
    final api = MatchApi(
      baseUrl: widget.chatApi.baseUrl,
      getSessionToken: widget.chatApi.getSessionToken,
    );
    try {
      final photo = await api.loadCurrentUserPhoto();
      if (!mounted) return;
      setState(() {
        _currentUserImage = photo.image ?? _currentUserImage;
        _currentUserName = photo.name ?? _currentUserName;
      });
    } catch (error) {
      debugPrint('[MatchPhoto] Could not load your profile photo: $error');
    } finally {
      api.dispose();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _pulse.stop();
      _sparkles.stop();
      _entrance.value = 1;
    } else {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
      if (!_sparkles.isAnimating) _sparkles.repeat();
      if (_entrance.value == 0) _entrance.forward();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _sparkles.dispose();
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light.copyWith(
      statusBarColor: const Color(0xFF100D0E),
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: const Color(0xFF100D0E),
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarDividerColor: const Color(0xFF100D0E),
    ),
    child: Scaffold(
      backgroundColor: const Color(0xFF100D0E),
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -.05),
                  radius: .85,
                  colors: [
                    Color(0xFF4A1620),
                    Color(0xFF160D10),
                    Color(0xFF080A0A),
                  ],
                  stops: [0, .55, 1],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _sparkles,
                  builder: (context, _) => CustomPaint(
                    painter: MatchSparklePainter(_sparkles.value),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Close match',
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    ScaleTransition(
                      scale: Tween<double>(begin: .88, end: 1.08).animate(
                        CurvedAnimation(
                          parent: _pulse,
                          curve: Curves.easeInOut,
                        ),
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: Color(0xFFFF4265),
                        size: 66,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "It's a Match! ✨",
                      textAlign: TextAlign.center,
                      style: AppTypography.hero.copyWith(
                        color: Colors.white,
                        fontSize: 34,
                      ),
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final diameter = math.min(
                          174.0,
                          constraints.maxWidth * .49,
                        );
                        return SizedBox(
                          height: diameter + 16,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: _animatedPortrait(
                                  diameter,
                                  _currentUserImage,
                                  _currentUserName,
                                  true,
                                ),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: _animatedPortrait(
                                  diameter,
                                  widget.person.image,
                                  widget.person.name,
                                  false,
                                ),
                              ),
                              AnimatedBuilder(
                                animation: _pulse,
                                builder: (context, child) => Transform.scale(
                                  scale: .94 + _pulse.value * .12,
                                  child: child,
                                ),
                                child: Container(
                                  width: 59,
                                  height: 59,
                                  decoration: BoxDecoration(
                                    color: AppColors.coral,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.coral.withValues(
                                          alpha: .55,
                                        ),
                                        blurRadius: 24,
                                        spreadRadius: 3,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.favorite_rounded,
                                    color: Colors.white,
                                    size: 31,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 15),
                    Text(
                      'You and ${widget.person.name} liked each other!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xAA1A1516),
                        borderRadius: BorderRadius.circular(21),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: .08),
                        ),
                      ),
                      child: Column(
                        children: [
                          _matchActionRow(
                            Icons.chat_bubble_rounded,
                            'Send a message',
                            'Start the conversation',
                            () => _openChat(context),
                          ),
                          Divider(
                            height: 1,
                            color: Colors.white.withValues(alpha: .08),
                          ),
                          _matchActionRow(
                            Icons.person_search_rounded,
                            'View profile',
                            'Learn more about ${widget.person.name}',
                            () => Navigator.push(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => MatchedProfileScreen(
                                  person: widget.person,
                                  chatApi: widget.chatApi,
                                ),
                              ),
                            ),
                          ),
                          Divider(
                            height: 1,
                            color: Colors.white.withValues(alpha: .08),
                          ),
                          _matchActionRow(
                            Icons.favorite_border_rounded,
                            'Keep matching',
                            'Find more amazing people',
                            () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => _openChat(context),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.coral,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: const StadiumBorder(),
                          elevation: 8,
                          shadowColor: AppColors.coral.withValues(alpha: .35),
                        ),
                        child: const Text(
                          'Send a message',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: .1),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          backgroundColor: const Color(0x441A1516),
                          shape: const StadiumBorder(),
                        ),
                        child: const Text('Maybe later'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  void _openChat(BuildContext context) => Navigator.pushReplacement(
    context,
    MaterialPageRoute<void>(
      builder: (_) => ConversationScreen(
        match: MatchRecord(id: widget.person.id, person: widget.person),
        api: widget.chatApi,
      ),
    ),
  );
}
