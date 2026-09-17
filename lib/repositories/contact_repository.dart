import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/errors/app_failure.dart';
import '../demo/demo_store.dart';
import '../firebase/firestore_paths.dart';
import '../models/contact_message.dart';

/// "Contact us" inbox: anyone (even guests) can send, admin reads.
class ContactRepository {
  ContactRepository(FirebaseFirestore? db) : _db = db;

  final FirebaseFirestore? _db;

  FirebaseFirestore get _firestore {
    final FirebaseFirestore? db = _db;
    if (db == null) throw const AppFailure('Firebase غير مهيأ.');
    return db;
  }

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(FirestorePaths.contactMessages);

  Future<String> sendMessage(ContactMessage message) async {
    if (DemoStore.enabled) return DemoStore.instance.sendMessage(message);
    final DocumentReference<Map<String, dynamic>> ref =
        await _col.add(message.toMap(forCreate: true));
    return ref.id;
  }

  Stream<List<ContactMessage>> watchMessages({int limit = 50}) {
    if (DemoStore.enabled) {
      return DemoStore.instance.watchMessages(
        () => DemoStore.instance.messages.take(limit).toList(),
      );
    }
    return _col
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs
            .map((d) => ContactMessage.fromMap(d.id, d.data()))
            .toList());
  }

  Future<void> markRead(String id) async {
    if (DemoStore.enabled) {
      DemoStore.instance.markMessageRead(id);
      return;
    }
    await _col.doc(id).update(<String, dynamic>{'isRead': true});
  }

  Future<void> deleteMessage(String id) async {
    if (DemoStore.enabled) {
      DemoStore.instance.deleteMessage(id);
      return;
    }
    await _col.doc(id).delete();
  }
}
