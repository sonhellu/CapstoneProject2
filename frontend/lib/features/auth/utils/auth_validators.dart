class AuthValidators {
  static final RegExp _email = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Vui lòng nhập email';
    if (!_email.hasMatch(v)) return 'Email không hợp lệ';
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Vui lòng nhập mật khẩu';
    if (v.length < 8) return 'Mật khẩu cần ít nhất 8 ký tự';
    return null;
  }

  static String? name(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Vui lòng nhập họ tên';
    if (v.length < 2) return 'Họ tên quá ngắn';
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    final v = value ?? '';
    if (v.isEmpty) return 'Vui lòng xác nhận mật khẩu';
    if (v != password) return 'Mật khẩu xác nhận không khớp';
    return null;
  }
}
