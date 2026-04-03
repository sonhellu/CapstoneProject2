import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_keys.dart';

/// Language codes dùng cho Naver Papago NMT API.
abstract final class LangCode {
  static const ko = 'ko'; // Korean
  static const en = 'en'; // English
  static const vi = 'vi'; // Vietnamese
  static const ja = 'ja'; // Japanese
  static const zhCn = 'zh-CN'; // Chinese Simplified

  /// Map từ tag hiển thị trong app → Papago language code.
  static String fromTag(String tag) => switch (tag.toUpperCase()) {
        'KR' => ko,
        'EN' => en,
        'VN' => vi,
        'JA' => ja,
        'ZH' => zhCn,
        _ => en,
      };

  /// Tên ngôn ngữ đích hiển thị trên badge.
  static String displayName(String code) => switch (code) {
        ko => '한국어',
        en => 'English',
        vi => 'Tiếng Việt',
        ja => '日本語',
        zhCn => '中文(简体)',
        _ => code,
      };
}

class TranslationService {
  static const _endpoint =
      'https://naveropenapi.apigw.ntruss.com/nmt/v1/translation';

  /// Dịch [text] từ [sourceLang] sang [targetLang] qua Naver Papago NMT.
  /// Ném [TranslationException] nếu API trả về lỗi.
  static Future<String> translate({
    required String text,
    required String sourceLang,
    required String targetLang,
  }) async {
    if (text.trim().isEmpty) return text;
    if (sourceLang == targetLang) return text;

    final response = await http
        .post(
          Uri.parse(_endpoint),
          headers: {
            'X-NCP-APIGW-API-KEY-ID': ApiKeys.naverClientId,
            'X-NCP-APIGW-API-KEY': ApiKeys.naverClientSecret,
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'source': sourceLang,
            'target': targetLang,
            'text': text,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['message']['result']['translatedText'] as String;
    }

    // Parse lỗi từ Naver
    try {
      final err = jsonDecode(response.body) as Map<String, dynamic>;
      final msg = err['error']?['message'] ?? 'Unknown error';
      throw TranslationException('Papago: $msg (${response.statusCode})');
    } catch (_) {
      throw TranslationException('HTTP ${response.statusCode}');
    }
  }

  /// Tự động chọn ngôn ngữ đích:
  /// - Bài không phải tiếng Anh → dịch sang EN
  /// - Bài tiếng Anh → dịch sang KO (app dùng ở Hàn)
  static String autoTarget(String sourceLang) =>
      sourceLang == LangCode.en ? LangCode.ko : LangCode.en;
}

class TranslationException implements Exception {
  const TranslationException(this.message);
  final String message;

  @override
  String toString() => 'TranslationException: $message';
}
