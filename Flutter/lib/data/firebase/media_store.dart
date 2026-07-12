import 'dart:convert';
import 'dart:typed_data';

import 'package:beltei_app/core/network/api_exception.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Stores small images in Firestore when Firebase Storage is unavailable.
class MediaStore {
  MediaStore({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  static const collection = 'media';
  static const urlPrefix = 'firestore-media://';
  static const maxStoredBytes = 450 * 1024;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(collection);

  static bool isFirestoreMediaUrl(String url) => url.startsWith(urlPrefix);

  static String? mediaIdFromUrl(String url) {
    if (!isFirestoreMediaUrl(url)) return null;
    return url.substring(urlPrefix.length);
  }

  final Map<String, Uint8List> _cache = {};

  Future<String> uploadBytes(
    Uint8List bytes, {
    required String folder,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw ApiException('Sign in to upload images.');
    }
    if (bytes.isEmpty) {
      throw ApiException('Image file is empty.');
    }
    if (bytes.length > maxStoredBytes) {
      throw ApiException(
        'Image is too large. Try a smaller photo or crop the image.',
      );
    }

    final doc = _col.doc();
    await doc.set({
      'userId': user.uid,
      'folder': folder,
      'mimeType': 'image/jpeg',
      'bytes': base64Encode(bytes),
      'size': bytes.length,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return '$urlPrefix${doc.id}';
  }

  Future<Uint8List?> readBytes(String mediaId) async {
    final cached = _cache[mediaId];
    if (cached != null) return cached;

    final doc = await _col.doc(mediaId).get();
    if (!doc.exists) return null;
    final encoded = doc.data()?['bytes'] as String?;
    if (encoded == null || encoded.isEmpty) return null;
    final bytes = base64Decode(encoded);
    _cache[mediaId] = bytes;
    return bytes;
  }
}
