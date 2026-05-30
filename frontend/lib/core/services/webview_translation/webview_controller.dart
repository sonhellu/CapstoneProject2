import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_translation/google_mlkit_translation.dart';

import '../translation_service.dart';
import 'webview_screen.dart';

abstract final class WebTranslation {
  /// Maps a [LangCode] string (e.g. 'vi') to a ML Kit [TranslateLanguage].
  static TranslateLanguage? mlkitLanguage(String langCode) =>
      switch (langCode) {
        LangCode.vi   => TranslateLanguage.vietnamese,
        LangCode.en   => TranslateLanguage.english,
        LangCode.ja   => TranslateLanguage.japanese,
        LangCode.zhCn => TranslateLanguage.chinese,
        LangCode.ko   => TranslateLanguage.korean,
        _             => null,
      };

  /// Downloads the ML Kit model for [language] if not already on device.
  static Future<void> ensureModelDownloaded(TranslateLanguage language) async {
    final manager = OnDeviceTranslatorModelManager();
    final downloaded = await manager.isModelDownloaded(language.bcpCode);
    if (!downloaded) {
      await manager.downloadModel(language.bcpCode);
    }
  }

  /// Opens [url] in a translated WebView.
  ///
  /// Shows a loading dialog while downloading the ML Kit model,
  /// then navigates to [WebViewTranslationScreen].
  static Future<void> open({
    required BuildContext context,
    required String url,
    required String targetLangCode,
    String? title,
  }) async {
    final mlLang = mlkitLanguage(targetLangCode);

    if (mlLang == null) {
      // Language not supported by ML Kit — open without on-device translation
      if (!context.mounted) return;
      _navigate(context, url: url, targetLangCode: targetLangCode,
          targetLanguage: TranslateLanguage.english, title: title);
      return;
    }

    _showLoading(context);

    try {
      await ensureModelDownloaded(mlLang);
    } catch (_) {
      // Model download failed — still open, backend will handle long texts
    }

    if (!context.mounted) return;
    Navigator.of(context).pop(); // close loading dialog

    _navigate(context,
        url: url,
        targetLangCode: targetLangCode,
        targetLanguage: mlLang,
        title: title);
  }

  static void _navigate(
    BuildContext context, {
    required String url,
    required String targetLangCode,
    required TranslateLanguage targetLanguage,
    String? title,
  }) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => WebViewTranslationScreen(
        url: url,
        targetLangCode: targetLangCode,
        targetLanguage: targetLanguage,
        title: title,
      ),
    ));
  }

  static void _showLoading(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  '번역 엔진 로딩 중…',
                  style: GoogleFonts.notoSansKr(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
