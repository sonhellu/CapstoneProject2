import 'package:flutter/material.dart';

/// Shared page route factory — use instead of bare [MaterialPageRoute].
///
/// [fadeSlide] — content slides up 6% + fades in (320 ms, easeOutCubic).
/// Consistent across all push navigations in the app.
abstract final class AppTransitions {
  static Route<T> fadeSlide<T>(Widget page, {Duration? duration}) {
    return PageRouteBuilder<T>(
      pageBuilder: (_, _, _) => page,
      transitionDuration: duration ?? const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 260),
      transitionsBuilder: (_, animation, _, child) {
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
        return SlideTransition(
          position: slide,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );
  }

  /// Instant swap with a short fade — good for lateral tab-like pushes.
  static Route<T> fade<T>(Widget page, {Duration? duration}) {
    return PageRouteBuilder<T>(
      pageBuilder: (_, _, _) => page,
      transitionDuration: duration ?? const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    );
  }
}
