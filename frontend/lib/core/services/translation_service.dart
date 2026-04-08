import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// ──────────────────────────── Language codes ────────────────────────────

abstract final class LangCode {
  static const ko = 'ko';
  static const en = 'en';
  static const vi = 'vi';
  static const ja = 'ja';
  static const zhCn = 'zh-CN';

  /// Accepts both app display tags (KR, VN, ZH) and ISO locale codes
  /// (ko, vi, zh) returned by [Localizations.localeOf(context).languageCode].
  static String fromTag(String tag) => switch (tag.toUpperCase()) {
    'KR' || 'KO' => ko,
    'EN'         => en,
    'VN' || 'VI' => vi,
    'JA'         => ja,
    'ZH'         => zhCn,
    _            => en, // Burmese & unsupported → fallback English
  };

  static String displayName(String code) => switch (code) {
    ko   => '한국어',
    en   => 'English',
    vi   => 'Tiếng Việt',
    ja   => '日本語',
    zhCn => '中文(简体)',
    _    => code,
  };
}

// ──────────────────────────── Service (Singleton) ────────────────────────────

/// Provider-agnostic translation service backed by MyMemory API.
///
/// Usage:
/// ```dart
/// final result = await TranslationService.instance.translateText(
///   '안녕하세요',
///   from: LangCode.ko,
///   to: LangCode.vi,
/// );
/// ```
class TranslationService {
  TranslationService._();
  static final instance = TranslationService._();

  static const _baseUrl = 'https://api.mymemory.translated.net/get';

  // Registered email → 50,000 chars/day (vs 10,000 anonymous)
  static const _email = 'sonhellu186@gmail.com';

  /// Translates [text] from [from] language to [to] language.
  ///
  /// - Returns the original [text] on network error, quota exceeded, or any
  ///   unexpected response — so the UI never shows an empty string.
  /// - Logs a warning in debug mode when quota is finished or an error occurs.
  Future<String> translateText(
    String text, {
    required String from,
    required String to,
  }) async {
    if (text.trim().isEmpty) return text;
    if (from == to) return text;

    try {
      final uri = Uri.parse(_baseUrl).replace(queryParameters: {
        'q': text,
        'langpair': '$from|$to',
        'de': _email,
      });

      final response =
          await http.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        if (kDebugMode) {
          debugPrint(
            '[TranslationService] HTTP ${response.statusCode}: ${response.body}',
          );
        }
        return text;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      // Quota exceeded
      final quotaFinished = data['quotaFinished'] as bool? ?? false;
      if (quotaFinished) {
        if (kDebugMode) {
          debugPrint('[TranslationService] ⚠️ Daily quota finished — returning original text.');
        }
        return text;
      }

      final translated =
          data['responseData']?['translatedText'] as String? ?? text;

      // MyMemory echoes back original in caps when it cannot translate
      if (translated.toUpperCase() == text.toUpperCase()) return text;

      return translated;
    } catch (e) {
      if (kDebugMode) debugPrint('[TranslationService] Error: $e');
      return text;
    }
  }
}
