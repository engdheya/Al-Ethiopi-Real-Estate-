import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../demo/demo_store.dart';
import '../firebase/firestore_paths.dart';

/// Favorites: Firestore subcollection for signed-in users, SharedPreferences
/// for guests. The favorites counter on the property is maintained by the
/// Cloud Function in `functions/`.
class FavoriteRepository {
  FavoriteRepository(FirebaseFirestore? db, SharedPreferences prefs)
      : _db = db,
        _prefs = prefs;

  final FirebaseFirestore? _db;
  final SharedPreferences _prefs;
  final StreamController<Set<String>> _guestController =
      StreamController<Set<String>>.broadcast();

  CollectionReference<Map<String, dynamic>> _userFavCol(String uid) {
    final FirebaseFirestore? db = _db;
    if (db == null) throw StateError('Firestore unavailable');
    return db
        .collection(FirestorePaths.users)
        .doc(uid)
        .collection(FirestorePaths.favorites);
  }

  // ------------------------------------------------------------- signed-in

  Stream<Set<String>> watchFavorites(String uid) {
    if (DemoStore.enabled || _db == null) {
      return watchGuestFavorites();
    }
    return _userFavCol(uid).snapshots().map(
          (QuerySnapshot<Map<String, dynamic>> s) =>
              s.docs.map((d) => d.id).toSet(),
        );
  }

  /// Toggles and returns the new state (`true` = now a favorite).
  Future<bool> toggleFavorite({String? uid, required String propertyId}) async {
    if (uid == null || DemoStore.enabled || _db == null) {
      return toggleGuestFavorite(propertyId);
    }
    final DocumentReference<Map<String, dynamic>> ref =
        _userFavCol(uid).doc(propertyId);
    final DocumentSnapshot<Map<String, dynamic>> snap = await ref.get();
    if (snap.exists) {
      await ref.delete();
      return false;
    }
    await ref.set(<String, dynamic>{
      'propertyId': propertyId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return true;
  }

  Future<void> removeFavorite({String? uid, required String propertyId}) async {
    if (uid == null || DemoStore.enabled || _db == null) {
      final Set<String> ids = guestFavoriteIds()..remove(propertyId);
      await _saveGuest(ids);
      return;
    }
    await _userFavCol(uid).doc(propertyId).delete();
  }

  // ------------------------------------------------------------------ guest

  Set<String> guestFavoriteIds() {
    return _prefs
            .getStringList(AppConstants.prefsGuestFavorites)
            ?.toSet() ??
        <String>{};
  }

  Stream<Set<String>> watchGuestFavorites() async* {
    yield guestFavoriteIds();
    yield* _guestController.stream;
  }

  Future<bool> toggleGuestFavorite(String propertyId) async {
    final Set<String> ids = guestFavoriteIds();
    final bool nowFavorite;
    if (ids.contains(propertyId)) {
      ids.remove(propertyId);
      nowFavorite = false;
    } else {
      ids.add(propertyId);
      nowFavorite = true;
    }
    await _saveGuest(ids);
    return nowFavorite;
  }

  Future<void> _saveGuest(Set<String> ids) async {
    await _prefs.setStringList(
      AppConstants.prefsGuestFavorites,
      ids.toList(),
    );
    _guestController.add(ids);
  }

  void dispose() {
    _guestController.close();
  }
}
