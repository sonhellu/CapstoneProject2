import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/feedback/app_snackbar.dart';
import '../../../core/theme/theme_ext.dart';
import '../../../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';

class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _resendCooldown = false;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkVerified() async {
    final auth = context.read<AuthProvider>();
    await auth.reloadUser();
    if (!mounted) return;
    if (auth.isEmailVerified) {
      showSuccessSnackBar(
        context,
        AppLocalizations.of(context)!.authSuccessVerified,
      );
      await auth.signOut();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.verifyEmailNotYet),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _resend() async {
    if (_resendCooldown) return;
    try {
      await context.read<AuthProvider>().resendVerificationEmail();
      _startCooldown();
      if (mounted) {
        showSuccessSnackBar(
          context,
          AppLocalizations.of(context)!.verifyEmailResendSent,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        showErrorTextSnackBar(context, e.message ?? e.code);
      }
    }
  }

  void _startCooldown() {
    setState(() {
      _resendCooldown = true;
      _cooldownSeconds = 60;
    });
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_cooldownSeconds <= 1) {
        t.cancel();
        setState(() => _resendCooldown = false);
      } else {
        setState(() => _cooldownSeconds--);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final email = context.read<AuthProvider>().userEmail ?? '';

    final p = context.primary;
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: context.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.logout_rounded, color: context.onSurfaceVar),
          tooltip: l.profileLogout,
          onPressed: () => context.read<AuthProvider>().signOut(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: p.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mark_email_unread_outlined,
                  size: 48,
                  color: p,
                ),
              ),
              const SizedBox(height: 28),

              // Title
              Text(
                l.verifyEmailTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: context.onSurface,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Subtitle with email
              Text(
                l.verifyEmailSubtitle(email),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.onSurfaceVar,
                      height: 1.5,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // "I already verified" button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: p,
                    foregroundColor: cs.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _checkVerified,
                  child: Text(
                    l.verifyEmailCheckButton,
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: cs.onPrimary),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Resend button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: p,
                    side: BorderSide(color: p),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _resendCooldown ? null : _resend,
                  child: Text(
                    _resendCooldown
                        ? l.verifyEmailResendCooldown(_cooldownSeconds)
                        : l.verifyEmailResendButton,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
