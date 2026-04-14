import 'package:flutter/material.dart';

import '../../../../core/theme/theme_ext.dart';
import '../../theme/auth_theme.dart';

class AuthCard extends StatelessWidget {
  const AuthCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: context.cardFill,
        borderRadius: BorderRadius.circular(AuthRadii.lg),
        boxShadow: context.cardElevationShadow,
        border: Border.all(color: context.outline.withValues(alpha: 0.6)),
      ),
      child: child,
    );
  }
}
