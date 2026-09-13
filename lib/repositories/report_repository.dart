import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/errors/app_failure.dart';
import '../demo/demo_store.dart';
import '../firebase/firestore_paths.dart';
import '../models/comment_report.dart';

/// Comment reports: users file, admin triages.
class ReportRepository {
  ReportRepository(FirebaseFirestore? db) : _db = db;

  final FirebaseFirestore? _db;

  FirebaseFirestore get _firestore {
    final FirebaseFirestore? db = _db;
    if (db == null) throw const AppFailure('Firebase غير مهيأ.');
    return db;
  }

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(FirestorePaths.reports);

  Future<String> fileReport(CommentReport report) async {
    if (DemoStore.enabled) return DemoStore.instance.fileReport(report);
    final DocumentReference<Map<String, dynamic>> ref =
        await _col.add(report.toMap(forCreate: true));
    return ref.id;
  }

  Stream<List<CommentReport>> watchReports({String? status, int limit = 50}) {
    if (DemoStore.enabled) {
      return DemoStore.instance.watchReports(
        () => DemoStore.instance.reports
            .where((CommentReport r) => status == null || r.status == status)
            .take(limit)
            .toList(),
      );
    }
    Query<Map<String, dynamic>> q =
        _col.orderBy('createdAt', descending: true).limit(limit);
    if (status != null) q = q.where('status', isEqualTo: status);
    return q.snapshots().map((s) =>
        s.docs.map((d) => CommentReport.fromMap(d.id, d.data())).toList());
  }

  Future<int> countPending() async {
    if (DemoStore.enabled) {
      return DemoStore.instance.reports
          .where((CommentReport r) => r.isPending)
          .length;
    }
    final AggregateQuerySnapshot snap = await _col
        .where('status', isEqualTo: 'pending')
        .count()
        .get();
    return snap.count ?? 0;
  }

  Future<void> setStatus(String id, String status) async {
    if (DemoStore.enabled) {
      DemoStore.instance.setReportStatus(id, status);
      return;
    }
    await _col.doc(id).update(<String, dynamic>{'status': status});
  }

  Future<void> deleteReport(String id) async {
    if (DemoStore.enabled) {
      DemoStore.instance.deleteReport(id);
      return;
    }
    await _col.doc(id).delete();
  }
}
