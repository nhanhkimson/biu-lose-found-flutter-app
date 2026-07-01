import 'package:firebase_core/firebase_core.dart';

String mapFirestoreError(FirebaseException e) {
  switch (e.code) {
    case 'unavailable':
    case 'failed-precondition':
      return 'Cloud profile is unavailable. Create a Firestore database in Firebase Console, then try again.';
    case 'permission-denied':
      return 'Profile access denied. Check Firestore security rules for the users collection.';
    default:
      return e.message ?? 'Cloud profile error (${e.code}).';
  }
}

bool isTransientFirestoreError(FirebaseException e) {
  return e.code == 'unavailable' || e.code == 'failed-precondition';
}
