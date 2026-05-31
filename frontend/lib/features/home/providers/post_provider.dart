import 'package:flutter/foundation.dart';

import '../models/post.dart';
import '../services/post_api_service.dart';

class PostProvider extends ChangeNotifier {
  PostProvider() {
    _bootstrap();
  }

  bool _loading = true;
  String? _error;
  final List<Post> _posts = [];
  final Map<String, List<CommentData>> _commentsMap = {};

  bool get isLoading => _loading;
  String? get error => _error;
  List<Post> get posts => List.unmodifiable(_posts);

  Future<void> refresh() => _bootstrap();

  Post? getById(String id) {
    try {
      return _posts.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  List<CommentData> commentsFor(String postId) =>
      List.unmodifiable(_commentsMap[postId] ?? []);

  Future<void> _bootstrap() async {
    try {
      final fetched = await PostApiService.instance.fetchPosts();
      _posts
        ..clear()
        ..addAll(fetched);
    } catch (e) {
      _error = e.toString();
      // Fallback to mock data when backend is unreachable
      _posts
        ..clear()
        ..addAll(List<Post>.from(mockPosts));
      _seedComments();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void _seedComments() {
    _commentsMap['p1'] = [
      CommentData(
        id: 'c1_1',
        authorName: 'Tanaka Yuki',
        avatarInitial: 'T',
        text: 'Really helpful! Thanks for sharing 🙏',
        time: '1h ago',
      ),
      CommentData(
        id: 'c1_2',
        authorName: 'Ahmed Hassan',
        avatarInitial: 'A',
        text: 'I wish I had this guide when I first came here...',
        time: '3h ago',
      ),
    ];
    _commentsMap['p2'] = [
      CommentData(
        id: 'c2_1',
        authorName: 'Linh Pham',
        avatarInitial: 'L',
        text: 'Thank you so much! This is exactly what I needed.',
        time: '2h ago',
      ),
    ];
  }

  Future<void> loadComments(String postId) async {
    if (_commentsMap.containsKey(postId)) return;
    try {
      final comments = await PostApiService.instance.fetchComments(postId);
      _commentsMap[postId] = comments;
      notifyListeners();
    } catch (_) {
      _commentsMap[postId] = [];
    }
  }

  Future<void> addPost(Post post) async {
    final saved = await PostApiService.instance.createPost(post);
    _posts.insert(0, saved);
    notifyListeners();
  }

  Future<void> updatePost(
    String id, {
    required String title,
    required String content,
  }) async {
    final idx = _posts.indexWhere((p) => p.id == id);
    if (idx == -1) return;

    final previous = _posts[idx];
    _posts[idx] = previous.copyWith(title: title, content: content);
    notifyListeners();

    try {
      await PostApiService.instance.updatePost(
        id,
        title: title,
        content: content,
      );
    } catch (_) {
      _posts[idx] = previous;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deletePost(String id) async {
    _posts.removeWhere((p) => p.id == id);
    notifyListeners();
    try {
      await PostApiService.instance.deletePost(id);
    } catch (_) {
      await refresh();
      rethrow;
    }
  }

  Future<void> addComment(
    String postId,
    CommentData comment, {
    String authorName = 'You',
    String avatarInitial = 'Y',
  }) async {
    final current = List<CommentData>.from(_commentsMap[postId] ?? []);
    current.insert(0, comment);
    _commentsMap[postId] = current;

    final idx = _posts.indexWhere((p) => p.id == postId);
    if (idx != -1) {
      _posts[idx] = _posts[idx].copyWith(comments: current.length);
    }
    notifyListeners();

    try {
      final saved = await PostApiService.instance.addComment(
        postId,
        comment.text,
        authorName: authorName,
        avatarInitial: avatarInitial,
      );
      final synced = List<CommentData>.from(_commentsMap[postId] ?? []);
      final pendingIdx = synced.indexWhere((c) => c.id == comment.id);
      if (pendingIdx != -1) {
        synced[pendingIdx] = saved;
        _commentsMap[postId] = synced;
        notifyListeners();
      }
    } catch (_) {
      current.removeWhere((c) => c.id == comment.id);
      _commentsMap[postId] = current;
      if (idx != -1) {
        _posts[idx] = _posts[idx].copyWith(comments: current.length);
      }
      notifyListeners();
      rethrow;
    }
  }
}
