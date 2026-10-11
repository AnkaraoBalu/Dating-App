import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../home/data/home_discover_data.dart';
import '../../../chat/data/chat_api.dart';
import '../screens/match_celebration_screen.dart';

abstract final class MatchNavigation {
  static final Map<NavigatorState, Future<void>> _presentations = {};
  static final Set<(NavigatorState, String)> _pendingMatches = {};

  static Future<void> celebrate(
    BuildContext context, {
    required HomePerson person,
    required ChatApi chatApi,
    String? currentUserImage,
    String? currentUserName,
  }) async {
    if (!context.mounted) return;
    final navigator = Navigator.of(context);
    final key = (navigator, person.id);
    if (!_pendingMatches.add(key)) return;
    final previous = _presentations[navigator];
    final completed = Completer<void>();
    _presentations[navigator] = completed.future;
    try {
      // Finish the current celebration before showing another confirmed match.
      if (previous != null) await previous;
      if (!context.mounted || !navigator.mounted) return;
      HapticFeedback.mediumImpact();
      final reduceMotion = MediaQuery.disableAnimationsOf(context);
      await navigator.push<void>(
        PageRouteBuilder<void>(
          settings: RouteSettings(name: '/match/${person.id}'),
          transitionDuration: Duration(milliseconds: reduceMotion ? 0 : 360),
          reverseTransitionDuration: Duration(
            milliseconds: reduceMotion ? 0 : 240,
          ),
          pageBuilder: (_, _, _) => MatchCelebrationScreen(
            person: person,
            chatApi: chatApi,
            currentUserImage: currentUserImage,
            currentUserName: currentUserName,
          ),
          transitionsBuilder: (_, animation, _, child) {
            final curved = animation.drive(
              CurveTween(curve: Curves.easeOutCubic),
            );
            return FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: Tween<double>(begin: .94, end: 1).animate(curved),
                child: child,
              ),
            );
          },
        ),
      );
    } finally {
      _pendingMatches.remove(key);
      completed.complete();
      if (identical(_presentations[navigator], completed.future)) {
        _presentations.remove(navigator);
      }
    }
  }
}
