import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_keys.dart';

// ──────────────────────────── Language codes ────────────────────────────

abstract final class LangCode {
  static const ko    = 'ko';
  static const en    = 'en';
  static const vi    = 'vi';
  static const ja    = 'ja';
  static const zhCn  = 'zh-CN';

  // Papago-supported target languages (source is always Korean in this app).
  static const _papagoSupported = {ko, en, vi, ja, zhCn};

  /// Accepts display tags (KR, VN, ZH), ISO locale codes (ko, vi, zh),
  /// and full language names (Korean, Vietnamese, Chinese) stored in Firestore.
  static String fromTag(String tag) => switch (tag.toUpperCase()) {
    'KR' || 'KO' || 'KOREAN'        => ko,
    'EN' || 'ENGLISH'                => en,
    'VN' || 'VI' || 'VIETNAMESE'     => vi,
    'JA' || 'JAPANESE'               => ja,
    'ZH' || 'ZH-CN' || 'CHINESE'    => zhCn,
    'MY' || 'MYANMAR' || 'BURMESE'  => en, // Papago unsupported → fallback
    _                                => en,
  };

  static String displayName(String code) => switch (code) {
    ko   => '한국어',
    en   => 'English',
    vi   => 'Tiếng Việt',
    ja   => '日本語',
    zhCn => '中文(简体)',
    _    => code,
  };

  /// Returns true when Papago can translate FROM Korean TO [code].
  static bool isPapagoSupported(String code) =>
      _papagoSupported.contains(code);
}

// ──────────────────────────── Service (Singleton) ────────────────────────────

/// Translation service backed by Naver Papago NMT API.
///
/// Usage:
/// ```dart
/// final result = await TranslationService.instance.translateText(
///   '안녕하세요',
///   from: LangCode.ko,
///   to: LangCode.vi,
/// );
/// ```
///
/// Supported target languages: vi, en, ja, zh-CN, ko.
/// Burmese (my) is not supported by Papago — falls back to English.
class TranslationService {
  TranslationService._();
  static final instance = TranslationService._();

  static const _endpoint =
      'https://papago.apigw.ntruss.com/nmt/v1/translation';

  static const _detectEndpoint =
      'https://papago.apigw.ntruss.com/langs/v1/dect';

  /// Detects the language of [text] using Papago Language Detection API.
  ///
  /// Returns a [LangCode] string (e.g. 'ko', 'vi', 'en') on success,
  /// or null if detection fails or the language is unsupported.
  Future<String?> detectLanguage(String text) async {
    if (text.trim().isEmpty) return null;
    try {
      final response = await http
          .post(
            Uri.parse(_detectEndpoint),
            headers: {
              'X-NCP-APIGW-API-KEY-ID': ApiKeys.papagoClientId,
              'X-NCP-APIGW-API-KEY':    ApiKeys.papagoClientSecret,
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: {'query': text},
          )
          .timeout(const Duration(seconds: 6));

      if (response.statusCode != 200) {
        if (kDebugMode) {
          debugPrint('[Papago] Detect HTTP ${response.statusCode}: ${response.body}');
        }
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final langCode = data['langCode'] as String?;
      if (langCode == null || langCode.isEmpty) return null;

      // Normalize: Papago may return 'zh-CN', 'zh-TW' etc.
      return LangCode.fromTag(langCode);
    } catch (e) {
      if (kDebugMode) debugPrint('[Papago] Detect error: $e');
      return null;
    }
  }

  /// Translates [text] from [from] to [to] using Papago NMT.
  ///
  /// - Returns [text] unchanged on error or unsupported language pair.
  /// - Never throws.
  Future<String> translateText(
    String text, {
    required String from,
    required String to,
  }) async {
    if (text.trim().isEmpty) return text;
    if (from == to) return text;

    // Papago does not support Burmese — return original text.
    if (!LangCode.isPapagoSupported(to)) return text;

    try {
      final response = await http
          .post(
            Uri.parse(_endpoint),
            headers: {
              'X-NCP-APIGW-API-KEY-ID': ApiKeys.papagoClientId,
              'X-NCP-APIGW-API-KEY':    ApiKeys.papagoClientSecret,
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: {
              'source': from,
              'target': to,
              'text':   text,
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        if (kDebugMode) {
          debugPrint(
            '[Papago] HTTP ${response.statusCode}: ${response.body}',
          );
        }
        return text;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final translated =
          data['message']?['result']?['translatedText'] as String?;

      if (translated == null || translated.trim().isEmpty) return text;
      return translated;
    } catch (e) {
      if (kDebugMode) debugPrint('[Papago] Error: $e');
      return text;
    }
  }
}
