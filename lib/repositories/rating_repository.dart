import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/errors/app_failure.dart';
import '../demo/demo_store.dart';
import '../firebase/firestore_paths.dart';
import '../models/rating_entry.dart';

/// One rating per user per property (doc id `{propertyId}_{uid}`).
/// Property aggregates are maintained by Cloud Functions.
class RatingRepository {
  RatingRepository(FirebaseFirestore? db) : _db = db;

  final FirebaseFirestore? _db;

  FirebaseFirestore get _firestore {
    final FirebaseFirestore? db = _db;
    if (db == null) throw const AppFailure('Firebase غير مهيأ.');
    return db;
  }

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(FirestorePaths.ratings);

  Stream<RatingEntry?> watchMyRating(String propertyId, String uid) {
    if (DemoStore.enabled) {
      return DemoStore.instance.watchRatings(
        () => DemoStore.instance.findRating(propertyId, uid),
      );
    }
    return _col.doc(RatingEntry.docId(propertyId, uid)).snapshots().map(
        (DocumentSnapshot<Map<String, dynamic>> snap) {
      final Map<String, dynamic>? data = snap.data();
      if (!snap.exists || data == null) return null;
      return RatingEntry.fromMap(snap.id, data);
    });
  }

  Future<void> submitRating({
    required String propertyId,
    required String uid,
    required int value,
  }) async {
    assert(value >= 1 && value <= 5);
    if (DemoStore.enabled) {
      DemoStore.instance.submitRating(
        propertyId: propertyId,
        uid: uid,
        value: value,
      );
      return;
    }
    final RatingEntry entry = RatingEntry(
      id: RatingEntry.docId(propertyId, uid),
      propertyId: propertyId,
      userId: uid,
      value: value,
    );
    await _col.doc(entry.id).set(entry.toMap(forCreate: true));
  }
}
