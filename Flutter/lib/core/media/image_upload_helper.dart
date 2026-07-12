import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

/// Result of local resize/compress before POST /api/uploads.
class PreparedUploadImage {
  const PreparedUploadImage({
    required this.bytes,
    required this.fileName,
  });

  final Uint8List bytes;
  final String fileName;
}

/// Picks any gallery image, converts to JPEG, and compresses for upload.
abstract final class ImageUploadHelper {
  static const int maxUploadBytes = 4 * 1024 * 1024;
  static const int maxFirestoreBytes = 450 * 1024;
  static const int maxInputBytes = 25 * 1024 * 1024;
  static const int maxDimension = 2048;

  static const List<int> _dimensions = [2048, 1600, 1280, 1024];
  static const List<int> _qualities = [88, 78, 68, 58, 48, 40];

  static Future<PreparedUploadImage> prepare(XFile file) async {
    final raw = await file.readAsBytes();
    if (raw.isEmpty) {
      throw Exception('Image file is empty.');
    }
    if (raw.length > maxInputBytes) {
      throw Exception('Image is too large (max 25MB).');
    }

    Uint8List? best;
    for (final dimension in _dimensions) {
      for (final quality in _qualities) {
        final out = await FlutterImageCompress.compressWithList(
          raw,
          minWidth: dimension,
          minHeight: dimension,
          quality: quality,
          format: CompressFormat.jpeg,
          autoCorrectionAngle: true,
          keepExif: false,
        );
        if (out.isEmpty) continue;
        best = Uint8List.fromList(out);
        if (out.length <= maxUploadBytes) {
          return PreparedUploadImage(bytes: best, fileName: 'upload.jpg');
        }
      }
    }

    if (best == null || best.isEmpty) {
      throw Exception('Could not process image. Try another photo.');
    }
    if (best.length > maxUploadBytes) {
      throw Exception(
        'Image is still too large after compression. Try a smaller photo.',
      );
    }

    return PreparedUploadImage(bytes: best, fileName: 'upload.jpg');
  }

  /// Smaller JPEG for Firestore inline storage (under 1MB document limit).
  static Future<PreparedUploadImage> prepareCompact(XFile file) async {
    final raw = await file.readAsBytes();
    if (raw.isEmpty) {
      throw Exception('Image file is empty.');
    }
    if (raw.length > maxInputBytes) {
      throw Exception('Image is too large (max 25MB).');
    }

    Uint8List? best;
    const dimensions = [1280, 1024, 800, 640, 480];
    const qualities = [78, 68, 58, 48, 38, 30];

    for (final dimension in dimensions) {
      for (final quality in qualities) {
        final out = await FlutterImageCompress.compressWithList(
          raw,
          minWidth: dimension,
          minHeight: dimension,
          quality: quality,
          format: CompressFormat.jpeg,
          autoCorrectionAngle: true,
          keepExif: false,
        );
        if (out.isEmpty) continue;
        best = Uint8List.fromList(out);
        if (out.length <= maxFirestoreBytes) {
          return PreparedUploadImage(bytes: best, fileName: 'upload.jpg');
        }
      }
    }

    if (best == null || best.isEmpty) {
      throw Exception('Could not process image. Try another photo.');
    }
    if (best.length > maxFirestoreBytes) {
      throw Exception(
        'Image is still too large. Try a smaller or simpler photo.',
      );
    }

    return PreparedUploadImage(bytes: best, fileName: 'upload.jpg');
  }
}
