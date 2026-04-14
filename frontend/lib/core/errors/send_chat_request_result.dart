/// Outcome of [ChatService.sendRequest] — map to UI snackbars / banners.
enum SendChatRequestResult {
  /// Request document was written (merge create / safe update).
  sent,

  /// No signed-in user.
  notSignedIn,

  /// Partner has no `users/{id}` profile.
  partnerProfileMissing,

  /// Current user already has a pending outbound request to this person.
  alreadyPending,

  /// The other person already sent a pending request — accept from Chat tab.
  incomingPendingExists,

  /// Pair already went through acceptance (or request already accepted).
  alreadyAccepted,

  /// Prior request was declined; rules do not allow resetting to pending.
  previouslyDeclined,

  /// Firestore or network failure.
  failed,
}
