import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Seeds Firestore `users` collection with 5 fake profiles for development.
/// Safe to call multiple times — uses `set` with merge so it won't duplicate.
class DevSeeder {
  DevSeeder._();

  static final _db = FirebaseFirestore.instance;

  static const _users = [
    {
      'uid': 'seed_user_001',
      'displayName': 'Kim Minji',
      'avatarInitial': 'K',
      'email': 'minji.kim@kmu.ac.kr',
      'nativeLanguage': 'Korean',
      'learningLanguage': 'Vietnamese',
      'gender': 'female',
      'school': 'Keimyung University',
      'bio': '안녕하세요! 베트남어 공부 중이에요. 같이 언어 교환해요 😊',
      'isOnline': true,
    },
    {
      'uid': 'seed_user_002',
      'displayName': 'Park Junho',
      'avatarInitial': 'P',
      'email': 'junho.park@kmu.ac.kr',
      'nativeLanguage': 'Korean',
      'learningLanguage': 'Vietnamese',
      'gender': 'male',
      'school': 'Keimyung University',
      'bio': '베트남 문화에 관심이 많아요. 같이 공부해요!',
      'isOnline': false,
    },
    {
      'uid': 'seed_user_003',
      'displayName': 'Nguyen Thi Lan',
      'avatarInitial': 'N',
      'email': 'lan.nguyen@hust.edu.vn',
      'nativeLanguage': 'Vietnamese',
      'learningLanguage': 'Korean',
      'gender': 'female',
      'school': 'Hanoi University of Science and Technology',
      'bio': 'Đang học tiếng Hàn, tìm bạn trao đổi ngôn ngữ!',
      'isOnline': true,
    },
    {
      'uid': 'seed_user_004',
      'displayName': 'Tran Van Duc',
      'avatarInitial': 'T',
      'email': 'duc.tran@vnu.edu.vn',
      'nativeLanguage': 'Vietnamese',
      'learningLanguage': 'Korean',
      'gender': 'male',
      'school': 'Vietnam National University',
      'bio': 'K-pop fan, muốn học tiếng Hàn thực tế từ người bản địa.',
      'isOnline': true,
    },
    {
      'uid': 'seed_user_005',
      'displayName': 'Lee Soyeon',
      'avatarInitial': 'L',
      'email': 'soyeon.lee@dgu.ac.kr',
      'nativeLanguage': 'Korean',
      'learningLanguage': 'Vietnamese',
      'gender': 'female',
      'school': 'Dongguk University',
      'bio': '베트남 여행 준비 중! 베트남어 배우고 싶어요 ✈️',
      'isOnline': false,
    },
  ];

  /// Writes all seed users to Firestore. Only runs in debug mode.
  static Future<void> seedUsers() async {
    if (!kDebugMode) return;

    final batch = _db.batch();
    for (final user in _users) {
      final ref = _db.collection('users').doc(user['uid'] as String);
      batch.set(ref, {
        ...user,
        'createdAt': FieldValue.serverTimestamp(),
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    await batch.commit();
    debugPrint('[DevSeeder] Seeded ${_users.length} users to Firestore.');
  }
}
