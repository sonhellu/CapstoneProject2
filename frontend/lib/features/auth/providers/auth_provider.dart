import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../chat/repository/user_repository.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? authService, UserRepository? userRepository})
    : _authService = authService ?? AuthService(),
      _userRepository = userRepository {
    _authSub = _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  final AuthService _authService;
  final UserRepository? _userRepository;
  late final StreamSubscription<User?> _authSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _profileSub;

  String? _school;
  String? _firestoreDisplayName;

  UserRepository get _profiles => _userRepository ?? UserRepository.instance;

  User? get firebaseUser => _authService.currentUser;
  bool get isAuthenticated => firebaseUser != null;
  bool get isEmailVerified => firebaseUser?.emailVerified ?? false;
  String? get userEmail => firebaseUser?.email;
  String? get displayName => firebaseUser?.displayName;
  String? get uid => firebaseUser?.uid;

  /// University name from Firestore — updates in realtime when profile is saved.
  String? get school => _school;

  /// Display name from Firestore (most up-to-date), falling back to Firebase
  /// Auth displayName, then the email username.
  String get nickname =>
      (_firestoreDisplayName?.trim().isNotEmpty == true
          ? _firestoreDisplayName!.trim()
          : null) ??
      (firebaseUser?.displayName?.trim().isNotEmpty == true
          ? firebaseUser!.displayName!.trim()
          : null) ??
      (userEmail?.split('@').first ?? 'User');

  void _onAuthStateChanged(User? user) {
    _profileSub?.cancel();
    if (user != null) {
      _profileSub = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((snap) {
            final data = snap.data();
            _school = data?['school'] as String?;
            _firestoreDisplayName = data?['displayName'] as String?;
            notifyListeners();
          });
    } else {
      _school = null;
      _firestoreDisplayName = null;
      notifyListeners();
    }
  }

  /// Returns the current Firebase ID token (for API calls).
  Future<String?> getIdToken() => _authService.getIdToken();

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final cred = await _authService.signInWithEmail(
      email: email,
      password: password,
    );
    final user = cred.user;
    if (user != null) {
      await _profiles.saveOrUpdateProfile(
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
    final cred = await _authService.registerWithEmail(
      email: email,
      password: password,
    );
    if (name.isNotEmpty) {
      await cred.user?.updateDisplayName(name);
    }
    final user = cred.user;
    if (user != null) {
      await _profiles.saveOrUpdateProfile(
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
    await _authService.reloadCurrentUser();
    notifyListeners();
  }

  /// Resend verification email (e.g. from VerifyEmailScreen).
  Future<void> resendVerificationEmail() async {
    await _authService.resendVerificationEmail();
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  @override
  void dispose() {
    _authSub.cancel();
    _profileSub?.cancel();
    super.dispose();
  }
}
