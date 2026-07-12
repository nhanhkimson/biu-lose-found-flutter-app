import 'package:firebase_core/firebase_core.dart';

String mapFirestoreError(FirebaseException e) {
  final message = e.message ?? '';
  switch (e.code) {
    case 'unavailable':
      return 'Cloud database is unavailable. Check your connection and try again.';
    case 'failed-precondition':
      if (message.contains('index')) {
        return 'Filters are still syncing. Pull down or tap Retry in a moment.';
      }
      return 'Cloud database is unavailable. Please try again.';
    case 'permission-denied':
      return 'Cloud database access denied. Check Firestore security rules.';
    default:
      return e.message ?? 'Cloud database error (${e.code}).';
  }
}

bool isTransientFirestoreError(FirebaseException e) {
  return e.code == 'unavailable' || e.code == 'failed-precondition';
}

/// Errors that should not block Firebase Auth sign-in.
bool isNonBlockingFirestoreError(FirebaseException e) {
  return isTransientFirestoreError(e) || e.code == 'permission-denied';
}
