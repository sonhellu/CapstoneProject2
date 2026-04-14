import '../models/post.dart';

/// Simulates a remote API for post CRUD.
///
/// Each method introduces a [_kDelay] delay to mimic network latency.
/// Replace the body of each method with a real `http` call when the
/// backend is ready — the rest of the app does not need to change.
class MockPostService {
  MockPostService._();
  static final instance = MockPostService._();

  static const _kDelay = Duration(milliseconds: 500);

  /// Adds a new post to the "server" and returns it with a generated id.
  Future<Post> createPost(Post post) async {
    await Future<void>.delayed(_kDelay);
    return post; // server would return the saved object with a real id
  }

  /// Overwrites the [title] and/or [content] of an existing post.
  Future<Post> updatePost(
    String id, {
    required String title,
    required String content,
  }) async {
    await Future<void>.delayed(_kDelay);
    // In production: PATCH /api/posts/{id}  { title, content }
    throw UnimplementedError(
      'Server response not available in mock mode — '
      'PostProvider handles the list update locally.',
    );
  }

  /// Removes the post with [id] from the "server".
  Future<void> deletePost(String id) async {
    await Future<void>.delayed(_kDelay);
    // In production: DELETE /api/posts/{id}
  }
}
