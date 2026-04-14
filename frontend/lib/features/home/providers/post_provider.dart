import 'package:flutter/foundation.dart';

import '../models/post.dart';
import '../services/mock_post_service.dart';

/// Single source of truth for the community post feed.
///
/// [isLoading] is true briefly on cold start so list UIs can show shimmer.
/// Backed by [MockPostService] today; swap for remote API when ready.
class PostProvider extends ChangeNotifier {
  PostProvider() {
    _bootstrap();
  }

  bool _loading = true;
  final List<Post> _posts = [];

  bool get isLoading => _loading;

  List<Post> get posts => List.unmodifiable(_posts);

  Post? getById(String id) {
    try {
      return _posts.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> _bootstrap() async {
    await Future<void>.delayed(const Duration(milliseconds: 420));
    _posts
      ..clear()
      ..addAll(List<Post>.from(mockPosts));
    _loading = false;
    notifyListeners();
  }

  Future<void> addPost(Post post) async {
    final saved = await MockPostService.instance.createPost(post);
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
      await MockPostService.instance.deletePost('__noop__');
    } catch (_) {
      _posts[idx] = previous;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deletePost(String id) async {
    await MockPostService.instance.deletePost(id);
    _posts.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  void toggleLike(String id) {
    final idx = _posts.indexWhere((p) => p.id == id);
    if (idx == -1) return;
    final p = _posts[idx];
    _posts[idx] = p.copyWith(likes: p.likes + 1);
    notifyListeners();
  }
}
