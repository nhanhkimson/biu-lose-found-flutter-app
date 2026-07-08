import 'package:beltei_app/core/media/image_upload_helper.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

/// Uploads listing and proof images to Firebase Storage.
class StorageUploadStore {
  StorageUploadStore({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  final FirebaseStorage _storage;

  Future<String> uploadImageFile(XFile file, {String folder = 'items'}) async {
    final prepared = await ImageUploadHelper.prepare(file);
    final name = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child('$folder/$name');
    await ref.putData(
      prepared.bytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return ref.getDownloadURL();
  }
}
