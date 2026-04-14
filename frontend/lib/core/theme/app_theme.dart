import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────── Color Tokens ────────────────────────────────────

abstract final class HiColors {
  // ── Brand ──────────────────────────────────────────────────────────────────
  static const primary        = Color(0xFF2563EB);
  static const primaryLight   = Color(0xFF3B82F6);
  static const primaryDark    = Color(0xFF1D4ED8);
  static const primarySurface = Color(0xFFEFF6FF); // light tint for chips/badges

  static const secondary      = Color(0xFF0EA5E9); // sky accent
  static const secondarySurface = Color(0xFFE0F2FE);

  // ── Semantic ───────────────────────────────────────────────────────────────
  static const success          = Color(0xFF10B981);
  static const successSurface   = Color(0xFFD1FAE5);
  static const error            = Color(0xFFEF4444);
  static const errorSurface     = Color(0xFFFEE2E2);
  static const warning          = Color(0xFFF59E0B);
  static const warningSurface   = Color(0xFFFEF3C7);

  // ── Light palette ──────────────────────────────────────────────────────────
  static const bgLight          = Color(0xFFF8FAFC);
  static const surfaceLight     = Color(0xFFFFFFFF);
  static const surfaceVarLight  = Color(0xFFF1F5F9);
  static const borderLight      = Color(0xFFE2E8F0);
  static const textPrimLight    = Color(0xFF0F172A);
  static const textSecLight     = Color(0xFF64748B);
  static const textDisLight     = Color(0xFFCBD5E1);

  // ── Dark palette ───────────────────────────────────────────────────────────
  static const bgDark           = Color(0xFF0F172A);
  static const surfaceDark      = Color(0xFF1E293B);
  static const surfaceVarDark   = Color(0xFF334155);
  static const borderDark       = Color(0xFF334155);
  static const textPrimDark     = Color(0xFFF1F5F9);
  static const textSecDark      = Color(0xFF94A3B8);
  static const textDisDark      = Color(0xFF475569);
}

// ─────────────────────────── Radius Tokens ───────────────────────────────────

abstract final class HiRadius {
  static const double xs  = 8;
  static const double sm  = 12;
  static const double md  = 16;
  static const double lg  = 20;
  static const double xl  = 24;
  static const double full = 999;
}

// ─────────────────────────── Spacing Tokens ──────────────────────────────────

abstract final class HiSpacing {
  static const double xs  = 4;
  static const double sm  = 8;
  static const double md  = 16;
  static const double lg  = 24;
  static const double xl  = 32;
  static const double xxl = 48;
}

// ─────────────────────────── Shadow Tokens ───────────────────────────────────

abstract final class HiShadow {
  static List<BoxShadow> sm = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> md = [
    BoxShadow(
      color: HiColors.primary.withValues(alpha: 0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> lg = [
    BoxShadow(
      color: HiColors.primary.withValues(alpha: 0.12),
      blurRadius: 32,
      offset: const Offset(0, 12),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
}

// ─────────────────────────── App Theme ───────────────────────────────────────

abstract final class AppTheme {
  // ── Typography ─────────────────────────────────────────────────────────────
  // Noto Sans KR: covers Latin, Hangul, CJK, Vietnamese, Japanese
  // Noto Sans Myanmar: required for Burmese Unicode
  static TextTheme _textTheme(Locale locale) => locale.languageCode == 'my'
      ? GoogleFonts.notoSansMyanmarTextTheme()
      : GoogleFonts.notoSansKrTextTheme();

  // ── Light Theme ────────────────────────────────────────────────────────────
  static ThemeData light(Locale locale) {
    final text = _textTheme(locale);

    final cs = ColorScheme(
      brightness:         Brightness.light,
      primary:            HiColors.primary,
      onPrimary:          Colors.white,
      primaryContainer:   HiColors.primarySurface,
      onPrimaryContainer: HiColors.primaryDark,
      secondary:          HiColors.secondary,
      onSecondary:        Colors.white,
      secondaryContainer: HiColors.secondarySurface,
      onSecondaryContainer: HiColors.primaryDark,
      surface:            HiColors.surfaceLight,
      onSurface:          HiColors.textPrimLight,
      surfaceContainerHighest: HiColors.surfaceVarLight,
      onSurfaceVariant:   HiColors.textSecLight,
      outline:            HiColors.borderLight,
      outlineVariant:     HiColors.borderLight,
      error:              HiColors.error,
      onError:            Colors.white,
      errorContainer:     HiColors.errorSurface,
      onErrorContainer:   HiColors.error,
      shadow:             Colors.black,
      scrim:              Colors.black,
      inverseSurface:     HiColors.bgDark,
      onInverseSurface:   HiColors.textPrimDark,
      inversePrimary:     HiColors.primaryLight,
    );

    return _buildTheme(cs, text, Brightness.light);
  }

  // ── Dark Theme ─────────────────────────────────────────────────────────────
  static ThemeData dark(Locale locale) {
    final text = _textTheme(locale).apply(
      bodyColor:        HiColors.textPrimDark,
      displayColor:     HiColors.textPrimDark,
      decorationColor:  HiColors.textSecDark,
    );

    final cs = ColorScheme(
      brightness:         Brightness.dark,
      primary:            HiColors.primaryLight,
      onPrimary:          Colors.white,
      primaryContainer:   HiColors.primaryDark,
      onPrimaryContainer: HiColors.primarySurface,
      secondary:          HiColors.secondary,
      onSecondary:        Colors.white,
      secondaryContainer: HiColors.primaryDark,
      onSecondaryContainer: HiColors.secondarySurface,
      surface:            HiColors.surfaceDark,
      onSurface:          HiColors.textPrimDark,
      surfaceContainerHighest: HiColors.surfaceVarDark,
      onSurfaceVariant:   HiColors.textSecDark,
      outline:            HiColors.borderDark,
      outlineVariant:     HiColors.borderDark,
      error:              HiColors.error,
      onError:            Colors.white,
      errorContainer:     const Color(0xFF7F1D1D),
      onErrorContainer:   HiColors.errorSurface,
      shadow:             Colors.black,
      scrim:              Colors.black,
      inverseSurface:     HiColors.surfaceVarLight,
      onInverseSurface:   HiColors.textPrimLight,
      inversePrimary:     HiColors.primary,
    );

    return _buildTheme(cs, text, Brightness.dark);
  }

  // ── Shared builder ─────────────────────────────────────────────────────────
  static ThemeData _buildTheme(
    ColorScheme cs,
    TextTheme text,
    Brightness brightness,
  ) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: cs,
      textTheme: text,
      scaffoldBackgroundColor: isDark ? HiColors.bgDark : HiColors.bgLight,

      // ── AppBar ─────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? HiColors.surfaceDark : HiColors.surfaceLight,
        foregroundColor: isDark ? HiColors.textPrimDark : HiColors.textPrimLight,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: text.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: isDark ? HiColors.textPrimDark : HiColors.textPrimLight,
        ),
      ),

      // ── Card ───────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: isDark ? HiColors.surfaceDark : HiColors.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HiRadius.lg),
          side: BorderSide(
            color: isDark ? HiColors.borderDark : HiColors.borderLight,
            width: 1,
          ),
        ),
        margin: EdgeInsets.zero,
      ),

      // ── Input ──────────────────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        floatingLabelBehavior: FloatingLabelBehavior.never,
        filled: true,
        fillColor: isDark ? HiColors.surfaceVarDark : HiColors.bgLight,
        hintStyle: TextStyle(
          color: isDark
              ? HiColors.textDisDark
              : HiColors.textSecLight.withValues(alpha: 0.7),
          fontWeight: FontWeight.w400,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: HiSpacing.md,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HiRadius.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HiRadius.md),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HiRadius.md),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HiRadius.md),
          borderSide: const BorderSide(color: HiColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(HiRadius.md),
          borderSide: const BorderSide(color: HiColors.error, width: 1.5),
        ),
      ),

      // ── ElevatedButton ─────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: HiColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: HiSpacing.lg,
            vertical: 14,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HiRadius.md),
          ),
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),

      // ── OutlinedButton ─────────────────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? HiColors.primaryLight : HiColors.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: HiSpacing.lg,
            vertical: 14,
          ),
          side: BorderSide(
            color: isDark ? HiColors.primaryLight : HiColors.primary,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(HiRadius.md),
          ),
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),

      // ── BottomSheet ────────────────────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? HiColors.surfaceDark : HiColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(HiRadius.xl),
          ),
        ),
        showDragHandle: true,
        dragHandleColor: isDark ? HiColors.borderDark : HiColors.borderLight,
      ),

      // ── NavigationBar ──────────────────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? HiColors.surfaceDark : HiColors.surfaceLight,
        indicatorColor: isDark
            ? HiColors.primaryDark.withValues(alpha: 0.3)
            : HiColors.primarySurface,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return text.labelSmall?.copyWith(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
            color: selected
                ? (isDark ? HiColors.primaryLight : HiColors.primary)
                : (isDark ? HiColors.textSecDark : HiColors.textSecLight),
          );
        }),
      ),

      // ── Chip ───────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? HiColors.surfaceVarDark : HiColors.bgLight,
        selectedColor: HiColors.primary,
        labelStyle: text.labelSmall?.copyWith(fontWeight: FontWeight.w600),
        side: BorderSide(
          color: isDark ? HiColors.borderDark : HiColors.borderLight,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HiRadius.full),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: HiSpacing.sm,
          vertical: 2,
        ),
      ),

      // ── Divider ────────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: isDark ? HiColors.borderDark : HiColors.borderLight,
        thickness: 1,
        space: 1,
      ),

      // ── SnackBar ───────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? HiColors.surfaceVarDark : HiColors.textPrimLight,
        contentTextStyle: text.bodyMedium?.copyWith(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HiRadius.sm),
        ),
      ),
    );
  }
}
