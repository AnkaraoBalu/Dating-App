# Notifications (push)

Firebase Cloud Messaging for Android and iOS. Everything push-related in the
app lives in this folder; `HomeScreen` starts it for the signed-in session
(`home/presentation/controllers/home_notification_actions.dart`).

- `data/push_notifications_service.dart`: asks for permission, registers the
  phone with the API (again when Firebase rotates the token), and exposes
  `foreground` (arrived while the app is open) and `opened` (tapped in the
  system tray, including the one that launched the app).
- `data/notifications_api.dart`: `POST/DELETE /notifications/devices`.
- `models/push_notification.dart`: notification types (`message`, `match`,
  `like`, `vibe`, `call`) read from the push data.
- `presentation/widgets/in_app_notification.dart`: the banner shown while the
  app is open (the system only shows notifications in the background).

Tapping a notification opens the conversation, the Matches tab, Likes
received, or the related Vibe room. Room messages are pushed to joined members
who are not already viewing that room live. Log out unregisters the phone
before signing out.

## Setup

- Android: `android/app/google-services.json` (from the Firebase console) and
  the `com.google.gms.google-services` Gradle plugin. Both config files are
  git-ignored; each developer downloads them from the Firebase project.
- iOS: `ios/Runner/GoogleService-Info.plist` in the Runner target, the
  `aps-environment` entitlement, the `remote-notification` background mode, and
  an APNs key uploaded in Firebase → Project settings → Cloud Messaging.
  Push needs a real iPhone, not the Simulator.
- Without these files the app runs normally, just without push.

The backend side is `backend/src/modules/notifications/`.
