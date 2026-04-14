import 'package:flutter/material.dart';

import '../../../../core/theme/theme_ext.dart';
import '../../../../l10n/app_localizations.dart';
import '../../theme/auth_theme.dart';

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onToggleObscure,
    this.showObscureToggle = false,
    this.autofillHints,
    this.onSubmitted,
    this.suffixWidget,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData prefixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final VoidCallback? onToggleObscure;
  final bool showObscureToggle;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffixWidget;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: context.onSurface,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          validator: validator,
          autofillHints: autofillHints,
          onFieldSubmitted: onSubmitted,
          style: TextStyle(
            color: context.onSurface,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: context.onSurfaceVar.withValues(alpha: 0.85),
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: context.subtleFill,
            prefixIcon: Icon(
              prefixIcon,
              color: context.primary.withValues(alpha: 0.85),
              size: 22,
            ),
            suffixIcon: showObscureToggle
                ? IconButton(
                    tooltip: obscureText
                        ? l.authTooltipShowPassword
                        : l.authTooltipHidePassword,
                    onPressed: onToggleObscure,
                    icon: Icon(
                      obscureText
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: context.onSurfaceVar,
                    ),
                  )
                : suffixWidget,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AuthRadii.sm),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AuthRadii.sm),
              borderSide: BorderSide(
                color: context.outline.withValues(alpha: 0.9),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AuthRadii.sm),
              borderSide: BorderSide(
                color: context.primary,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AuthRadii.sm),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error.withValues(alpha: 0.8),
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AuthRadii.sm),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.error,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }
}
