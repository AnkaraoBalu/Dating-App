import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../models/push_notification.dart';
import 'notifications_api.dart';
import 'system_notifications.dart';

/// Firebase Cloud Messaging for the signed-in session (owned by HomeScreen).
///
/// - Asks for permission and registers this phone with the API, again
///   whenever Firebase rotates the token.
/// - [foreground]: notifications received while the app is open.
/// - [opened]: notifications the user tapped, including the one that
///   launched the app.
class PushNotificationsService {
  PushNotificationsService({required this.api});

  /// The active session's service, so log out can unregister the phone.
  static PushNotificationsService? current;

  final NotificationsApi api;
  FirebaseMessaging? _messaging;
  final SystemNotifications _system = SystemNotifications();
  final StreamController<PushNotification> _opened =
      StreamController<PushNotification>.broadcast();
  final StreamController<PushNotification> _foreground =
      StreamController<PushNotification>.broadcast();
  final List<StreamSubscription<Object?>> _subscriptions = [];
  String? _token;
  bool _disposed = false;

  Stream<PushNotification> get foreground => _foreground.stream;

  Stream<PushNotification> get opened => _opened.stream;

  String get _platform =>
      defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';

  Future<void> start() async {
    // Firebase isn't configured (no google-services.json /
    // GoogleService-Info.plist), e.g. in tests: run without push.
    if (Firebase.apps.isEmpty) return;
    final messaging = _messaging ??= FirebaseMessaging.instance;
    current = this;
    try {
      _subscriptions
        ..add(FirebaseMessaging.onMessage.listen(_receivedInForeground))
        ..add(FirebaseMessaging.onMessageOpenedApp.listen(_tapped))
        ..add(messaging.onTokenRefresh.listen(_register));
      await _system.initialize(onTap: (n) => _add(_opened, n));
      final launchedFrom = await messaging.getInitialMessage();
      if (launchedFrom != null) _tapped(launchedFrom);

      // The app displays its own foreground banner on both platforms.
      await messaging.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: true,
        sound: true,
      );
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      final token = await _deviceToken(messaging);
      if (token != null) await _register(token);
    } catch (error) {
      debugPrint('[Push] Could not set up notifications: $error');
    }
  }

  /// iOS only issues an FCM token once Apple has issued its APNs token.
  Future<String?> _deviceToken(FirebaseMessaging messaging) async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      for (var attempt = 0; attempt < 10; attempt++) {
        if (await messaging.getAPNSToken() != null) break;
        await Future<void>.delayed(const Duration(seconds: 1));
      }
    }
    return messaging.getToken();
  }

  Future<void> _register(String token) async {
    if (_disposed) return;
    _token = token;
    try {
      await api.registerDevice(token: token, platform: _platform);
    } catch (error) {
      debugPrint('[Push] Could not register this phone: $error');
    }
  }

  /// Stops this phone receiving the signed-in account's notifications.
  /// Call before signing out, while the session token is still valid.
  Future<void> unregister() async {
    final token = _token;
    if (token == null) return;
    try {
      await api.removeDevice(token);
      _token = null;
    } catch (error) {
      debugPrint('[Push] Could not unregister this phone: $error');
    }
  }

  void _receivedInForeground(RemoteMessage message) {
    if (_disposed) return;
    _add(_foreground, _parse(message));
  }

  void _tapped(RemoteMessage message) => _add(_opened, _parse(message));

  PushNotification _parse(RemoteMessage message) => PushNotification.fromData(
    message.data,
    title: message.notification?.title,
    body: message.notification?.body,
  );

  void _add(StreamController<PushNotification> stream, PushNotification n) {
    if (!stream.isClosed) stream.add(n);
  }

  Future<void> dispose() async {
    _disposed = true;
    if (identical(current, this)) current = null;
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    api.close();
    await _opened.close();
    await _foreground.close();
  }
}
