import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  AuthService({FirebaseAuth? firebaseAuth}) : _firebaseAuth = firebaseAuth;

  final FirebaseAuth? _firebaseAuth;

  FirebaseAuth get _auth => _firebaseAuth ?? FirebaseAuth.instance;

  FirebaseAuth? get _safeAuth {
    try {
      return _auth;
    } on FirebaseException catch (e) {
      if (e.code == 'no-app') return null;
      rethrow;
    }
  }

  User? get currentUser => _safeAuth?.currentUser;
  Stream<User?> get authStateChanges =>
      _safeAuth?.authStateChanges() ?? Stream<User?>.value(null);

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> reloadCurrentUser() async {
    await currentUser?.reload();
  }

  Future<void> resendVerificationEmail() async {
    await currentUser?.sendEmailVerification();
  }

  Future<String?> getIdToken() {
    return currentUser?.getIdToken() ?? Future.value(null);
  }

  Future<void> signOut() => _auth.signOut();
}
