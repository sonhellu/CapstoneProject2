import 'package:flutter/widgets.dart';

import '../services/translation_service.dart';

/// Resolves the current app locale into a [LangCode] string that can be passed
/// directly to [TranslationService] and [GeocodingService].
///
/// Usage:
/// ```dart
/// final lang = AppLocaleResolver.targetLang(context);
/// // 'vi', 'en', 'ja', 'zh-CN', ...
/// ```
abstract final class AppLocaleResolver {
  /// Returns the Papago/MyMemory-compatible language code for the current
  /// locale, e.g. 'vi' when the app is in Vietnamese.
  ///
  /// Falls back to [LangCode.en] if the locale cannot be resolved.
  static String targetLang(BuildContext context) {
    try {
      final languageCode = Localizations.localeOf(context).languageCode;
      return LangCode.fromTag(languageCode);
    } catch (_) {
      return LangCode.en;
    }
  }
}
