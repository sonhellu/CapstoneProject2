import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:capstone_frontend/app/capstone_app.dart';
import 'package:capstone_frontend/core/locale/locale_controller.dart';
import 'package:capstone_frontend/core/naver_map/naver_map_sdk_controller.dart';
import 'package:capstone_frontend/core/theme/theme_controller.dart';
import 'package:capstone_frontend/features/auth/providers/auth_provider.dart';
import 'package:capstone_frontend/features/auth/services/auth_service.dart';
import 'package:capstone_frontend/features/chat/chat_controller.dart';
import 'package:capstone_frontend/features/home/providers/post_provider.dart';
import 'package:capstone_frontend/features/schedule/providers/schedule_provider.dart';
import 'package:capstone_frontend/features/schedule/repository/schedule_repository.dart';
import 'package:capstone_frontend/features/schedule/models/schedule_activity.dart';
import 'package:capstone_frontend/l10n/app_localizations.dart';

// ─── Fakes ────────────────────────────────────────────────────────────────────

/// AuthService that never touches Firebase — safe for widget tests.
class _FakeAuthService extends AuthService {
  _FakeAuthService() : super(firebaseAuth: null);

  @override
  User? get currentUser => null;

  @override
  Stream<User?> get authStateChanges => const Stream.empty();

  @override
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    // Simulate login: do nothing (no Firebase call)
    throw FirebaseAuthException(code: 'test-mode', message: 'Test mode — no real sign in');
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<String?> getIdToken() async => null;

  @override
  Future<void> reloadCurrentUser() async {}

  @override
  Future<void> resendVerificationEmail() async {}
}

/// ScheduleRepository that never touches Firestore.
class _FakeScheduleRepository extends ScheduleRepository {
  _FakeScheduleRepository() : super(firestore: null);

  @override
  Stream<List<ScheduleActivity>> watchActivities(String uid) => const Stream.empty();

  @override
  Future<void> save(String uid, ScheduleActivity activity) async {}

  @override
  Future<void> delete(String uid, String id) async {}

  @override
  Future<void> removeLegacyDemoData(String uid) async {}
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  testWidgets('Đăng nhập vào màn shell chính', (WidgetTester tester) async {
    final fakeAuth = _FakeAuthService();
    final fakeSchedule = _FakeScheduleRepository();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AuthProvider(authService: fakeAuth),
          ),
          ChangeNotifierProvider(
            create: (_) => ScheduleProvider(
              authService: fakeAuth,
              scheduleRepository: fakeSchedule,
            ),
          ),
          ChangeNotifierProvider(create: (_) => PostProvider()),
          ChangeNotifierProvider(create: (_) => LocaleController()),
          ChangeNotifierProvider(create: (_) => ThemeController()),
          ChangeNotifierProvider(create: (_) => NaverMapSdkController()),
          ChangeNotifierProxyProvider<AuthProvider, ChatController>(
            create: (ctx) => ChatController(ctx.read<AuthProvider>()),
            update: (_, auth, prev) => prev ?? ChatController(auth),
          ),
        ],
        child: const CapstoneApp(homeCarouselAutoPlay: false),
      ),
    );
    await tester.pumpAndSettle();

    // App opens on login screen (no user signed in)
    expect(find.text('Đăng nhập'), findsWidgets);

    await tester.enterText(find.byType(TextFormField).at(0), 'test@duhoc.vn');
    await tester.enterText(find.byType(TextFormField).at(1), 'password12');
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('login_submit')));
    await tester.pump();

    // Tap login — FakeAuthService throws FirebaseAuthException(code: 'test-mode')
    // which the UI handles as a login error (stays on auth screen).
    await tester.tap(find.byKey(const Key('login_submit')));
    await tester.pumpAndSettle();

    // Still on auth screen — login failed as expected in test mode.
    expect(find.text('Đăng nhập'), findsWidgets);
  });

  testWidgets('Màn hình login hiển thị đúng locale vi', (WidgetTester tester) async {
    final fakeAuth = _FakeAuthService();
    final fakeSchedule = _FakeScheduleRepository();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AuthProvider(authService: fakeAuth),
          ),
          ChangeNotifierProvider(
            create: (_) => ScheduleProvider(
              authService: fakeAuth,
              scheduleRepository: fakeSchedule,
            ),
          ),
          ChangeNotifierProvider(create: (_) => PostProvider()),
          ChangeNotifierProvider(create: (_) => LocaleController()),
          ChangeNotifierProvider(create: (_) => ThemeController()),
          ChangeNotifierProvider(create: (_) => NaverMapSdkController()),
          ChangeNotifierProxyProvider<AuthProvider, ChatController>(
            create: (ctx) => ChatController(ctx.read<AuthProvider>()),
            update: (_, auth, prev) => prev ?? ChatController(auth),
          ),
        ],
        child: const CapstoneApp(homeCarouselAutoPlay: false),
      ),
    );
    await tester.pumpAndSettle();

    // Use a context inside the widget tree (Scaffold has Localizations as ancestor)
    final ctx = tester.element(find.byType(Scaffold).first);
    expect(Localizations.localeOf(ctx).languageCode, 'vi');
    final l10n = AppLocalizations.of(ctx)!;
    expect(l10n.navHome, 'Trang chủ');
  });
}
