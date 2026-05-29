import 'dart:convert';

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:http/http.dart' as http;

import '../config/api_keys.dart';

// ──────────────────────────── Language codes ────────────────────────────

abstract final class LangCode {
  static const ko   = 'ko';
  static const en   = 'en';
  static const vi   = 'vi';
  static const ja   = 'ja';
  static const zhCn = 'zh-CN';
  static const my   = 'my';

  static const _supported = {ko, en, vi, ja, zhCn, my};

  static String fromTag(String tag) => switch (tag.toUpperCase()) {
    'KR' || 'KO' || 'KOREAN'       => ko,
    'EN' || 'ENGLISH'               => en,
    'VN' || 'VI' || 'VIETNAMESE'    => vi,
    'JA' || 'JAPANESE'              => ja,
    'ZH' || 'ZH-CN' || 'CHINESE'   => zhCn,
    'MY' || 'MYANMAR' || 'BURMESE' => my,
    _                               => en,
  };

  static String displayName(String code) => switch (code) {
    ko   => '한국어',
    en   => 'English',
    vi   => 'Tiếng Việt',
    ja   => '日本語',
    zhCn => '中文(简体)',
    my   => 'မြန်မာဘာသာ',
    _    => code,
  };

  static bool isSupported(String code) => _supported.contains(code);
  static String normalize(String code) => fromTag(code);
}

// ──────────────────────────── Service (Singleton) ────────────────────────────

/// Translation service backed by Google Cloud Translation API v2.
/// Free tier: 500,000 characters/month.
/// Requires API key in ApiKeys.googleTranslateApiKey.
class TranslationService {
  TranslationService._();
  static final instance = TranslationService._();

  static const _baseUrl =
      'https://translation.googleapis.com/language/translate/v2';

  final _translationCache = <String, String>{};
  final _detectCache      = <String, String?>{};
  static const _kMaxCache = 250;

  void clearCache() {
    _translationCache.clear();
    _detectCache.clear();
  }

  bool canTranslate({
    required String text,
    required String from,
    required String to,
  }) {
    if (text.trim().isEmpty) return false;
    if (ApiKeys.googleTranslateApiKey.isEmpty) return false;
    final f = LangCode.normalize(from);
    final t = LangCode.normalize(to);
    return f != t && LangCode.isSupported(t);
  }

  /// Detects the language of [text] via Google Cloud Translation API.
  /// Returns a LangCode string (e.g. 'ko', 'vi') or null on failure.
  Future<String?> detectLanguage(String text) async {
    final key = text.trim();
    if (key.isEmpty || ApiKeys.googleTranslateApiKey.isEmpty) return null;
    if (_detectCache.containsKey(key)) return _detectCache[key];

    try {
      final uri = Uri.parse('$_baseUrl/detect')
          .replace(queryParameters: {'key': ApiKeys.googleTranslateApiKey});

      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'q': key}),
          )
          .timeout(const Duration(seconds: 6));

      if (res.statusCode != 200) return null;

      final data       = jsonDecode(res.body) as Map<String, dynamic>;
      final detections = data['data']?['detections'] as List?;
      final lang       = detections?.first?.first?['language'] as String?;
      final normalized = lang != null ? LangCode.fromTag(lang) : null;

      _remember(_detectCache, key, normalized, _kMaxCache);
      return normalized;
    } catch (e) {
      if (kDebugMode) debugPrint('[TranslationService] detect error: $e');
      return null;
    }
  }

  /// Translates [text] from [from] to [to].
  /// Returns [text] unchanged on error or unsupported pair.
  Future<String> translateText(
    String text, {
    required String from,
    required String to,
  }) async {
    final f = LangCode.normalize(from);
    final t = LangCode.normalize(to);

    if (!canTranslate(text: text, from: f, to: t)) return text;

    final cacheKey = '$f|$t|${text.trim()}';
    if (_translationCache.containsKey(cacheKey)) {
      return _translationCache[cacheKey]!;
    }

    try {
      final uri = Uri.parse(_baseUrl)
          .replace(queryParameters: {'key': ApiKeys.googleTranslateApiKey});

      final res = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'q': text.trim(),
              'source': f,
              'target': t,
              'format': 'text',
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode != 200) return text;

      final data        = jsonDecode(res.body) as Map<String, dynamic>;
      final translations = data['data']?['translations'] as List?;
      final translated  = translations?.first?['translatedText'] as String?;

      if (translated == null || translated.trim().isEmpty) return text;
      _remember(_translationCache, cacheKey, translated, _kMaxCache);
      return translated;
    } catch (e) {
      if (kDebugMode) debugPrint('[TranslationService] translate error: $e');
      return text;
    }
  }

  void _remember<K, V>(Map<K, V> cache, K key, V value, int maxEntries) {
    cache.remove(key);
    cache[key] = value;
    while (cache.length > maxEntries) {
      cache.remove(cache.keys.first);
    }
  }
}
