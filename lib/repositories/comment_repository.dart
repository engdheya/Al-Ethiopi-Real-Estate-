import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/errors/app_failure.dart';
import '../demo/demo_store.dart';
import '../firebase/firestore_paths.dart';
import '../models/comment.dart';

/// Comments: users manage their own, admin moderates everything.
/// Aggregates (`commentsCount` on the property) are maintained by the Cloud
/// Function in `functions/` reacting to writes.
class CommentRepository {
  CommentRepository(FirebaseFirestore? db) : _db = db;

  final FirebaseFirestore? _db;

  FirebaseFirestore get _firestore {
    final FirebaseFirestore? db = _db;
    if (db == null) throw const AppFailure('Firebase غير مهيأ.');
    return db;
  }

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(FirestorePaths.comments);

  Stream<List<PropertyComment>> watchComments(String propertyId,
      {int limit = 50}) {
    if (DemoStore.enabled) {
      return DemoStore.instance.watchComments(
        (List<PropertyComment> all) => all
            .where((PropertyComment c) =>
                c.propertyId == propertyId && !c.isHidden)
            .take(limit)
            .toList(),
      );
    }
    return _col
        .where('propertyId', isEqualTo: propertyId)
        .where('isHidden', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs
            .map((d) => PropertyComment.fromMap(d.id, d.data()))
            .toList());
  }

  /// Admin moderation queue (includes hidden comments).
  Stream<List<PropertyComment>> watchRecentForAdmin({int limit = 50}) {
    if (DemoStore.enabled) {
      return DemoStore.instance.watchComments(
        (List<PropertyComment> all) => all.take(limit).toList(),
      );
    }
    return _col
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs
            .map((d) => PropertyComment.fromMap(d.id, d.data()))
            .toList());
  }

  Future<int> countAll() async {
    if (DemoStore.enabled) return DemoStore.instance.comments.length;
    final AggregateQuerySnapshot snap = await _col.count().get();
    return snap.count ?? 0;
  }

  Future<String> addComment(PropertyComment comment) async {
    if (DemoStore.enabled) return DemoStore.instance.addComment(comment);
    final DocumentReference<Map<String, dynamic>> ref =
        await _col.add(comment.toMap(forCreate: true));
    return ref.id;
  }

  Future<void> updateComment(PropertyComment comment) async {
    if (DemoStore.enabled) {
      DemoStore.instance.updateComment(comment);
      return;
    }
    await _col.doc(comment.id).update(comment.toMap());
  }

  Future<void> deleteComment(String id) async {
    if (DemoStore.enabled) {
      DemoStore.instance.deleteComment(id);
      return;
    }
    await _col.doc(id).delete();
  }

  Future<void> setHidden(String id, bool hidden) async {
    if (DemoStore.enabled) {
      DemoStore.instance.setCommentHidden(id, hidden);
      return;
    }
    await _col.doc(id).update(<String, dynamic>{'isHidden': hidden});
  }

  Future<void> toggleLike(String commentId, String uid) async {
    if (DemoStore.enabled) {
      DemoStore.instance.toggleCommentLike(commentId, uid);
      return;
    }
    final DocumentReference<Map<String, dynamic>> ref = _col.doc(commentId);
    await _firestore.runTransaction((Transaction tx) async {
      final DocumentSnapshot<Map<String, dynamic>> snap = await tx.get(ref);
      final List<dynamic> liked =
          List<dynamic>.from(snap.data()?['likedBy'] as List? ?? <dynamic>[]);
      if (liked.contains(uid)) {
        tx.update(ref, <String, dynamic>{
          'likedBy': FieldValue.arrayRemove(<String>[uid]),
        });
      } else {
        tx.update(ref, <String, dynamic>{
          'likedBy': FieldValue.arrayUnion(<String>[uid]),
        });
      }
    });
  }
}
