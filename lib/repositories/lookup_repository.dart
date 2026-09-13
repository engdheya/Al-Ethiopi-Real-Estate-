import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/errors/app_failure.dart';
import '../demo/demo_store.dart';
import '../firebase/firestore_paths.dart';
import '../models/area.dart';
import '../models/city.dart';
import '../models/feature_item.dart';
import '../models/property_type.dart';

/// Admin-managed catalogs: types, cities, areas, features.
class LookupRepository {
  LookupRepository(FirebaseFirestore? db) : _db = db;

  final FirebaseFirestore? _db;

  FirebaseFirestore get _firestore {
    final FirebaseFirestore? db = _db;
    if (db == null) throw const AppFailure('Firebase غير مهيأ.');
    return db;
  }

  // ------------------------------------------------------------ property types

  Stream<List<PropertyType>> watchTypes({bool activeOnly = true}) {
    if (DemoStore.enabled) {
      return DemoStore.instance.watchLookups(
        () => DemoStore.instance.types
            .where((PropertyType t) => !activeOnly || t.isActive)
            .toList(),
      );
    }
    Query<Map<String, dynamic>> q = _firestore
        .collection(FirestorePaths.propertyTypes)
        .orderBy('order');
    if (activeOnly) q = q.where('isActive', isEqualTo: true);
    return q.snapshots().map((s) =>
        s.docs.map((d) => PropertyType.fromMap(d.id, d.data())).toList());
  }

  Future<List<PropertyType>> fetchTypes({bool activeOnly = true}) async {
    if (DemoStore.enabled) {
      return DemoStore.instance.types
          .where((PropertyType t) => !activeOnly || t.isActive)
          .toList();
    }
    Query<Map<String, dynamic>> q = _firestore
        .collection(FirestorePaths.propertyTypes)
        .orderBy('order');
    if (activeOnly) q = q.where('isActive', isEqualTo: true);
    final QuerySnapshot<Map<String, dynamic>> snap = await q.get();
    return snap.docs.map((d) => PropertyType.fromMap(d.id, d.data())).toList();
  }

  // ------------------------------------------------------------------ cities

  Stream<List<City>> watchCities({bool activeOnly = true}) {
    if (DemoStore.enabled) {
      return DemoStore.instance.watchLookups(
        () => DemoStore.instance.cities
            .where((City c) => !activeOnly || c.isActive)
            .toList(),
      );
    }
    Query<Map<String, dynamic>> q =
        _firestore.collection(FirestorePaths.cities).orderBy('order');
    if (activeOnly) q = q.where('isActive', isEqualTo: true);
    return q.snapshots().map((s) =>
        s.docs.map((d) => City.fromMap(d.id, d.data())).toList());
  }

  Future<List<City>> fetchCities({bool activeOnly = true}) async {
    if (DemoStore.enabled) {
      return DemoStore.instance.cities
          .where((City c) => !activeOnly || c.isActive)
          .toList();
    }
    Query<Map<String, dynamic>> q =
        _firestore.collection(FirestorePaths.cities).orderBy('order');
    if (activeOnly) q = q.where('isActive', isEqualTo: true);
    final QuerySnapshot<Map<String, dynamic>> snap = await q.get();
    return snap.docs.map((d) => City.fromMap(d.id, d.data())).toList();
  }

  // ------------------------------------------------------------------- areas

  Stream<List<Area>> watchAreas(String cityId, {bool activeOnly = true}) {
    if (DemoStore.enabled) {
      return DemoStore.instance.watchLookups(
        () => DemoStore.instance.areas
            .where((Area a) =>
                a.cityId == cityId && (!activeOnly || a.isActive))
            .toList(),
      );
    }
    Query<Map<String, dynamic>> q = _firestore
        .collection(FirestorePaths.areas)
        .where('cityId', isEqualTo: cityId)
        .orderBy('order');
    if (activeOnly) q = q.where('isActive', isEqualTo: true);
    return q.snapshots().map((s) =>
        s.docs.map((d) => Area.fromMap(d.id, d.data())).toList());
  }

  Future<List<Area>> fetchAreas(String cityId,
      {bool activeOnly = true}) async {
    if (DemoStore.enabled) {
      return DemoStore.instance.areas
          .where(
              (Area a) => a.cityId == cityId && (!activeOnly || a.isActive))
          .toList();
    }
    Query<Map<String, dynamic>> q = _firestore
        .collection(FirestorePaths.areas)
        .where('cityId', isEqualTo: cityId)
        .orderBy('order');
    if (activeOnly) q = q.where('isActive', isEqualTo: true);
    final QuerySnapshot<Map<String, dynamic>> snap = await q.get();
    return snap.docs.map((d) => Area.fromMap(d.id, d.data())).toList();
  }

  Stream<List<Area>> watchAllAreas() {
    if (DemoStore.enabled) {
      return DemoStore.instance
          .watchLookups(() => DemoStore.instance.areas.toList());
    }
    return _firestore
        .collection(FirestorePaths.areas)
        .orderBy('order')
        .snapshots()
        .map((s) =>
            s.docs.map((d) => Area.fromMap(d.id, d.data())).toList());
  }

  // ---------------------------------------------------------------- features

  Stream<List<FeatureItem>> watchFeatures({bool activeOnly = true}) {
    if (DemoStore.enabled) {
      return DemoStore.instance.watchLookups(
        () => DemoStore.instance.features
            .where((FeatureItem f) => !activeOnly || f.isActive)
            .toList(),
      );
    }
    Query<Map<String, dynamic>> q =
        _firestore.collection(FirestorePaths.features).orderBy('order');
    if (activeOnly) q = q.where('isActive', isEqualTo: true);
    return q.snapshots().map((s) =>
        s.docs.map((d) => FeatureItem.fromMap(d.id, d.data())).toList());
  }

  Future<List<FeatureItem>> fetchFeatures({bool activeOnly = true}) async {
    if (DemoStore.enabled) {
      return DemoStore.instance.features
          .where((FeatureItem f) => !activeOnly || f.isActive)
          .toList();
    }
    Query<Map<String, dynamic>> q =
        _firestore.collection(FirestorePaths.features).orderBy('order');
    if (activeOnly) q = q.where('isActive', isEqualTo: true);
    final QuerySnapshot<Map<String, dynamic>> snap = await q.get();
    return snap.docs.map((d) => FeatureItem.fromMap(d.id, d.data())).toList();
  }

  // ------------------------------------------------------------- admin CRUD

  Future<String> addType(PropertyType type) async {
    if (DemoStore.enabled) return DemoStore.instance.addType(type);
    final DocumentReference<Map<String, dynamic>> ref = await _firestore
        .collection(FirestorePaths.propertyTypes)
        .add(type.toMap());
    return ref.id;
  }

  Future<void> updateType(PropertyType type) async {
    if (DemoStore.enabled) {
      DemoStore.instance.updateType(type);
      return;
    }
    await _firestore
        .collection(FirestorePaths.propertyTypes)
        .doc(type.id)
        .update(type.toMap());
  }

  Future<void> deleteType(String id) async {
    if (DemoStore.enabled) {
      DemoStore.instance.deleteType(id);
      return;
    }
    await _firestore.collection(FirestorePaths.propertyTypes).doc(id).delete();
  }

  Future<String> addCity(City city) async {
    if (DemoStore.enabled) return DemoStore.instance.addCity(city);
    final DocumentReference<Map<String, dynamic>> ref =
        await _firestore.collection(FirestorePaths.cities).add(city.toMap());
    return ref.id;
  }

  Future<void> updateCity(City city) async {
    if (DemoStore.enabled) {
      DemoStore.instance.updateCity(city);
      return;
    }
    await _firestore
        .collection(FirestorePaths.cities)
        .doc(city.id)
        .update(city.toMap());
  }

  Future<void> deleteCity(String id) async {
    if (DemoStore.enabled) {
      DemoStore.instance.deleteCity(id);
      return;
    }
    await _firestore.collection(FirestorePaths.cities).doc(id).delete();
  }

  Future<String> addArea(Area area) async {
    if (DemoStore.enabled) return DemoStore.instance.addArea(area);
    final DocumentReference<Map<String, dynamic>> ref =
        await _firestore.collection(FirestorePaths.areas).add(area.toMap());
    return ref.id;
  }

  Future<void> updateArea(Area area) async {
    if (DemoStore.enabled) {
      DemoStore.instance.updateArea(area);
      return;
    }
    await _firestore
        .collection(FirestorePaths.areas)
        .doc(area.id)
        .update(area.toMap());
  }

  Future<void> deleteArea(String id) async {
    if (DemoStore.enabled) {
      DemoStore.instance.deleteArea(id);
      return;
    }
    await _firestore.collection(FirestorePaths.areas).doc(id).delete();
  }

  Future<String> addFeature(FeatureItem feature) async {
    if (DemoStore.enabled) return DemoStore.instance.addFeature(feature);
    final DocumentReference<Map<String, dynamic>> ref = await _firestore
        .collection(FirestorePaths.features)
        .add(feature.toMap());
    return ref.id;
  }

  Future<void> updateFeature(FeatureItem feature) async {
    if (DemoStore.enabled) {
      DemoStore.instance.updateFeature(feature);
      return;
    }
    await _firestore
        .collection(FirestorePaths.features)
        .doc(feature.id)
        .update(feature.toMap());
  }

  Future<void> deleteFeature(String id) async {
    if (DemoStore.enabled) {
      DemoStore.instance.deleteFeature(id);
      return;
    }
    await _firestore.collection(FirestorePaths.features).doc(id).delete();
  }
}
