import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/locale/nationality_language.dart';
import '../models/chat_models.dart';

/// Manages the `users/{uid}` Firestore collection.
///
/// Call [saveOrUpdateProfile] on every sign-in/register to keep the doc fresh.
/// [searchPartners] queries all users and filters in-memory to avoid
/// composite index requirements during development.
class UserRepository {
  UserRepository._();
  static final UserRepository instance = UserRepository._();

  final _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _col => _db.collection('users');

  // ── Write ──────────────────────────────────────────────────────────────────

  /// Creates the profile doc if it doesn't exist yet; otherwise marks online.
  Future<void> saveOrUpdateProfile({
    required String uid,
    required String displayName,
    required String email,
    String? nationality,
    String? nativeLanguage,
  }) async {
    final ref = _col.doc(uid);
    final snap = await ref.get();
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
    final existing = snap.data();
    final resolvedNationality = (nationality != null && nationality.isNotEmpty)
        ? nationality
        : (existing?['nationality'] as String? ?? 'Unknown');
    final resolvedNative = nativeLanguageFromNationality(
      resolvedNationality,
      fallback: (nativeLanguage != null && nativeLanguage.isNotEmpty)
          ? nativeLanguage
          : 'English',
    );
    final defaultLearning = defaultLearningLanguageForNative(resolvedNative);

    if (!snap.exists) {
      await ref.set({
        'uid': uid,
        'displayName': displayName,
        'avatarInitial': initial,
        'email': email,
        'nationality': resolvedNationality,
        'nativeLanguage': resolvedNative,
        'learningLanguage': defaultLearning,
        'gender': 'other',
        'school': 'Keimyung University',
        'bio': 'Hi, I\'m using HiCampus!',
        'isOnline': true,
        'createdAt': FieldValue.serverTimestamp(),
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } else {
      final currentNative = existing?['nativeLanguage'] as String?;
      final currentLearning = existing?['learningLanguage'] as String?;
      final updates = <String, dynamic>{
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
      };
      if (nationality != null && nationality.isNotEmpty) {
        updates['nationality'] = resolvedNationality;
      }
      if (currentNative != resolvedNative) {
        updates['nativeLanguage'] = resolvedNative;
      }
      if (currentLearning == null ||
          currentLearning.trim().isEmpty ||
          currentLearning == currentNative ||
          currentLearning == resolvedNative) {
        updates['learningLanguage'] = defaultLearning;
      }
      await ref.update(updates);
    }
  }

  /// Partial update — only the provided non-null fields are written.
  Future<void> updateProfile({
    required String uid,
    String? displayName,
    String? nativeLanguage,
    String? learningLanguage,
    String? gender,
    String? school,
    String? nationality,
    String? major,
    String? bio,
  }) async {
    final data = <String, dynamic>{};
    if (displayName != null) {
      data['displayName'] = displayName;
      data['avatarInitial'] = displayName.isNotEmpty
          ? displayName[0].toUpperCase()
          : '?';
    }
    final derivedNative = nationality == null
        ? nativeLanguage
        : nativeLanguageFromNationality(
            nationality,
            fallback: nativeLanguage ?? 'English',
          );
    if (derivedNative != null) data['nativeLanguage'] = derivedNative;
    if (learningLanguage != null) {
      data['learningLanguage'] = learningLanguage;
    } else if (nationality != null && derivedNative != null) {
      data['learningLanguage'] = defaultLearningLanguageForNative(
        derivedNative,
      );
    }
    if (gender != null) data['gender'] = gender;
    if (school != null) data['school'] = school;
    if (nationality != null) data['nationality'] = nationality;
    if (major != null) data['major'] = major;
    if (bio != null) data['bio'] = bio;
    if (data.isNotEmpty) await _col.doc(uid).update(data);
  }

  /// Returns the raw Firestore document for [uid], or null if not found.
  Future<Map<String, dynamic>?> getRawProfile(String uid) async {
    final snap = await _col.doc(uid).get();
    if (!snap.exists || snap.data() == null) return null;
    return snap.data();
  }

  Future<void> setOnlineStatus(String uid, {required bool isOnline}) async {
    await _col.doc(uid).set({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Persists the FCM registration token so Cloud Functions can send
  /// push notifications to this device.
  /// Called once per session and whenever the token refreshes.
  Future<void> saveFcmToken(String uid, String token) async {
    // Use set+merge so this never throws when the user doc doesn't exist yet.
    await _col.doc(uid).set({'fcmToken': token}, SetOptions(merge: true));
  }

  // ── Read ───────────────────────────────────────────────────────────────────

  Future<PartnerModel?> getUser(String uid) async {
    final snap = await _col.doc(uid).get();
    if (!snap.exists || snap.data() == null) return null;
    return _fromDoc(snap);
  }

  /// Returns all users except [myUid], filtered by [gender] and
  /// [learningLanguage] (= the language the current user wants to learn,
  /// which must match partner's nativeLanguage).
  Future<List<PartnerModel>> searchPartners({
    required Gender gender,
    required String learningLanguage,
    required String myUid,
  }) async {
    final results = await Future.wait([_col.doc(myUid).get(), _col.get()]);
    final mySnap = results[0] as DocumentSnapshot<Map<String, dynamic>>;
    final snap = results[1] as QuerySnapshot<Map<String, dynamic>>;
    final myProfile = mySnap.data();
    final myNative = nativeLanguageFromProfile(myProfile);
    final targetLanguage = learningLanguage == 'Any'
        ? learningLanguageFromProfile(myProfile, nativeLanguage: myNative)
        : learningLanguage;
    final seen = <String>{};
    return snap.docs
        .where((d) {
          // Exclude self
          if (d.id == myUid) return false;
          // Exclude incomplete profiles (no displayName saved yet)
          final name = d.data()['displayName'] as String?;
          if (name == null || name.trim().isEmpty) return false;
          // Deduplicate by UID (safety net)
          return seen.add(d.id);
        })
        .map(_fromDoc)
        .where((p) {
          final genderOk = gender == Gender.any || p.gender == gender;
          final langOk =
              p.nativeLanguage == targetLanguage &&
              p.learningLanguage == myNative;
          return genderOk && langOk;
        })
        .toList();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  PartnerModel _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    final native = nativeLanguageFromProfile(d);
    final learning = learningLanguageFromProfile(d, nativeLanguage: native);
    return PartnerModel(
      id: doc.id,
      name: d['displayName'] as String? ?? 'Unknown',
      avatarInitial: d['avatarInitial'] as String? ?? '?',
      nativeLanguage: native,
      learningLanguage: learning,
      school: d['school'] as String? ?? '',
      bio: d['bio'] as String? ?? '',
      gender: _parseGender(d['gender']),
      isOnline: d['isOnline'] as bool? ?? false,
    );
  }

  Gender _parseGender(dynamic g) => switch (g?.toString()) {
    'male' => Gender.male,
    'female' => Gender.female,
    _ => Gender.any,
  };
}
