import 'dart:async';

/// Returns true for transient errors that are worth retrying
/// (network unavailable, Firestore unavailable).
bool _isRetryable(Object e) {
  final s = e.toString().toLowerCase();
  return s.contains('network') ||
      s.contains('unavailable') ||
      s.contains('failed host lookup') ||
      s.contains('connection') ||
      s.contains('timeout');
}

/// Retries [fn] up to [maxAttempts] times with exponential back-off.
///
/// Only retries on transient network errors; all other errors propagate
/// immediately. Back-off: 1 s → 2 s → 4 s …
///
/// ```dart
/// await withRetry(() => ChatService.instance.sendRequest(...));
/// ```
Future<T> withRetry<T>(
  Future<T> Function() fn, {
  int maxAttempts = 3,
}) async {
  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    try {
      return await fn();
    } catch (e) {
      final isLast = attempt == maxAttempts - 1;
      if (isLast || !_isRetryable(e)) rethrow;
      await Future.delayed(Duration(seconds: 1 << attempt)); // 1s, 2s, 4s
    }
  }
  throw StateError('withRetry: unreachable');
}
