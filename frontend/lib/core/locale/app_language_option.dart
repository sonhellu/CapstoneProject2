import 'package:flutter/material.dart';

/// Các ngôn ngữ khớp [AppLocalizations.supportedLocales] — du học mục tiêu phổ biến.
class AppLanguageOption {
  const AppLanguageOption({
    required this.locale,
    required this.nativeLabel,
    required this.flagEmoji,
    required this.subtitle,
  });

  final Locale locale;
  final String nativeLabel;
  final String flagEmoji;

  /// Gợi ý quốc gia / khu vực (hiển thị phụ).
  final String subtitle;

  static const List<AppLanguageOption> all = [
    AppLanguageOption(
      locale: Locale('vi'),
      nativeLabel: 'Tiếng Việt',
      flagEmoji: '🇻🇳',
      subtitle: 'Vietnam',
    ),
    AppLanguageOption(
      locale: Locale('en'),
      nativeLabel: 'English',
      flagEmoji: '🇬🇧',
      subtitle: 'International',
    ),
    AppLanguageOption(
      locale: Locale('ko'),
      nativeLabel: '한국어',
      flagEmoji: '🇰🇷',
      subtitle: 'Hàn Quốc',
    ),
    AppLanguageOption(
      locale: Locale('ja'),
      nativeLabel: '日本語',
      flagEmoji: '🇯🇵',
      subtitle: 'Nhật Bản',
    ),
    AppLanguageOption(
      locale: Locale('zh'),
      nativeLabel: '中文',
      flagEmoji: '🇨🇳',
      subtitle: 'Trung Quốc',
    ),
    AppLanguageOption(
      locale: Locale('my'),
      nativeLabel: 'မြန်မာ',
      flagEmoji: '🇲🇲',
      subtitle: 'Myanmar',
    ),
  ];
}
