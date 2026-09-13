import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/errors/app_failure.dart';
import '../demo/demo_store.dart';
import '../firebase/firestore_paths.dart';
import '../models/app_notification.dart';

/// Admin-written broadcast log. Push delivery to FCM topics is performed by
/// the Cloud Function in `functions/` (see docs/FIREBASE_SETUP_AR.md).
class NotificationRepository {
  NotificationRepository(FirebaseFirestore? db) : _db = db;

  final FirebaseFirestore? _db;

  FirebaseFirestore get _firestore {
    final FirebaseFirestore? db = _db;
    if (db == null) throw const AppFailure('Firebase غير مهيأ.');
    return db;
  }

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(FirestorePaths.notifications);

  Stream<List<AppNotification>> watchNotifications({int limit = 30}) {
    if (DemoStore.enabled) {
      return DemoStore.instance.watchNotifications(
        () => DemoStore.instance.notifications.take(limit).toList(),
      );
    }
    return _col
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs
            .map((d) => AppNotification.fromMap(d.id, d.data()))
            .toList());
  }

  Future<String> sendNotification(AppNotification notification) async {
    if (DemoStore.enabled) {
      return DemoStore.instance.sendNotification(notification);
    }
    final DocumentReference<Map<String, dynamic>> ref =
        await _col.add(notification.toMap(forCreate: true));
    return ref.id;
  }

  Future<void> deleteNotification(String id) async {
    if (DemoStore.enabled) {
      DemoStore.instance.deleteNotification(id);
      return;
    }
    await _col.doc(id).delete();
  }
}
