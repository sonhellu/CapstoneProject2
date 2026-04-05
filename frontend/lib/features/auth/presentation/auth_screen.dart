import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../core/widgets/language_picker_button.dart';
import '../../../l10n/app_localizations.dart';
import '../theme/auth_theme.dart';
import 'login_form.dart';
import 'register_form.dart';
import 'widgets/auth_card.dart';
import 'widgets/auth_header.dart';

enum AuthMode { login, register }

/// Màn hình đăng nhập / đăng ký với chuyển đổi mượt.
class AuthScreen extends HookWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mode = useState(AuthMode.login);
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AuthColors.background,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxW = constraints.maxWidth > 560
                    ? 480.0
                    : constraints.maxWidth - 32;
                return Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: constraints.maxWidth > 600 ? 40 : 20,
                      vertical: 16,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: maxW),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 8),
                          const AuthHeader(),
                          const SizedBox(height: 28),
                          AuthCard(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 420),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              transitionBuilder: (child, animation) {
                                final offset =
                                    Tween<Offset>(
                                      begin: const Offset(0.04, 0),
                                      end: Offset.zero,
                                    ).animate(
                                      CurvedAnimation(
                                        parent: animation,
                                        curve: Curves.easeOutCubic,
                                      ),
                                    );
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: offset,
                                    child: child,
                                  ),
                                );
                              },
                              child: mode.value == AuthMode.login
                                  ? Column(
                                      key: const ValueKey('login'),
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l.authLoginTitle,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                                color: AuthColors.textPrimary,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          l.authLoginSubtitle,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: AuthColors.textSecondary,
                                              ),
                                        ),
                                        const SizedBox(height: 22),
                                        const LoginForm(),
                                      ],
                                    )
                                  : Column(
                                      key: const ValueKey('register'),
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l.authRegisterTitle,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                                color: AuthColors.textPrimary,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          l.authRegisterSubtitle,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: AuthColors.textSecondary,
                                              ),
                                        ),
                                        const SizedBox(height: 22),
                                        const RegisterForm(),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                mode.value == AuthMode.login
                                    ? l.authFooterNoAccount
                                    : l.authFooterHasAccount,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: AuthColors.textSecondary),
                              ),
                              TextButton(
                                onPressed: () {
                                  mode.value = mode.value == AuthMode.login
                                      ? AuthMode.register
                                      : AuthMode.login;
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: AuthColors.primary,
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                child: Text(
                                  mode.value == AuthMode.login
                                      ? l.authSwitchToRegister
                                      : l.authSwitchToLogin,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 0,
            right: 4,
            child: SafeArea(
              child: Material(
                color: Colors.transparent,
                child: const LanguagePickerButton(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
