import 'package:flutter/material.dart';

import 'webview_screen.dart';

abstract final class WebTranslation {
  /// Opens [url] in a translated WebView.
  static void open({
    required BuildContext context,
    required String url,
    required String targetLangCode,
    String? title,
  }) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => WebViewTranslationScreen(
        url: url,
        targetLangCode: targetLangCode,
        title: title,
      ),
    ));
  }
}
