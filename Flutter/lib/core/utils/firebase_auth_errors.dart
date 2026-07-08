import 'package:firebase_auth/firebase_auth.dart';

String mapFirebaseAuthError(FirebaseAuthException e) {
  switch (e.code) {
    case 'user-not-found':
    case 'wrong-password':
      return 'Invalid email or password.';
    case 'invalid-credential':
      return 'Sign-in failed. Check that Google (or Facebook) is enabled in Firebase Console → Authentication → Sign-in method.';
    case 'requires-recent-login':
      return 'Please sign out and sign in again before changing your password.';
    case 'email-already-in-use':
      return 'An account with this email already exists.';
    case 'weak-password':
      return 'Password must be at least 8 characters.';
    case 'invalid-email':
      return 'Please enter a valid email address.';
    case 'too-many-requests':
      return 'Too many attempts. Try again later.';
    case 'account-exists-with-different-credential':
      return 'An account already exists with this email using a different sign-in method.';
    default:
      return e.message ?? 'Authentication failed.';
  }
}
