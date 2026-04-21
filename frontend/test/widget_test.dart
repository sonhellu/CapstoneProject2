import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:capstone_frontend/app/capstone_app.dart';
import 'package:capstone_frontend/core/locale/locale_controller.dart';
import 'package:capstone_frontend/core/naver_map/naver_map_sdk_controller.dart';
import 'package:capstone_frontend/core/theme/theme_controller.dart';
import 'package:capstone_frontend/features/auth/providers/auth_provider.dart';
import 'package:capstone_frontend/features/chat/chat_controller.dart';
import 'package:capstone_frontend/features/schedule/providers/schedule_provider.dart';
import 'package:capstone_frontend/features/shell/main_shell.dart';
import 'package:capstone_frontend/l10n/app_localizations.dart';

void main() {
  testWidgets('Đăng nhập vào màn shell chính', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => ScheduleProvider()),
          ChangeNotifierProvider(create: (_) => LocaleController()),
          ChangeNotifierProvider(create: (_) => ThemeController()),
          ChangeNotifierProvider(create: (_) => NaverMapSdkController()),
          ChangeNotifierProxyProvider<AuthProvider, ChatController>(
            create: (ctx) => ChatController(ctx.read<AuthProvider>()),
            update: (_, auth, prev) => prev ?? ChatController(auth),
          ),
        ],
        // Production wiring: [CapstoneApp] → [MaterialApp] with
        // [AppLocalizations.localizationsDelegates] / [supportedLocales];
        // [LocaleController] supplies [MaterialApp.locale] (default vi).
        child: const CapstoneApp(homeCarouselAutoPlay: false),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Đăng nhập'), findsWidgets);

    await tester.enterText(find.byType(TextFormField).at(0), 'test@duhoc.vn');
    await tester.enterText(find.byType(TextFormField).at(1), 'password12');
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('login_submit')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pumpAndSettle();

    final shellContext = tester.element(find.byType(MainShell));
    final l10n = AppLocalizations.of(shellContext)!;

    expect(Localizations.localeOf(shellContext), const Locale('vi'));
    expect(l10n.navHome, 'Trang chủ');
    expect(find.text(l10n.navHome), findsOneWidget);
  });
}
