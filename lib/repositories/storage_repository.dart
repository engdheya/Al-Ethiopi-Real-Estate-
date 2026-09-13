import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

import '../core/errors/app_failure.dart';
import '../demo/demo_store.dart';
import '../models/property.dart';

/// Firebase Storage uploads for property galleries and user avatars.
class StorageRepository {
  StorageRepository(FirebaseStorage? storage) : _storage = storage;

  final FirebaseStorage? _storage;
  static const Uuid _uuid = Uuid();

  FirebaseStorage get _firebaseStorage {
    final FirebaseStorage? storage = _storage;
    if (storage == null) throw const AppFailure('Firebase غير مهيأ.');
    return storage;
  }

  /// Uploads one gallery photo and returns its Firestore metadata.
  Future<PropertyImage> uploadPropertyImage({
    required String propertyId,
    required File file,
    required int order,
    bool isMain = false,
  }) async {
    if (DemoStore.enabled) {
      // Demo mode: reference the local file directly.
      return PropertyImage(
        url: file.path,
        path: 'demo/$propertyId/${file.path.split('/').last}',
        isMain: isMain,
        order: order,
      );
    }
    final String ext = file.path.split('.').last.toLowerCase();
    final String safeExt =
        <String>['jpg', 'jpeg', 'png', 'webp'].contains(ext) ? ext : 'jpg';
    final String path =
        'properties/$propertyId/${_uuid.v4()}.$safeExt';
    final Reference ref = _firebaseStorage.ref().child(path);
    await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/$safeExt'),
    );
    final String url = await ref.getDownloadURL();
    return PropertyImage(url: url, path: path, isMain: isMain, order: order);
  }

  Future<void> deleteImage(String path) async {
    if (DemoStore.enabled || path.startsWith('demo/')) return;
    if (path.isEmpty) return;
    try {
      await _firebaseStorage.ref().child(path).delete();
    } on FirebaseException catch (e) {
      // Already deleted remotely — treat as success.
      if (e.code != 'object-not-found') rethrow;
    }
  }

  Future<String> uploadAvatar({
    required String uid,
    required File file,
  }) async {
    if (DemoStore.enabled) return file.path;
    final String path = 'users/$uid/avatar_${_uuid.v4()}.jpg';
    final Reference ref = _firebaseStorage.ref().child(path);
    await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );
    return ref.getDownloadURL();
  }
}
