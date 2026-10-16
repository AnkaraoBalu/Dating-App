import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Public Just2 web pages that the app links to (terms, privacy, support).
abstract final class LegalLinks {
  static const website = 'https://just2.in';
  static final terms = Uri.parse('$website/terms');
  static final privacy = Uri.parse('$website/privacy');
  static final communityGuidelines = Uri.parse('$website/community-guidelines');
  static final support = Uri.parse('$website/support');
}

/// Opens [uri] in an in-app browser tab, with a notice if that is not possible.
Future<void> openLegalLink(BuildContext context, Uri uri) async {
  final opened = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Could not open ${uri.host}${uri.path}.')),
    );
  }
}
