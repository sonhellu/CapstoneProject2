import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/schedule_activity.dart';

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Persistent schedule store backed by Firestore.
/// Syncs in real-time across all devices for the signed-in user.
///
/// Collection path: users/{uid}/schedule_activities/{activityId}
class ScheduleProvider extends ChangeNotifier {
  ScheduleProvider() {
    _authSub = FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
  }

  final _db   = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  final List<ScheduleActivity> _items = [];
  StreamSubscription<QuerySnapshot>? _firestoreSub;
  StreamSubscription<User?>?         _authSub;

  // ── Public reads ──────────────────────────────────────────────────────────

  List<ScheduleActivity> get all => List.unmodifiable(_items);

  bool get isLoading => _items.isEmpty && _auth.currentUser != null;

  /// All activities for [day], sorted by start time.
  List<ScheduleActivity> activitiesFor(DateTime day) {
    final d    = _dateOnly(day);
    final list = _items.where((e) => _sameDay(e.date, d)).toList();
    list.sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
    return list;
  }

  /// Up to [limit] upcoming activities for [day].
  /// When [day] is today, filters out activities that have already ended.
  List<ScheduleActivity> upcomingForDay(DateTime day, {int limit = 3}) {
    var list = activitiesFor(day);
    if (_sameDay(day, DateTime.now())) {
      final nowMins = TimeOfDay.now().hour * 60 + TimeOfDay.now().minute;
      list = list.where((e) => e.endMinutes > nowMins).toList();
    }
    return list.length <= limit ? list : list.take(limit).toList();
  }

  // ── Mutations ─────────────────────────────────────────────────────────────

  Future<void> add(ScheduleActivity a) async {
    final col = _collection();
    if (col == null) return;
    await col.doc(a.id).set(a.toJson());
  }

  Future<void> update(ScheduleActivity a) async {
    final col = _collection();
    if (col == null) return;
    await col.doc(a.id).set(a.toJson());
  }

  Future<void> remove(String id) async {
    final col = _collection();
    if (col == null) return;
    await col.doc(id).delete();
  }

  // ── Firestore helpers ─────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>>? _collection() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection('schedule_activities');
  }

  void _onAuthChanged(User? user) {
    _firestoreSub?.cancel();
    _firestoreSub = null;
    _items.clear();
    notifyListeners();

    if (user == null) return;

    _removeLegacyDemoData();

    _firestoreSub = _collection()!
        .orderBy('date')
        .snapshots()
        .listen(_onSnapshot, onError: _onError);
  }

  /// Deletes demo documents that may have been written by a previous version.
  Future<void> _removeLegacyDemoData() async {
    final col = _collection();
    if (col == null) return;
    const demoIds = ['demo_1', 'demo_2', 'demo_3', 'demo_4'];
    for (final id in demoIds) {
      final doc = await col.doc(id).get();
      if (doc.exists) await col.doc(id).delete();
    }
  }

  void _onSnapshot(QuerySnapshot snapshot) {
    _items
      ..clear()
      ..addAll(
        snapshot.docs.map(
          (doc) => ScheduleActivity.fromJson(doc.data() as Map<String, dynamic>),
        ),
      );
    notifyListeners();
  }

  void _onError(Object e) {
    if (kDebugMode) debugPrint('[ScheduleProvider] Firestore error: $e');
  }

  // ── Dispose ───────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _firestoreSub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }
}
