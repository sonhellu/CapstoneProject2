import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/location_review.dart';
import '../models/user_pin_model.dart';

class PinRepository {
  PinRepository({FirebaseFirestore? firestore, FirebaseAuth? firebaseAuth})
    : _injectedDb = firestore,
      _injectedAuth = firebaseAuth;

  static final PinRepository instance = PinRepository();

  final FirebaseFirestore? _injectedDb;
  final FirebaseAuth? _injectedAuth;

  FirebaseFirestore get _db => _injectedDb ?? FirebaseFirestore.instance;
  FirebaseAuth get _auth => _injectedAuth ?? FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _pins => _db.collection('pins');

  CollectionReference<Map<String, dynamic>> _reviews(String pinId) =>
      _pins.doc(pinId).collection('reviews');

  Stream<List<UserPinModel>> watchVisiblePins() {
    return _auth.authStateChanges().asyncExpand((user) {
      if (user == null) return Stream<List<UserPinModel>>.value(const []);

      final publicStream = _pins
          .where('isPublic', isEqualTo: true)
          .snapshots()
          .map((snap) => snap.docs.map(_pinFromDoc).toList(growable: false));
      final ownStream = _pins
          .where('authorId', isEqualTo: user.uid)
          .snapshots()
          .map((snap) => snap.docs.map(_pinFromDoc).toList(growable: false));

      return _mergePinStreams(publicStream, ownStream);
    });
  }

  Future<List<UserPinModel>> visiblePinsOnce() => watchVisiblePins().first;

  Future<UserPinModel> savePin(UserPinModel pin) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Login is required to save a pin.');

    final doc = pin.id.isEmpty ? _pins.doc() : _pins.doc(pin.id);
    final saved = pin.copyWith(
      id: doc.id,
      authorId: pin.authorId.isNotEmpty ? pin.authorId : user.uid,
      authorName: pin.authorName.isNotEmpty
          ? pin.authorName
          : (user.displayName ?? user.email?.split('@').first ?? 'Student'),
      createdAt: pin.createdAt,
    );

    await doc.set({
      ...saved.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return saved;
  }

  Future<void> deletePin(String pinId) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Login is required to delete a pin.');

    final doc = await _pins.doc(pinId).get();
    if (!doc.exists) return;
    if (doc.data()?['authorId'] != user.uid) {
      throw StateError('Only the owner can delete this pin.');
    }

    await _pins.doc(pinId).delete();
  }

  Stream<List<LocationReview>> watchReviews(String pinId) {
    return _reviews(pinId).snapshots().map((snap) {
      final list = snap.docs.map(_reviewFromDoc).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> addReview({
    required String pinId,
    required int rating,
    required String body,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('Login is required to add a review.');

    final doc = _reviews(pinId).doc();
    final authorName =
        user.displayName ?? user.email?.split('@').first ?? 'You';
    final review = LocationReview(
      id: doc.id,
      pinId: pinId,
      authorId: user.uid,
      authorName: authorName,
      authorInitial: authorName.isEmpty ? 'Y' : authorName[0].toUpperCase(),
      rating: rating.clamp(1, 5).toInt(),
      body: body,
      createdAt: DateTime.now(),
    );

    await _db.runTransaction((tx) async {
      final pinRef = _pins.doc(pinId);
      final pinSnap = await tx.get(pinRef);
      if (!pinSnap.exists) throw StateError('Pin no longer exists.');

      final pinData = pinSnap.data() ?? const <String, dynamic>{};
      final oldCount = (pinData['reviewCount'] as num?)?.toInt() ?? 0;
      final oldRating = (pinData['rating'] as num?)?.toDouble() ?? 0;
      final newCount = oldCount + 1;
      final newAverage = ((oldRating * oldCount) + review.rating) / newCount;

      tx.set(doc, {
        ...review.toJson(),
        'createdAtServer': FieldValue.serverTimestamp(),
      });

      tx.update(pinRef, {
        'rating': newAverage.round().clamp(1, 5).toInt(),
        'reviewCount': newCount,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  UserPinModel _pinFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    return UserPinModel.fromJson({
      ...doc.data(),
      'id': doc.data()['id'] as String? ?? doc.id,
    });
  }

  LocationReview _reviewFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return LocationReview.fromJson({
      ...doc.data(),
      'id': doc.data()['id'] as String? ?? doc.id,
    });
  }

  Stream<List<UserPinModel>> _mergePinStreams(
    Stream<List<UserPinModel>> first,
    Stream<List<UserPinModel>> second,
  ) {
    late StreamController<List<UserPinModel>> controller;
    StreamSubscription<List<UserPinModel>>? firstSub;
    StreamSubscription<List<UserPinModel>>? secondSub;
    var firstItems = const <UserPinModel>[];
    var secondItems = const <UserPinModel>[];
    var firstReady = false;
    var secondReady = false;

    void emit() {
      if (!firstReady || !secondReady) return;
      final byId = <String, UserPinModel>{};
      for (final pin in [...firstItems, ...secondItems]) {
        byId[pin.id] = pin;
      }
      final list = byId.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      controller.add(list);
    }

    controller = StreamController<List<UserPinModel>>(
      onListen: () {
        firstSub = first.listen((items) {
          firstItems = items;
          firstReady = true;
          emit();
        }, onError: controller.addError);
        secondSub = second.listen((items) {
          secondItems = items;
          secondReady = true;
          emit();
        }, onError: controller.addError);
      },
      onCancel: () async {
        await firstSub?.cancel();
        await secondSub?.cancel();
      },
    );

    return controller.stream;
  }
}
