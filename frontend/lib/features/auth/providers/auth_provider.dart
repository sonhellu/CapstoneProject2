import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../chat/repository/user_repository.dart';

class AuthProvider extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;

  User? get firebaseUser => _auth.currentUser;
  bool get isAuthenticated => firebaseUser != null;
  bool get isEmailVerified => firebaseUser?.emailVerified ?? false;
  String? get userEmail => firebaseUser?.email;
  String? get displayName => firebaseUser?.displayName;
  String? get uid => firebaseUser?.uid;

  /// Returns the current Firebase ID token (for API calls).
  Future<String?> getIdToken() =>
      firebaseUser?.getIdToken() ?? Future.value(null);

  AuthProvider() {
    // Listen to sign-in / sign-out events
    _auth.authStateChanges().listen((_) => notifyListeners());
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    final user = cred.user;
    if (user != null) {
      await UserRepository.instance.saveOrUpdateProfile(
        uid: user.uid,
        displayName: user.displayName ?? email.split('@').first,
        email: email,
      );
    }
  }

  Future<void> registerWithEmail({
    required String name,
    required String email,
    required String password,
    required String nationality,
    required String nativeLanguage,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (name.isNotEmpty) {
      await cred.user?.updateDisplayName(name);
    }
    final user = cred.user;
    if (user != null) {
      await UserRepository.instance.saveOrUpdateProfile(
        uid: user.uid,
        displayName: name.isNotEmpty ? name : email.split('@').first,
        email: email,
        nationality: nationality,
        nativeLanguage: nativeLanguage,
      );
    }
    // Send verification email immediately after registration
    await cred.user?.sendEmailVerification();
    notifyListeners();
  }

  /// Call this when user says they already clicked the link.
  /// Reloads the Firebase user to get the latest emailVerified status.
  Future<void> reloadUser() async {
    await firebaseUser?.reload();
    notifyListeners();
  }

  /// Resend verification email (e.g. from VerifyEmailScreen).
  Future<void> resendVerificationEmail() async {
    await firebaseUser?.sendEmailVerification();
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
