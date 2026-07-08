import 'package:beltei_app/core/utils/firebase_firestore_errors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore `users/{uid}` extended profile (studentId, phone, role).
class UserProfileStore {
  UserProfileStore({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const collection = 'users';

  Future<Map<String, dynamic>?> get(String uid) async {
    try {
      final doc = await _firestore.collection(collection).doc(uid).get(
            const GetOptions(source: Source.serverAndCache),
          );
      return doc.data();
    } on FirebaseException catch (e) {
      if (isNonBlockingFirestoreError(e)) return null;
      rethrow;
    }
  }

  /// Returns `true` when the write reached Firestore.
  Future<bool> merge(String uid, Map<String, dynamic> data) async {
    if (data.isEmpty) return true;
    try {
      await _firestore.collection(collection).doc(uid).set(
            {
              ...data,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
      return true;
    } on FirebaseException catch (e) {
      if (isNonBlockingFirestoreError(e)) return false;
      rethrow;
    }
  }
}
