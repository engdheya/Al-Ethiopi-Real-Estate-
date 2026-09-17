import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/errors/app_failure.dart';
import '../demo/demo_store.dart';
import '../firebase/firestore_paths.dart';
import '../models/app_settings.dart';

/// Public app settings (`settings/app`): contact info + legal pages.
class SettingsRepository {
  SettingsRepository(FirebaseFirestore? db) : _db = db;

  final FirebaseFirestore? _db;

  FirebaseFirestore get _firestore {
    final FirebaseFirestore? db = _db;
    if (db == null) throw const AppFailure('Firebase غير مهيأ.');
    return db;
  }

  DocumentReference<Map<String, dynamic>> get _doc => _firestore
      .collection(FirestorePaths.settings)
      .doc(FirestorePaths.settingsAppDoc);

  Stream<AppSettings> watchSettings() {
    if (DemoStore.enabled) {
      return DemoStore.instance.watchSettings(() => DemoStore.instance.settings);
    }
    return _doc.snapshots().map((snap) {
      final Map<String, dynamic>? data = snap.data();
      if (data == null) return const AppSettings();
      return AppSettings.fromMap(data);
    });
  }

  Future<AppSettings> getSettings() async {
    if (DemoStore.enabled) return DemoStore.instance.settings;
    final DocumentSnapshot<Map<String, dynamic>> snap = await _doc.get();
    final Map<String, dynamic>? data = snap.data();
    if (data == null) return const AppSettings();
    return AppSettings.fromMap(data);
  }

  Future<void> saveSettings(AppSettings settings) async {
    if (DemoStore.enabled) {
      DemoStore.instance.saveSettings(settings);
      return;
    }
    await _doc.set(settings.toMap(), SetOptions(merge: true));
  }
}
