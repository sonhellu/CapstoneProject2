import 'package:flutter/material.dart';

import '../../../../core/theme/theme_ext.dart';
import '../../../../l10n/app_localizations.dart';
import '../../theme/auth_theme.dart';

class SocialAuthButtons extends StatelessWidget {
  const SocialAuthButtons({
    super.key,
    required this.onGoogle,
    required this.onKakao,
  });

  final VoidCallback onGoogle;
  final VoidCallback onKakao;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: Divider(
                    color: context.outline.withValues(alpha: 0.9))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                l.authSocialOr,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.onSurfaceVar,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            Expanded(
                child: Divider(
                    color: context.outline.withValues(alpha: 0.9))),
          ],
        ),
        const SizedBox(height: 18),
        _OutlineSocialButton(
          onPressed: onGoogle,
          borderColor: context.outline,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _GoogleMark(outline: context.outline),
              const SizedBox(width: 12),
              Text(
                l.authSocialContinueGoogle,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.onSurface,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _OutlineSocialButton(
          onPressed: onKakao,
          borderColor: AuthColors.kakao.withValues(alpha: 0.55),
          backgroundTint: AuthColors.kakao.withValues(alpha: 0.12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat_bubble_rounded, color: Colors.brown.shade800, size: 22),
              const SizedBox(width: 10),
              Text(
                l.authSocialKakaoLabel,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.brown.shade900,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark({required this.outline});
  final Color outline;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: outline),
      ),
      child: const Text(
        'G',
        style: TextStyle(
          color: AuthColors.googleBlue,
          fontWeight: FontWeight.w800,
          fontSize: 14,
          height: 1,
        ),
      ),
    );
  }
}

class _OutlineSocialButton extends StatelessWidget {
  const _OutlineSocialButton({
    required this.onPressed,
    required this.child,
    required this.borderColor,
    this.backgroundTint,
  });

  final VoidCallback onPressed;
  final Widget child;
  final Color borderColor;
  final Color? backgroundTint;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AuthRadii.sm),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AuthRadii.sm),
            border: Border.all(color: borderColor, width: 1.5),
            color: backgroundTint ?? Colors.transparent,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: child,
          ),
        ),
      ),
    );
  }
}
