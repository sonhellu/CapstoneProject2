import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../theme/shell_theme.dart';

/// Overlay khi khởi tạo Maps — CircularProgressIndicator tùy chỉnh.
class MapLoadingOverlay extends StatelessWidget {
  const MapLoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Material(
      color: Colors.white.withValues(alpha: 0.92),
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.85, end: 1),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          builder: (context, scale, child) {
            return Transform.scale(scale: scale, child: child);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 52,
                height: 52,
                child: CircularProgressIndicator(
                  strokeWidth: 3.2,
                  color: ShellColors.primaryBlue,
                  backgroundColor: ShellColors.primaryBlue.withValues(alpha: 0.12),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l.statusLoadingMap,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: ShellColors.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
