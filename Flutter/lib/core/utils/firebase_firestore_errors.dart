import 'package:firebase_core/firebase_core.dart';

String mapFirestoreError(FirebaseException e) {
  switch (e.code) {
    case 'unavailable':
    case 'failed-precondition':
      return 'Cloud database is unavailable. Create a Firestore database in Firebase Console, then try again.';
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
