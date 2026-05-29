import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/schedule_activity.dart';

class ScheduleRepository {
  ScheduleRepository({FirebaseFirestore? firestore}) : _injectedDb = firestore;

  final FirebaseFirestore? _injectedDb;
  // Lazy: FirebaseFirestore.instance is only accessed when a method is called,
  // not at construction time — safe to instantiate in tests without Firebase.
  FirebaseFirestore get _db => _injectedDb ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _collection(String uid) {
    return _db.collection('users').doc(uid).collection('schedule_activities');
  }

  Stream<List<ScheduleActivity>> watchActivities(String uid) {
    return _collection(uid)
        .orderBy('date')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ScheduleActivity.fromJson(doc.data()))
              .toList(growable: false),
        );
  }

  Future<void> save(String uid, ScheduleActivity activity) {
    return _collection(uid).doc(activity.id).set(activity.toJson());
  }

  Future<void> delete(String uid, String id) {
    return _collection(uid).doc(id).delete();
  }

  Future<void> removeLegacyDemoData(String uid) async {
    const demoIds = ['demo_1', 'demo_2', 'demo_3', 'demo_4'];
    final col = _collection(uid);
    await Future.wait(
      demoIds.map((id) async {
        final doc = await col.doc(id).get();
        if (doc.exists) await col.doc(id).delete();
      }),
    );
  }
}
