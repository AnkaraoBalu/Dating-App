import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

const oauthBrowserMode = LaunchMode.inAppBrowserView;

/// Android returns through the deep link; other supported platforms can also
/// dismiss their browser panel. Browser cleanup must never block sign-in.
Future<void> dismissOAuthBrowser() async {
  try {
    if (await supportsCloseForLaunchMode(
      oauthBrowserMode,
    ).timeout(const Duration(seconds: 2))) {
      await closeInAppWebView().timeout(const Duration(seconds: 2));
    }
  } catch (error) {
    debugPrint('[Just2Auth] Could not dismiss sign-in browser: $error');
  }
}
