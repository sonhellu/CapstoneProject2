import 'dart:convert';

import '../../../core/services/api_client.dart';
import '../models/post.dart';

class PostApiService {
  PostApiService._();
  static final instance = PostApiService._();

  final _api = ApiClient();

  Future<List<Post>> fetchPosts({
    String? category,
    int? lastId,
    int size = 20,
  }) async {
    final params = <String, String>{'size': size.toString()};
    if (category != null && category != 'All') params['category'] = category;
    if (lastId != null) params['last_id'] = lastId.toString();

    final res = await _api.get('/api/posts/', queryParams: params);
    if (res.statusCode != 200) return [];

    final List data = jsonDecode(utf8.decode(res.bodyBytes));
    return data
        .map((item) => Post.fromJson(item['post'] as Map<String, dynamic>))
        .toList();
  }

  Future<Post> createPost(Post post) async {
    final res = await _api.post('/api/posts/', body: post.toJson());
    if (res.statusCode != 201) {
      throw Exception(_message(res, 'Failed to create post'));
    }
    return Post.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
  }

  Future<void> updatePost(
    String id, {
    required String title,
    required String content,
  }) async {
    final res = await _api.patch(
      '/api/posts/$id',
      body: {'title': title, 'content': content},
    );
    if (res.statusCode != 200) {
      throw Exception(_message(res, 'Failed to update post'));
    }
  }

  Future<void> deletePost(String id) async {
    final res = await _api.delete('/api/posts/$id');
    if (res.statusCode != 204) {
      throw Exception(_message(res, 'Failed to delete post'));
    }
  }

  Future<List<CommentData>> fetchComments(String postId) async {
    final res = await _api.get('/api/posts/$postId/comments');
    if (res.statusCode != 200) return [];
    final List data = jsonDecode(utf8.decode(res.bodyBytes));
    return data
        .map((item) => CommentData.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<CommentData> addComment(
    String postId,
    String content, {
    required String authorName,
    required String avatarInitial,
  }) async {
    final res = await _api.post(
      '/api/posts/$postId/comments',
      body: {
        'content': content,
        'is_anonymous': false,
        'author_name': authorName,
        'author_avatar_initial': avatarInitial,
      },
    );
    if (res.statusCode != 201) {
      throw Exception(_message(res, 'Failed to add comment'));
    }
    return CommentData.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
  }

  Future<Post> likePost(String id) async {
    final res = await _api.post('/api/posts/$id/like');
    if (res.statusCode != 200) {
      throw Exception(_message(res, 'Failed to like post'));
    }
    return Post.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
  }

  String _message(dynamic res, String fallback) {
    try {
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      final detail = body['detail'];
      if (detail is String && detail.isNotEmpty) return '$fallback: $detail';
    } catch (_) {}
    return '$fallback (${res.statusCode})';
  }
}
