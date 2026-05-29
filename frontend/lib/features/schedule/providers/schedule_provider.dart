import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../auth/services/auth_service.dart';
import '../models/schedule_activity.dart';
import '../repository/schedule_repository.dart';

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Persistent schedule store backed by Firestore.
/// Syncs in real-time across all devices for the signed-in user.
///
/// Collection path: users/{uid}/schedule_activities/{activityId}
class ScheduleProvider extends ChangeNotifier {
  ScheduleProvider({
    AuthService? authService,
    ScheduleRepository? scheduleRepository,
  }) : _authService = authService ?? AuthService(),
       _repository = scheduleRepository ?? ScheduleRepository() {
    _authSub = _authService.authStateChanges.listen(_onAuthChanged);
  }

  final AuthService _authService;
  final ScheduleRepository _repository;

  final List<ScheduleActivity> _items = [];
  StreamSubscription<List<ScheduleActivity>>? _scheduleSub;
  StreamSubscription<User?>? _authSub;

  // ── Public reads ──────────────────────────────────────────────────────────

  List<ScheduleActivity> get all => List.unmodifiable(_items);

  bool get isLoading => _items.isEmpty && _authService.currentUser != null;

  /// All activities for [day], sorted by start time.
  List<ScheduleActivity> activitiesFor(DateTime day) {
    final d = _dateOnly(day);
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

  /// Home preview keeps today's schedule visible even after an activity ended.
  /// Upcoming items are shown first, then the most recently finished items.
  List<ScheduleActivity> homePreviewForDay(DateTime day, {int limit = 3}) {
    final list = activitiesFor(day);
    if (!_sameDay(day, DateTime.now()) || list.length <= limit) {
      return list.length <= limit ? list : list.take(limit).toList();
    }

    final nowMins = TimeOfDay.now().hour * 60 + TimeOfDay.now().minute;
    final upcoming = list.where((e) => e.endMinutes > nowMins);
    final finished = list
        .where((e) => e.endMinutes <= nowMins)
        .toList()
        .reversed;
    return [...upcoming, ...finished].take(limit).toList(growable: false);
  }

  // ── Mutations ─────────────────────────────────────────────────────────────

  Future<void> add(ScheduleActivity a) async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) return;
    final previous = List<ScheduleActivity>.of(_items);
    _upsertLocal(a);
    try {
      await _repository.save(uid, a);
    } catch (_) {
      _replaceLocal(previous);
      rethrow;
    }
  }

  Future<void> update(ScheduleActivity a) async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) return;
    final previous = List<ScheduleActivity>.of(_items);
    _upsertLocal(a);
    try {
      await _repository.save(uid, a);
    } catch (_) {
      _replaceLocal(previous);
      rethrow;
    }
  }

  Future<void> remove(String id) async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) return;
    final previous = List<ScheduleActivity>.of(_items);
    _items.removeWhere((e) => e.id == id);
    notifyListeners();
    try {
      await _repository.delete(uid, id);
    } catch (_) {
      _replaceLocal(previous);
      rethrow;
    }
  }

  void _onAuthChanged(User? user) {
    _scheduleSub?.cancel();
    _scheduleSub = null;
    _items.clear();
    notifyListeners();

    if (user == null) return;

    unawaited(_repository.removeLegacyDemoData(user.uid));

    _scheduleSub = _repository
        .watchActivities(user.uid)
        .listen(_onSnapshot, onError: _onError);
  }

  void _onSnapshot(List<ScheduleActivity> activities) {
    _items
      ..clear()
      ..addAll(activities);
    notifyListeners();
  }

  void _upsertLocal(ScheduleActivity activity) {
    final index = _items.indexWhere((e) => e.id == activity.id);
    if (index == -1) {
      _items.add(activity);
    } else {
      _items[index] = activity;
    }
    notifyListeners();
  }

  void _replaceLocal(List<ScheduleActivity> activities) {
    _items
      ..clear()
      ..addAll(activities);
    notifyListeners();
  }

  void _onError(Object e) {
    if (kDebugMode) debugPrint('[ScheduleProvider] Firestore error: $e');
  }

  // ── Dispose ───────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _scheduleSub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }
}
