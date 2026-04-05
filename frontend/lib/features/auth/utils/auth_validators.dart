import '../../../l10n/app_localizations.dart';

class AuthValidators {
  static final RegExp _email = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static String? email(String? value, AppLocalizations l) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return l.authValidationEmailEmpty;
    if (!_email.hasMatch(v)) return l.authValidationEmailInvalid;
    return null;
  }

  static String? password(String? value, AppLocalizations l) {
    final v = value ?? '';
    if (v.isEmpty) return l.authValidationPasswordEmpty;
    if (v.length < 8) return l.authValidationPasswordMin;
    return null;
  }

  static String? name(String? value, AppLocalizations l) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return l.authValidationNameEmpty;
    if (v.length < 2) return l.authValidationNameShort;
    return null;
  }

  static String? confirmPassword(String? value, String password, AppLocalizations l) {
    final v = value ?? '';
    if (v.isEmpty) return l.authValidationConfirmEmpty;
    if (v != password) return l.authValidationConfirmMismatch;
    return null;
  }
}
