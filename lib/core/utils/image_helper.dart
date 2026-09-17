import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

import '../constants/app_constants.dart';

/// Gallery picking + compression for property uploads.
class ImageHelper {
  ImageHelper._();

  static final ImagePicker _picker = ImagePicker();

  static const List<String> allowedExtensions = <String>[
    'jpg',
    'jpeg',
    'png',
    'webp',
  ];

  /// Picks multiple images from the gallery, compressed for upload.
  static Future<List<File>> pickPropertyImages({int max = 12}) async {
    final List<XFile> picked = await _picker.pickMultiImage(
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 82,
    );
    if (picked.isEmpty) return <File>[];
    final List<File> files = <File>[];
    for (final XFile x in picked.take(max)) {
      final File? compressed = await compressImageFile(File(x.path));
      if (compressed != null) files.add(compressed);
    }
    return files;
  }

  static Future<File?> pickSingleImage() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );
    if (picked == null) return null;
    return compressImageFile(File(picked.path), quality: 78);
  }

  /// Compresses to JPEG under the upload size cap. Returns null when the
  /// file type is not an allowed image.
  static Future<File?> compressImageFile(File file, {int quality = 82}) async {
    final String ext = file.path.split('.').last.toLowerCase();
    if (!allowedExtensions.contains(ext)) return null;
    try {
      final String targetPath = '${file.path}_compressed.jpg';
      final XFile? result = await FlutterImageCompress.compressAndGetFile(
        file.path,
        targetPath,
        minWidth: 1600,
        minHeight: 1200,
        quality: quality,
        format: CompressFormat.jpeg,
      );
      if (result == null) return null;
      final File out = File(result.path);
      if (await out.length() > AppConstants.maxImageUploadBytes) {
        // Second pass with lower quality for very detailed photos.
        final XFile? retry = await FlutterImageCompress.compressAndGetFile(
          file.path,
          targetPath,
          minWidth: 1280,
          minHeight: 960,
          quality: 70,
          format: CompressFormat.jpeg,
        );
        if (retry == null) return null;
        return File(retry.path);
      }
      return out;
    } catch (_) {
      // If compression fails (rare device codecs), fall back to the original.
      if (await file.length() <= AppConstants.maxImageUploadBytes) {
        return file;
      }
      return null;
    }
  }
}
