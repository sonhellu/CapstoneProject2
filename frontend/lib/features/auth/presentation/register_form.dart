import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../utils/auth_validators.dart';
import 'widgets/auth_primary_button.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/social_auth_buttons.dart';

class RegisterForm extends HookWidget {
  const RegisterForm({super.key});

  void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final formKey = useMemoized(GlobalKey<FormState>.new);
    final name = useTextEditingController();
    final email = useTextEditingController();
    final password = useTextEditingController();
    final confirm = useTextEditingController();
    final obscure = useState(true);
    final obscureConfirm = useState(true);
    final loading = useState(false);

    Future<void> submit() async {
      if (!(formKey.currentState?.validate() ?? false)) return;
      loading.value = true;
      try {
        await context.read<AuthProvider>().registerWithEmail(
              name: name.text.trim(),
              email: email.text.trim(),
              password: password.text,
            );
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
            key: const Key('register_name'),
            controller: name,
            label: l.authFieldFullName,
            hint: l.authHintNameExample,
            prefixIcon: Icons.person_outline_rounded,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.name],
            validator: (v) => AuthValidators.name(v, l),
          ),
          const SizedBox(height: 16),
          AuthTextField(
            key: const Key('register_email'),
            controller: email,
            label: l.authFieldEmail,
            hint: l.authHintEmail,
            prefixIcon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            validator: (v) => AuthValidators.email(v, l),
          ),
          const SizedBox(height: 16),
          AuthTextField(
            key: const Key('register_password'),
            controller: password,
            label: l.authFieldPassword,
            hint: l.authHintPasswordMin,
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: obscure.value,
            showObscureToggle: true,
            onToggleObscure: () => obscure.value = !obscure.value,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.newPassword],
            validator: (v) => AuthValidators.password(v, l),
          ),
          const SizedBox(height: 16),
          AuthTextField(
            key: const Key('register_confirm'),
            controller: confirm,
            label: l.authFieldPasswordConfirm,
            hint: l.authHintConfirmPassword,
            prefixIcon: Icons.verified_user_outlined,
            obscureText: obscureConfirm.value,
            showObscureToggle: true,
            onToggleObscure: () => obscureConfirm.value = !obscureConfirm.value,
            textInputAction: TextInputAction.done,
            validator: (v) =>
                AuthValidators.confirmPassword(v, password.text, l),
            onSubmitted: (_) => submit(),
          ),
          const SizedBox(height: 24),
          AuthPrimaryButton(
            key: const Key('register_submit'),
            label: l.authButtonRegister,
            isLoading: loading.value,
            onPressed: submit,
          ),
          const SizedBox(height: 24),
          SocialAuthButtons(
            onGoogle: () => _snack(context, l.authSocialGoogleRegisterDemo),
            onKakao: () => _snack(context, l.authSocialKakaoRegisterDemo),
          ),
        ],
      ),
    );
  }
}
