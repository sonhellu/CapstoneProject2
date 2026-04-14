import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../errors/chat_accept_errors.dart';
import '../../l10n/app_localizations.dart';

/// Maps Firebase / network errors to short, localized copy (no stack traces).
String userFacingErrorMessage(AppLocalizations l, Object error) {
  if (error is ChatAcceptException) {
    switch (error.failure) {
      case ChatAcceptFailure.requestNotFound:
        return l.errorChatRequestNotFound;
      case ChatAcceptFailure.requestNotPending:
        return l.errorChatRequestNotPending;
      case ChatAcceptFailure.transactionAborted:
        return l.errorTransactionAborted;
      case ChatAcceptFailure.networkError:
        return l.errorNetwork;
    }
  }
  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return l.errorPermissionDenied;
      case 'not-found':
        return l.errorNotFound;
      case 'aborted':
        return l.errorTransactionAborted;
      case 'failed-precondition':
        return l.errorDataConflict;
      case 'unavailable':
      case 'deadline-exceeded':
        return l.errorNetwork;
    }
  }
  final raw = error.toString().toLowerCase();
  if (raw.contains('permission-denied')) return l.errorPermissionDenied;
  if (raw.contains('not-found')) return l.errorNotFound;
  if (raw.contains('network') ||
      raw.contains('unavailable') ||
      raw.contains('failed host lookup') ||
      raw.contains('connection')) {
    return l.errorNetwork;
  }
  return l.errorUnexpected;
}

void showErrorTextSnackBar(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  final cs = Theme.of(context).colorScheme;
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: TextStyle(color: cs.onErrorContainer, fontSize: 14),
      ),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: cs.errorContainer,
      elevation: 2,
    ),
  );
}

void showErrorSnackBar(BuildContext context, Object error) {
  final l = AppLocalizations.of(context);
  final msg = l == null ? error.toString() : userFacingErrorMessage(l, error);
  showErrorTextSnackBar(context, msg);
}

void showSuccessSnackBar(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  final cs = Theme.of(context).colorScheme;
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        message,
        style: TextStyle(color: cs.onPrimaryContainer, fontSize: 14),
      ),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: cs.primaryContainer,
      elevation: 2,
    ),
  );
}
