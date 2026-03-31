import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Lớp phủ nhẹ giữa màn hình khi đổi locale — tránh cảm giác “khựng”.
class LocaleChangeOverlay extends StatelessWidget {
  const LocaleChangeOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final border = scheme.outlineVariant;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      builder: (context, t, child) {
        return Opacity(opacity: t, child: child);
      },
      child: AbsorbPointer(
        child: Material(
          color: scheme.surface.withValues(alpha: 0.82),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Shimmer.fromColors(
                  baseColor: border.withValues(alpha: 0.65),
                  highlightColor: scheme.surface,
                  period: const Duration(milliseconds: 1100),
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: scheme.primary.withValues(alpha: 0.14),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.8,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
