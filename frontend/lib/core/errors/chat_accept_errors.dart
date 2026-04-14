/// Business-rule failures when accepting a chat request.
enum ChatAcceptFailure {
  /// No `chat_requests/{id}` document found.
  requestNotFound,

  /// Document exists but `status` is neither `pending` nor `accepted`.
  requestNotPending,

  /// Firestore transaction was aborted due to contention (should be retried).
  transactionAborted,

  /// Network error or other transient failure.
  networkError,
}

class ChatAcceptException implements Exception {
  const ChatAcceptException(this.failure);
  final ChatAcceptFailure failure;

  /// Human-readable message shown in the UI via [showErrorSnackBar].
  String get message => switch (failure) {
        ChatAcceptFailure.requestNotFound =>
          'Request no longer exists. It may have been cancelled.',
        ChatAcceptFailure.requestNotPending =>
          'This request has already been handled.',
        ChatAcceptFailure.transactionAborted =>
          'Connection busy — please try again.',
        ChatAcceptFailure.networkError =>
          'Network error. Check your connection and retry.',
      };

  @override
  String toString() => 'ChatAcceptException(${failure.name}): $message';
}
