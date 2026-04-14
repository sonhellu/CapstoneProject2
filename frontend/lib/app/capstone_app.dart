import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/locale/locale_controller.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';
import '../core/widgets/locale_change_overlay.dart';
import '../features/auth/presentation/auth_screen.dart';
import '../features/auth/presentation/verify_email_screen.dart';
import '../features/auth/providers/auth_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final localeCtrl = context.watch<LocaleController>();
    final themeCtrl = context.watch<ThemeController>();

    return MaterialApp(
      locale: localeCtrl.locale,
      theme: AppTheme.light(localeCtrl.locale),
      darkTheme: AppTheme.dark(localeCtrl.locale),
      themeMode: themeCtrl.mode,
      // ── Fade-in / Fade-out overlay ────────────────────────────────────
      // Keeping the overlay in the tree (opacity 0 vs 1) gives us a proper
      // FadeOut when isLocaleChanging flips back to false.
      builder: (context, child) {
        final showOverlay = localeCtrl.isLocaleChanging;
        return Stack(
          fit: StackFit.expand,
          children: [
            child ?? const SizedBox.shrink(),
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
          if (!auth.isAuthenticated) return const AuthScreen();
          if (!auth.isEmailVerified) return const VerifyEmailScreen();
          return MainShell(homeCarouselAutoPlay: homeCarouselAutoPlay);
        },
      ),
    );
  }
}
