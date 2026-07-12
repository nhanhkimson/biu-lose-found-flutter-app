import 'package:beltei_app/core/media/image_upload_helper.dart';
import 'package:beltei_app/core/network/api_client.dart';
import 'package:beltei_app/core/network/api_exception.dart';
import 'package:beltei_app/data/firebase/media_store.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

/// Uploads images to Firebase Storage, with Firestore fallback when Storage is unavailable.
class StorageUploadStore {
  StorageUploadStore({
    FirebaseStorage? storage,
    FirebaseAuth? auth,
    MediaStore? mediaStore,
    ApiClient? apiClient,
  })  : _storage = storage ?? FirebaseStorage.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _mediaStore = mediaStore ?? MediaStore(),
        _apiClient = apiClient;

  final FirebaseStorage _storage;
  final FirebaseAuth _auth;
  final MediaStore _mediaStore;
  final ApiClient? _apiClient;

  bool _isStorageUnavailable(Object error) {
    if (error is FirebaseException) {
      return error.code == 'object-not-found' ||
          error.code == 'unauthorized' ||
          error.code == 'permission-denied' ||
          error.code == 'unauthenticated' ||
          error.code == 'storage/unknown' ||
          error.code == 'unknown' ||
          error.code == 'bucket-not-found';
    }
    final message = error.toString().toLowerCase();
    return message.contains('storage') ||
        message.contains('bucket') ||
        message.contains('not found') ||
        message.contains('permission');
  }

  Future<void> _ensureSignedIn() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw ApiException('Sign in to upload images.');
    }
    await user.getIdToken(true);
  }

  Future<String> uploadImageFile(XFile file, {String folder = 'items'}) async {
    await _ensureSignedIn();

    try {
      return await _uploadToFirebase(file, folder: folder);
    } catch (storageError) {
      if (!_isStorageUnavailable(storageError)) rethrow;

      try {
        return await _uploadToFirestore(file, folder: folder);
      } catch (_) {
        if (_apiClient != null) {
          try {
            return await _apiClient.uploadImageFile(file);
          } catch (_) {}
        }
        throw ApiException(
          'Could not upload image. Try a smaller photo, or enable Firebase Storage in Firebase Console.',
        );
      }
    }
  }

  Future<String> uploadAvatarFile(XFile file, String userId) async {
    await _ensureSignedIn();

    try {
      return await _uploadToFirebase(file, folder: 'avatars', fixedName: '$userId.jpg');
    } catch (storageError) {
      if (!_isStorageUnavailable(storageError)) rethrow;

      try {
        return await _uploadToFirestore(file, folder: 'avatars');
      } catch (_) {
        if (_apiClient != null) {
          try {
            return await _apiClient.uploadImageFile(file);
          } catch (_) {}
        }
        throw ApiException(
          'Could not upload avatar. Try a smaller photo, or enable Firebase Storage in Firebase Console.',
        );
      }
    }
  }

  Future<String> _uploadToFirebase(
    XFile file, {
    required String folder,
    String? fixedName,
  }) async {
    final prepared = await ImageUploadHelper.prepare(file);
    final name = fixedName ?? '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child('$folder/$name');
    await ref.putData(
      prepared.bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return ref.getDownloadURL();
  }

  Future<String> _uploadToFirestore(XFile file, {required String folder}) async {
    final prepared = await ImageUploadHelper.prepareCompact(file);
    return _mediaStore.uploadBytes(prepared.bytes, folder: folder);
  }
}
