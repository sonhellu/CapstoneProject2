/// Outcome of [ChatService.sendRequest] — map to UI snackbars / banners.
enum SendChatRequestResult {
  /// Request document was written (new or reconnect).
  sent,

  /// No signed-in user.
  notSignedIn,

  /// Partner has no `users/{id}` profile.
  partnerProfileMissing,

  /// Current user already has a pending outbound request to this person.
  alreadyPending,

  /// The other person already sent a pending request — accept from Chat tab.
  incomingPendingExists,

  /// Pair is already actively connected.
  alreadyAccepted,

  /// Firestore or network failure.
  failed,
}
