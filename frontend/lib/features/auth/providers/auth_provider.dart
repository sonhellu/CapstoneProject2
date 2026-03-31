import 'package:flutter/foundation.dart';

/// Trạng thái đăng nhập (mock — thay bằng API thật sau).
class AuthProvider extends ChangeNotifier {
  bool _isAuthenticated = false;
  String? _userEmail;
  String? _displayName;

  bool get isAuthenticated => _isAuthenticated;
  String? get userEmail => _userEmail;
  String? get displayName => _displayName;

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _userEmail = email;
    _displayName = null;
    _isAuthenticated = true;
    notifyListeners();
  }

  Future<void> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    _userEmail = email;
    _displayName = name.isEmpty ? null : name;
    _isAuthenticated = true;
    notifyListeners();
  }

  void signOut() {
    _isAuthenticated = false;
    _userEmail = null;
    _displayName = null;
    notifyListeners();
  }
}
