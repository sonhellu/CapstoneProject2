import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Called when user taps a notification — convId may be empty for
/// request-type notifications (navigate to Chat tab only).
typedef NotificationTapCallback = void Function(String convId);

// ── Top-level background handler ─────────────────────────────────────────────
// Must be a top-level function annotated with @pragma so the Dart AOT compiler
// keeps it in the background isolate.
@pragma('vm:entry-point')
Future<void> _fcmBackgroundHandler(RemoteMessage _) async {
  // Background messages whose notifications are built server-side are shown
  // automatically by FCM. Nothing to do here except keep the isolate alive.
}

// ─────────────────────────────────────────────────────────────────────────────

/// Wraps Firebase Cloud Messaging + flutter_local_notifications.
///
/// Lifecycle:
/// 1. Call [registerBackgroundHandler] once at the top of `main()`, before
///    `runApp`.
/// 2. Call [initialize] after the widget tree is mounted (e.g. in
///    `MainShell.initState`) to wire up the tap callback and foreground display.
/// 3. Call [getAndSaveToken] once per session to keep the FCM token fresh in
///    Firestore so Cloud Functions can reach this device.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _fcm = FirebaseMessaging.instance;
  final _local = FlutterLocalNotificationsPlugin();

  // Android notification channel shared across the whole app.
  static const _channel = AndroidNotificationChannel(
    'hicampus_chat', // id
    'HiCampus Chat', // name shown in system settings
    description: 'Chat messages and connection requests',
    importance: Importance.high,
    playSound: true,
  );

  // ── One-time setup ──────────────────────────────────────────────────────────

  /// Register FCM background handler — call BEFORE `runApp()`.
  static void registerBackgroundHandler() {
    FirebaseMessaging.onBackgroundMessage(_fcmBackgroundHandler);
  }

  /// Wire up local-notification display and tap routing.
  ///
  /// Safe to call multiple times (re-registers handlers idempotently).
  Future<void> initialize({required NotificationTapCallback onTap}) async {
    // 1. Request OS permission (iOS / Android 13+).
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    // 2. On iOS, show notification banners while app is in foreground too.
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 3. Create Android channel.
    await _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);

    // 4. Init flutter_local_notifications (needed for foreground on Android).
    await _local.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false, // already done by FCM above
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (details) {
        onTap(details.payload ?? '');
      },
    );

    // 5. Foreground messages → show via flutter_local_notifications
    //    (FCM suppresses the system banner when app is in foreground on Android).
    FirebaseMessaging.onMessage.listen((msg) => _showLocal(msg, onTap));

    // 6. Background tap (app was suspended, not killed).
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      onTap(msg.data['convId'] as String? ?? '');
    });

    // 7. Terminated tap (app was killed, user tapped notification to open).
    final initial = await _fcm.getInitialMessage();
    if (initial != null) {
      // Slight delay so Navigator is ready before we push.
      Future.delayed(const Duration(milliseconds: 600), () {
        onTap(initial.data['convId'] as String? ?? '');
      });
    }
  }

  // ── Token management ────────────────────────────────────────────────────────

  /// Returns the current FCM registration token, or null if unavailable.
  ///
  /// On web, a VAPID key is required. Generate one in:
  /// Firebase Console → Project Settings → Cloud Messaging → Web Push certificates.
  /// Replace [_kVapidKey] with your key pair.
  ///
  /// Returns null on iOS Simulator (APNs not supported) or when the OS has
  /// not yet delivered an APNs token — both are safe to ignore.
  static const _kVapidKey =
      'BLMvFqoE9d2NQ3kp6BPvrxGiM2ePSbjbs7phno78mk14uhrwqnpZFQW9DP1CVxe0UGzyXo2Yeo9YvqWfzvaScUE'; // 🔑 replace after generating in Firebase Console

  Future<String?> getToken() async {
    try {
      if (kIsWeb) {
        return await _fcm.getToken(vapidKey: _kVapidKey);
      }
      return await _fcm.getToken();
    } catch (_) {
      // apns-token-not-set on iOS Simulator — not a real device error.
      return null;
    }
  }

  /// Subscribes to token refresh events and calls [onRefresh] so the caller
  /// can persist the new token to Firestore.
  void listenTokenRefresh(void Function(String token) onRefresh) {
    _fcm.onTokenRefresh.listen(onRefresh);
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  void _showLocal(RemoteMessage msg, NotificationTapCallback onTap) {
    final n = msg.notification;
    if (n == null) return;

    _local.show(
      // Use a stable ID derived from the convId so duplicate messages don't
      // stack (e.g. rapid-fire messages from same conversation).
      (msg.data['convId'] ?? '').hashCode,
      n.title,
      n.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: msg.data['convId'] as String? ?? '',
    );
  }
}
