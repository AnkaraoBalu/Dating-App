import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/push_notification.dart';

/// Shows real system notifications (the banner at the top of the screen) on
/// Android while the app is open. Firebase only displays notifications there
/// when the app is in the background; iOS shows foreground banners natively
/// (see `setForegroundNotificationPresentationOptions`).
class SystemNotifications {
  /// High importance so Android shows a heads-up banner, not just a tray icon.
  /// The backend sends background pushes to this channel too.
  static const channel = AndroidNotificationChannel(
    'just2_alerts',
    'Messages, matches and likes',
    description: 'New messages, matches and likes on Just2.',
    importance: Importance.high,
  );

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// [onTap] receives notifications shown here that the user tapped,
  /// including one that relaunched the app.
  Future<void> initialize({
    required void Function(PushNotification notification) onTap,
  }) async {
    if (!_supported || _ready) return;
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (response) {
        final notification = _decode(response.payload);
        if (notification != null) onTap(notification);
      },
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true) {
      final notification = _decode(launch!.notificationResponse?.payload);
      if (notification != null) onTap(notification);
    }
    _ready = true;
  }

  Future<void> show({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    if (!_ready) return;
    // One notification per conversation: a newer message replaces the older.
    final group = data['conversationId']?.toString();
    await _plugin.show(
      id: (group ?? '${DateTime.now().microsecondsSinceEpoch}').hashCode,
      title: title,
      body: body,
      payload: jsonEncode({...data, 'title': title, 'body': body}),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: Importance.high,
          priority: Priority.high,
          tag: group,
        ),
      ),
    );
  }

  PushNotification? _decode(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    try {
      final data = jsonDecode(payload);
      if (data is! Map<String, dynamic>) return null;
      return PushNotification.fromData(
        data,
        title: data['title']?.toString(),
        body: data['body']?.toString(),
      );
    } on FormatException {
      return null;
    }
  }
}
