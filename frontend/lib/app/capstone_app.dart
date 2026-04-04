import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../core/locale/locale_controller.dart';
import '../core/widgets/locale_change_overlay.dart';
import '../features/auth/presentation/auth_screen.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/theme/auth_theme.dart';
import '../features/shell/main_shell.dart';
import 'package:capstone_frontend/l10n/app_localizations.dart';

/// Root widget: theme, routing, locale, overlay.
class CapstoneApp extends StatelessWidget {
  const CapstoneApp({
    super.key,
    this.homeCarouselAutoPlay = true,
  });

  /// Forwards to [MainShell] / [HomeTabScreen] (disable in widget tests).
  final bool homeCarouselAutoPlay;

  // ── Dynamic font theme ──────────────────────────────────────────────────
  // Myanmar (my) requires Noto Sans Myanmar for correct Unicode rendering.
  // All other locales use Noto Sans KR (covers Latin, Hangul, CJK, Kana).
  static ThemeData _buildTheme(Locale locale) {
    final textTheme = locale.languageCode == 'my'
        ? GoogleFonts.notoSansMyanmarTextTheme()
        : GoogleFonts.notoSansKrTextTheme();

    return ThemeData(
      useMaterial3: true,
      textTheme: textTheme,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AuthColors.primary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AuthColors.background,
      inputDecorationTheme: InputDecorationTheme(
        floatingLabelBehavior: FloatingLabelBehavior.never,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AuthRadii.sm),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localeCtrl = context.watch<LocaleController>();

    return MaterialApp(
      locale: localeCtrl.locale,
      theme: _buildTheme(localeCtrl.locale),
      // ── Fade-in / Fade-out overlay ────────────────────────────────────
      // Keeping the overlay in the tree (opacity 0 vs 1) gives us a proper
      // FadeOut when isLocaleChanging flips back to false.
      builder: (context, child) {
        final showOverlay = localeCtrl.isLocaleChanging;
        return Stack(
          fit: StackFit.expand,
          children: [
            ?child,
            IgnorePointer(
              ignoring: !showOverlay,
              child: AnimatedOpacity(
                opacity: showOverlay ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                child: LocaleChangeOverlay(
                  targetLocale: localeCtrl.pendingLocale,
                ),
              ),
            ),
          ],
        );
      },
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isAuthenticated) {
            return MainShell(homeCarouselAutoPlay: homeCarouselAutoPlay);
          }
          return const AuthScreen();
        },
      ),
    );
  }
}
