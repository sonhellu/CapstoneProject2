import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:capstone_frontend/app/capstone_app.dart';
import 'package:capstone_frontend/core/locale/locale_controller.dart';
import 'package:capstone_frontend/core/naver_map/naver_map_sdk_controller.dart';
import 'package:capstone_frontend/features/auth/providers/auth_provider.dart';

void main() {
  testWidgets('Đăng nhập vào màn shell chính', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => LocaleController()),
          ChangeNotifierProvider(create: (_) => NaverMapSdkController()),
        ],
        child: const CapstoneApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('login_email')),
      'test@duhoc.vn',
    );
    await tester.enterText(
      find.byKey(const Key('login_password')),
      'password12',
    );
    await tester.ensureVisible(find.byKey(const Key('login_submit')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pumpAndSettle();

    expect(find.text('Trang chủ'), findsOneWidget);
  });
}
