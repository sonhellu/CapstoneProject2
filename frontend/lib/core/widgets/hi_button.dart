import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

enum HiButtonVariant { primary, outlined, ghost }

/// Unified button with haptic feedback and built-in loading state.
///
/// Usage:
/// ```dart
/// HiButton(
///   label: l.authButtonLogin,
///   isLoading: loading.value,
///   onPressed: submit,
/// )
/// ```
class HiButton extends StatelessWidget {
  const HiButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.variant = HiButtonVariant.primary,
    this.icon,
    this.fullWidth = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final HiButtonVariant variant;
  final IconData? icon;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    Widget child = isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation(
                variant == HiButtonVariant.primary
                    ? Colors.white
                    : cs.primary,
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: 8),
              ],
              Text(label),
            ],
          );

    if (fullWidth) {
      child = Center(child: child);
    }

    void handlePress() {
      if (isLoading || onPressed == null) return;
      HapticFeedback.lightImpact();
      onPressed!();
    }

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(HiRadius.md),
    );

    const padding = EdgeInsets.symmetric(horizontal: 24, vertical: 14);

    switch (variant) {
      case HiButtonVariant.primary:
        return SizedBox(
          width: fullWidth ? double.infinity : null,
          height: 50,
          child: ElevatedButton(
            onPressed: (isLoading || onPressed == null) ? null : handlePress,
            style: ElevatedButton.styleFrom(
              padding: padding,
              shape: shape,
            ),
            child: child,
          ),
        );

      case HiButtonVariant.outlined:
        return SizedBox(
          width: fullWidth ? double.infinity : null,
          height: 50,
          child: OutlinedButton(
            onPressed: (isLoading || onPressed == null) ? null : handlePress,
            style: OutlinedButton.styleFrom(
              padding: padding,
              shape: shape,
            ),
            child: child,
          ),
        );

      case HiButtonVariant.ghost:
        return SizedBox(
          width: fullWidth ? double.infinity : null,
          height: 50,
          child: TextButton(
            onPressed: (isLoading || onPressed == null) ? null : handlePress,
            style: TextButton.styleFrom(
              padding: padding,
              shape: shape,
            ),
            child: child,
          ),
        );
    }
  }
}
