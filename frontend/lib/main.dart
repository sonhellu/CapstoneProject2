import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:provider/provider.dart';

import 'app/capstone_app.dart';
import 'core/locale/locale_controller.dart';
import 'core/theme/theme_controller.dart';
import 'core/naver_map/naver_map_sdk_controller.dart';
import 'core/services/notification_service.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/chat/chat_controller.dart';
import 'firebase_options.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Phải gọi trước runApp để background isolate nhận được FCM handler.
  if (!kIsWeb) NotificationService.registerBackgroundHandler();

  final naverMapSdk = NaverMapSdkController();

  if (!kIsWeb) {
    try {
      await FlutterNaverMap().init(
        clientId: '8k0ihvfii8',
        onAuthFailed: (ex) {
          debugPrint('NaverMap auth failed: $ex');
          naverMapSdk.markFailed(ex);
        },
      );
      naverMapSdk.markInitialized();
    } catch (e, st) {
      debugPrint('NaverMap init exception: $e\n$st');
      naverMapSdk.markFailed(e);
    }
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LocaleController()),
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider.value(value: naverMapSdk),
        ChangeNotifierProxyProvider<AuthProvider, ChatController>(
          create: (ctx) =>
              ChatController(ctx.read<AuthProvider>()),
          update: (_, auth, prev) =>
              prev ?? ChatController(auth),
        ),
      ],
      child: const CapstoneApp(),
    ),
  );
}
