import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';

import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../utils/auth_validators.dart';
import 'widgets/auth_primary_button.dart';
import 'widgets/auth_text_field.dart';

class LoginForm extends HookWidget {
  const LoginForm({super.key});

  void _snack(BuildContext context, String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        behavior: SnackBarBehavior.floating,
        backgroundColor: success ? const Color(0xFF2E7D32) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final email = useTextEditingController();
    final password = useTextEditingController();
    final obscure = useState(true);
    final loading = useState(false);

    Future<void> submit() async {
      if (!(formKey.currentState?.validate() ?? false)) return;
      loading.value = true;
      try {
        await context.read<AuthProvider>().signInWithEmail(
              email: email.text.trim(),
              password: password.text,
            );
        if (context.mounted) {
          _snack(context, AppLocalizations.of(context)!.authSuccessLogin, success: true);
        }
      } on FirebaseAuthException catch (e) {
        if (!context.mounted) return;
        final l = AppLocalizations.of(context)!;
        final msg = switch (e.code) {
          'user-not-found' || 'invalid-credential' => l.authErrInvalidCredential,
          'wrong-password' => l.authErrWrongPassword,
          'too-many-requests' => l.authErrTooManyRequests,
          'user-disabled' => l.authErrUserDisabled,
          _ => l.authErrDefault(e.message ?? e.code),
        };
        _snack(context, msg);
      } finally {
        if (context.mounted) loading.value = false;
      }
    }

    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthTextField(
            key: const Key('login_email'),
            controller: email,
            label: l.authFieldEmail,
            hint: l.authHintEmail,
            prefixIcon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            validator: (v) => AuthValidators.email(v, l),
          ),
          const SizedBox(height: 18),
          AuthTextField(
            key: const Key('login_password'),
            controller: password,
            label: l.authFieldPassword,
            hint: l.authHintPasswordDots,
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: obscure.value,
            showObscureToggle: true,
            onToggleObscure: () => obscure.value = !obscure.value,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            validator: (v) => AuthValidators.password(v, l),
            onSubmitted: (_) => submit(),
          ),
          const SizedBox(height: 24),
          AuthPrimaryButton(
            key: const Key('login_submit'),
            label: l.authButtonLogin,
            isLoading: loading.value,
            onPressed: submit,
          ),
        ],
      ),
    );
  }
}
