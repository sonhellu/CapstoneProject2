import 'package:flutter/material.dart';

/// Model đại diện cho một ngôn ngữ trong danh sách chọn ngôn ngữ app.
class LanguageModel {
  const LanguageModel({
    required this.languageName,
    required this.languageCode,
    required this.flagEmoji,
    required this.nativeLabel,
    required this.locale,
    this.isSystemDefault = false,
  });

  /// Tên tiếng Anh, e.g. "Vietnamese"
  final String languageName;

  /// IETF code, e.g. "vi", "ko", "en"
  final String languageCode;

  /// Flag emoji, e.g. "🇻🇳"
  final String flagEmoji;

  /// Tên bản ngữ, e.g. "Tiếng Việt"
  final String nativeLabel;

  final Locale locale;

  /// True chỉ với option "System Default"
  final bool isSystemDefault;

  // ─────────────────────────── Language List ───────────────────────────

  /// System Default — theo ngôn ngữ thiết bị.
  static const systemDefault = LanguageModel(
    languageName: 'System Default',
    languageCode: 'sys',
    flagEmoji: '⚙️',
    nativeLabel: 'System Default',
    locale: Locale('sys'),
    isSystemDefault: true,
  );

  static const all = <LanguageModel>[
    systemDefault,
    LanguageModel(
      languageName: 'Vietnamese',
      languageCode: 'vi',
      flagEmoji: '🇻🇳',
      nativeLabel: 'Tiếng Việt',
      locale: Locale('vi'),
    ),
    LanguageModel(
      languageName: 'Korean',
      languageCode: 'ko',
      flagEmoji: '🇰🇷',
      nativeLabel: '한국어',
      locale: Locale('ko'),
    ),
    LanguageModel(
      languageName: 'English',
      languageCode: 'en',
      flagEmoji: '🇬🇧',
      nativeLabel: 'English',
      locale: Locale('en'),
    ),
    LanguageModel(
      languageName: 'Japanese',
      languageCode: 'ja',
      flagEmoji: '🇯🇵',
      nativeLabel: '日本語',
      locale: Locale('ja'),
    ),
    LanguageModel(
      languageName: 'Chinese',
      languageCode: 'zh',
      flagEmoji: '🇨🇳',
      nativeLabel: '中文',
      locale: Locale('zh'),
    ),
    LanguageModel(
      languageName: 'Myanmar',
      languageCode: 'my',
      flagEmoji: '🇲🇲',
      nativeLabel: 'မြန်မာ',
      locale: Locale('my'),
    ),
  ];
}
