import 'package:dating_app/app/oauth_browser.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class _Browser extends UrlLauncherPlatform {
  bool canClose = false;
  bool fail = false;
  int closes = 0;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> supportsCloseForMode(PreferredLaunchMode mode) async {
    expect(mode, PreferredLaunchMode.inAppBrowserView);
    return canClose;
  }

  @override
  Future<void> closeWebView() async {
    closes++;
    if (fail) throw StateError('Browser already closed');
  }
}

void main() {
  late UrlLauncherPlatform previous;
  late _Browser browser;
  setUp(() {
    previous = UrlLauncherPlatform.instance;
    browser = _Browser();
    UrlLauncherPlatform.instance = browser;
  });
  tearDown(() => UrlLauncherPlatform.instance = previous);
  test('Android callback skips unsupported browser dismissal', () async {
    await dismissOAuthBrowser();
    expect(browser.closes, 0);
  });
  test('callback dismisses the panel on supported platforms', () async {
    browser.canClose = true;
    await dismissOAuthBrowser();
    expect(browser.closes, 1);
  });
  test('browser cleanup errors do not interrupt authentication', () async {
    browser.canClose = true;
    browser.fail = true;
    await dismissOAuthBrowser();
    expect(browser.closes, 1);
  });
}
