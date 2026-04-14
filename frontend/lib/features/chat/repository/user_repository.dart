import 'package:cloud_firestore/cloud_firestore.dart';

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
  }) async {
    final ref = _col.doc(uid);
    final snap = await ref.get();
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';

    if (!snap.exists) {
      await ref.set({
        'uid': uid,
        'displayName': displayName,
        'avatarInitial': initial,
        'email': email,
        'nativeLanguage': 'Vietnamese',
        'learningLanguage': 'Korean',
        'gender': 'other',
        'school': 'Keimyung University',
        'bio': 'Hi, I\'m using HiCampus!',
        'isOnline': true,
        'createdAt': FieldValue.serverTimestamp(),
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } else {
      // Update only online status; leave other profile fields untouched
      await ref.update({
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
      });
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
    String? bio,
  }) async {
    final data = <String, dynamic>{};
    if (displayName != null) {
      data['displayName'] = displayName;
      data['avatarInitial'] =
          displayName.isNotEmpty ? displayName[0].toUpperCase() : '?';
    }
    if (nativeLanguage != null) data['nativeLanguage'] = nativeLanguage;
    if (learningLanguage != null) data['learningLanguage'] = learningLanguage;
    if (gender != null) data['gender'] = gender;
    if (school != null) data['school'] = school;
    if (bio != null) data['bio'] = bio;
    if (data.isNotEmpty) await _col.doc(uid).update(data);
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
    final snap = await _col.get();
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
              learningLanguage == 'Any' || p.nativeLanguage == learningLanguage;
          return genderOk && langOk;
        })
        .toList();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  PartnerModel _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return PartnerModel(
      id: doc.id,
      name: d['displayName'] as String? ?? 'Unknown',
      avatarInitial: d['avatarInitial'] as String? ?? '?',
      nativeLanguage: d['nativeLanguage'] as String? ?? 'Korean',
      learningLanguage: d['learningLanguage'] as String? ?? 'Vietnamese',
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
