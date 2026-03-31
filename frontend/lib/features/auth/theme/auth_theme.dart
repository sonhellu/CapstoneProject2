import 'package:flutter/material.dart';

/// Bảng màu tối giản: xanh giáo dục + nền sáng.
abstract final class AuthColors {
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
  static const Color kakao = Color(0xFFFEE500);
  static const Color googleBlue = Color(0xFF4285F4);

  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: const Color(0xFF2563EB).withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
}

abstract final class AuthRadii {
  static const double sm = 16;
  static const double md = 20;
  static const double lg = 24;
}
