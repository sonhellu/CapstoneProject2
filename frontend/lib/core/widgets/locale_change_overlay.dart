import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────── Design Tokens ───────────────────────────
const _kPrimary = Color(0xFF003478);

// ─────────────────────────── Localized Loading Text ───────────────────────────

/// Loading message shown IN the target language so the user immediately
/// recognises that the switch is happening in their chosen language.
const _kMessages = <String, String>{
  'vi': 'Đang đổi ngôn ngữ…',
  'ko': '언어 변경 중…',
  'en': 'Changing language…',
  'ja': '言語を変更中…',
  'zh': '正在切换语言…',
  'my': 'ဘာသာစကား ပြောင်းနေသည်…',
};

// ─────────────────────────── Overlay Widget ───────────────────────────

/// Full-screen overlay shown during locale switching.
///
/// Placed inside an [AnimatedOpacity] in [CapstoneApp] so it fades in
/// when [LocaleController.isLocaleChanging] becomes true and fades out
/// when it becomes false — without ever being removed from the tree mid-animation.
///
/// [targetLocale] drives the displayed loading message so it already
/// appears in the language the user just selected.
class LocaleChangeOverlay extends StatelessWidget {
  const LocaleChangeOverlay({super.key, this.targetLocale});

  final Locale? targetLocale;

  String get _message =>
      _kMessages[targetLocale?.languageCode] ?? 'Changing language…';

  // Myanmar needs a Unicode-compliant font; all others use NotoSansKr.
  TextStyle get _textStyle {
    if (targetLocale?.languageCode == 'my') {
      return GoogleFonts.notoSansMyanmar(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: _kPrimary,
      );
    }
    return GoogleFonts.notoSansKr(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: _kPrimary,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      child: Material(
        color: Colors.white.withValues(alpha: 0.94),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Spinning indicator
              const SizedBox(
                width: 52,
                height: 52,
                child: CircularProgressIndicator(
                  strokeWidth: 3.2,
                  valueColor: AlwaysStoppedAnimation<Color>(_kPrimary),
                  backgroundColor: Color(0x1F003478),
                ),
              ),
              const SizedBox(height: 20),
              // Target-language loading text
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  _message,
                  key: ValueKey(targetLocale?.languageCode),
                  style: _textStyle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
