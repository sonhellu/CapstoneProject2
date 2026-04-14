import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// Overlay khi khởi tạo Maps — CircularProgressIndicator tùy chỉnh.
class MapLoadingOverlay extends StatelessWidget {
  const MapLoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final p = cs.primary;
    return Material(
      color: cs.surface.withValues(alpha: 0.92),
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
                  color: p,
                  backgroundColor: p.withValues(alpha: 0.12),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l.statusLoadingMap,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: p,
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
