import 'package:flutter/material.dart';

/// Quick access to theme tokens from any BuildContext.
///
/// Usage:
///   context.cs.primary          → ColorScheme.primary
///   context.tt.bodyMedium       → TextTheme.bodyMedium
///   context.isDark              → true if dark mode
///   context.surface             → surface color
///   context.bg                  → scaffold background
///   context.onSurface           → text on surface
///   context.dividerColor        → divider
extension ThemeX on BuildContext {
  ThemeData   get theme     => Theme.of(this);
  ColorScheme get cs        => Theme.of(this).colorScheme;
  TextTheme   get tt        => Theme.of(this).textTheme;
  bool        get isDark    => Theme.of(this).brightness == Brightness.dark;

  // ── Common color shortcuts ───────────────────────────────────────────────
  Color get bg          => Theme.of(this).scaffoldBackgroundColor;
  Color get surface     => cs.surface;
  Color get surfaceVar  => cs.surfaceContainerHighest;
  Color get primary     => cs.primary;
  Color get onSurface   => cs.onSurface;
  Color get onSurfaceVar => cs.onSurfaceVariant;
  Color get outline     => cs.outline;
  Color get divider     => Theme.of(this).dividerColor;

  /// Card/container fill: white in light, dark surface in dark.
  Color get cardFill    => isDark ? cs.surfaceContainerHighest : cs.surface;

  /// Subtle background tint for chips/badges.
  Color get subtleFill  => isDark
      ? cs.surfaceContainerHighest.withValues(alpha: 0.6)
      : cs.surfaceContainerHighest.withValues(alpha: 0.4);

  /// Hint / tertiary text (replaces hardcoded grey-400).
  Color get hintColor =>
      onSurfaceVar.withValues(alpha: isDark ? 0.85 : 0.75);

  /// Card drop shadow tuned for light vs dark surfaces.
  List<BoxShadow> get cardElevationShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];
}
