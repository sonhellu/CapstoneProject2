import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/post.dart';

class PostFirestoreService {
  PostFirestoreService._();
  static final instance = PostFirestoreService._();

  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _posts =>
      _db.collection('posts');

  CollectionReference<Map<String, dynamic>> _comments(String postId) =>
      _posts.doc(postId).collection('comments');

  // ── Read ─────────────────────────────────────────────────────────────────

  Stream<List<Post>> watchPosts({String? category}) {
    Query<Map<String, dynamic>> q =
        _posts.orderBy('createdAt', descending: true).limit(50);
    if (category != null && category != 'All') {
      q = q.where('category', isEqualTo: category);
    }
    return q.snapshots().map(
          (snap) => snap.docs.map(Post.fromFirestore).toList(),
        );
  }

  Stream<List<CommentData>> watchComments(String postId) {
    return _comments(postId)
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs.map(_commentFromDoc).toList());
  }

  // ── Write ────────────────────────────────────────────────────────────────

  Future<Post> createPost(Post post) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw StateError('Not signed in');
    final doc = _posts.doc();
    await doc.set(post.toFirestore());
    return post.copyWith(id: doc.id);
  }

  Future<void> updatePost(
    String id, {
    required String title,
    required String content,
  }) async {
    await _posts.doc(id).update({
      'title': title,
      'content': content,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deletePost(String id) async {
    await _posts.doc(id).delete();
  }

  Future<void> toggleLike(String postId, String uid) async {
    final ref = _posts.doc(postId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final likedBy =
          List<String>.from(snap.data()?['likedBy'] as List? ?? []);
      likedBy.contains(uid) ? likedBy.remove(uid) : likedBy.add(uid);
      tx.update(ref, {
        'likedBy': likedBy,
        'likeCount': likedBy.length,
      });
    });
  }

  Future<void> addComment(
    String postId, {
    required String content,
    required String authorName,
    required String avatarInitial,
    required String uid,
  }) async {
    final commentRef = _comments(postId).doc();
    final postRef = _posts.doc(postId);
    await _db.runTransaction((tx) async {
      tx.set(commentRef, {
        'content': content,
        'authorName': authorName,
        'avatarInitial': avatarInitial,
        'userId': uid,
        'isAnonymous': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      tx.update(postRef, {
        'commentCount': FieldValue.increment(1),
      });
    });
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  CommentData _commentFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final isAnon = data['isAnonymous'] as bool? ?? false;
    final ts = data['createdAt'] as Timestamp?;
    final dt = ts?.toDate() ?? DateTime.now();
    return CommentData(
      id: doc.id,
      authorName:
          isAnon ? 'Anonymous' : (data['authorName'] as String? ?? 'Unknown'),
      avatarInitial: isAnon ? 'A' : (data['avatarInitial'] as String? ?? '?'),
      text: data['content'] as String? ?? '',
      time: _timeAgo(dt),
    );
  }

  static String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }
}
