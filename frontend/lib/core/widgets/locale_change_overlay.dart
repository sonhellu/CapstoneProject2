import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Fixed determinate progress while switching locale. Indeterminate mode would
/// spin forever while the overlay remains in the tree under [AnimatedOpacity]
/// (opacity 0), which breaks [WidgetTester.pumpAndSettle] in tests.
const double _kLocaleOverlayProgress = 0.45;

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

  TextStyle _textStyle(BuildContext context) {
    final p = Theme.of(context).colorScheme.primary;
    if (targetLocale?.languageCode == 'my') {
      return GoogleFonts.notoSansMyanmar(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: p,
      );
    }
    return GoogleFonts.notoSansKr(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: p,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final p = cs.primary;
    return AbsorbPointer(
      child: Material(
        color: cs.surface.withValues(alpha: 0.94),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 52,
                height: 52,
                child: CircularProgressIndicator(
                  strokeWidth: 3.2,
                  value: _kLocaleOverlayProgress,
                  valueColor: AlwaysStoppedAnimation<Color>(p),
                  backgroundColor: p.withValues(alpha: 0.12),
                ),
              ),
              const SizedBox(height: 20),
              // Target-language loading text
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  _message,
                  key: ValueKey(targetLocale?.languageCode),
                  style: _textStyle(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
