import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/locale/locale_controller.dart';
import '../core/widgets/locale_change_overlay.dart';
import '../features/auth/presentation/auth_screen.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/theme/auth_theme.dart';
import '../features/shell/main_shell.dart';
import 'package:capstone_frontend/l10n/app_localizations.dart';

/// Root widget: theme, routing entry.
class CapstoneApp extends StatelessWidget {
  const CapstoneApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeCtrl = context.watch<LocaleController>();

    return MaterialApp(
      locale: localeCtrl.locale,
      builder: (context, child) {
        final showOverlay = localeCtrl.isLocaleChanging;
        return Stack(
          fit: StackFit.expand,
          children: [
            ?child,
            if (showOverlay) const Positioned.fill(child: LocaleChangeOverlay()),
          ],
        );
      },
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: ThemeData(
        useMaterial3: true,
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
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isAuthenticated) {
            return const MainShell();
          }
          return const AuthScreen();
        },
      ),
    );
  }
}
