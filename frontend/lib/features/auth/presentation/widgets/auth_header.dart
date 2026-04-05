import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../l10n/app_localizations.dart';
import '../../theme/auth_theme.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AuthColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AuthRadii.lg),
            boxShadow: [
              BoxShadow(
                color: AuthColors.primary.withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SvgPicture.asset(
            'assets/auth/auth_globe.svg',
            width: 120,
            height: 100,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          l.authHeaderTitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AuthColors.textPrimary,
                letterSpacing: -0.5,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          l.authHeaderSubtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AuthColors.textSecondary,
                height: 1.45,
              ),
        ),
      ],
    );
  }
}
