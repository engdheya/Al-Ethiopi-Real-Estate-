import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../demo/demo_store.dart';
import '../repositories/auth_repository.dart';
import '../repositories/comment_repository.dart';
import '../repositories/contact_repository.dart';
import '../repositories/favorite_repository.dart';
import '../repositories/lookup_repository.dart';
import '../repositories/notification_repository.dart';
import '../repositories/property_repository.dart';
import '../repositories/rating_repository.dart';
import '../repositories/report_repository.dart';
import '../repositories/settings_repository.dart';
import '../repositories/storage_repository.dart';

/// Holds initialized Firebase singletons.
///
/// When Firebase cannot be initialized (e.g. `google-services.json` is not
/// configured yet), the app boots into an explicit **demo mode** using local
/// sample data so UI work and evaluation can continue. Production data always
/// comes from Firebase.
class AppBackend {
  AppBackend._();

  static FirebaseFirestore? firestore;
  static FirebaseAuth? auth;
  static FirebaseStorage? storage;
  static FirebaseMessaging? messaging;

  static bool get demoMode => DemoStore.enabled;
}

// ---------------------------------------------------------------------------
// Firebase singletons (null in demo mode)
// ---------------------------------------------------------------------------

final Provider<FirebaseFirestore?> firestoreProvider =
    Provider<FirebaseFirestore?>((Ref ref) => AppBackend.firestore);

final Provider<FirebaseAuth?> firebaseAuthProvider =
    Provider<FirebaseAuth?>((Ref ref) => AppBackend.auth);

final Provider<FirebaseStorage?> firebaseStorageProvider =
    Provider<FirebaseStorage?>((Ref ref) => AppBackend.storage);

final Provider<FirebaseMessaging?> firebaseMessagingProvider =
    Provider<FirebaseMessaging?>((Ref ref) => AppBackend.messaging);

/// Overridden in `main()` after `SharedPreferences.getInstance()`.
final Provider<SharedPreferences> sharedPreferencesProvider =
    Provider<SharedPreferences>((Ref ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

// ---------------------------------------------------------------------------
// Repositories
// ---------------------------------------------------------------------------

final Provider<AuthRepository> authRepositoryProvider =
    Provider<AuthRepository>((Ref ref) {
  return AuthRepository(
    auth: ref.watch(firebaseAuthProvider),
    db: ref.watch(firestoreProvider),
  );
});

final Provider<PropertyRepository> propertyRepositoryProvider =
    Provider<PropertyRepository>((Ref ref) {
  return PropertyRepository(ref.watch(firestoreProvider));
});

final Provider<LookupRepository> lookupRepositoryProvider =
    Provider<LookupRepository>((Ref ref) {
  return LookupRepository(ref.watch(firestoreProvider));
});

final Provider<CommentRepository> commentRepositoryProvider =
    Provider<CommentRepository>((Ref ref) {
  return CommentRepository(ref.watch(firestoreProvider));
});

final Provider<RatingRepository> ratingRepositoryProvider =
    Provider<RatingRepository>((Ref ref) {
  return RatingRepository(ref.watch(firestoreProvider));
});

final Provider<FavoriteRepository> favoriteRepositoryProvider =
    Provider<FavoriteRepository>((Ref ref) {
  return FavoriteRepository(
    ref.watch(firestoreProvider),
    ref.watch(sharedPreferencesProvider),
  );
});

final Provider<ReportRepository> reportRepositoryProvider =
    Provider<ReportRepository>((Ref ref) {
  return ReportRepository(ref.watch(firestoreProvider));
});

final Provider<ContactRepository> contactRepositoryProvider =
    Provider<ContactRepository>((Ref ref) {
  return ContactRepository(ref.watch(firestoreProvider));
});

final Provider<SettingsRepository> settingsRepositoryProvider =
    Provider<SettingsRepository>((Ref ref) {
  return SettingsRepository(ref.watch(firestoreProvider));
});

final Provider<NotificationRepository> notificationRepositoryProvider =
    Provider<NotificationRepository>((Ref ref) {
  return NotificationRepository(ref.watch(firestoreProvider));
});

final Provider<StorageRepository> storageRepositoryProvider =
    Provider<StorageRepository>((Ref ref) {
  return StorageRepository(ref.watch(firebaseStorageProvider));
});
