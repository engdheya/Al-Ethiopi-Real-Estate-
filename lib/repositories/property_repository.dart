import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/errors/app_failure.dart';
import '../core/utils/keywords.dart';
import '../demo/demo_store.dart';
import '../firebase/firestore_paths.dart';
import '../models/property.dart';
import '../models/property_filter.dart';
import '../models/property_page.dart';

/// One page of a paginated property query.
class PropertyPage {
  const PropertyPage({
    required this.items,
    required this.hasMore,
    this.lastDoc,
  });

  final List<Property> items;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool hasMore;
}

/// Dashboard counters for the admin panel.
class PropertyStats {
  const PropertyStats({
    this.total = 0,
    this.sale = 0,
    this.rent = 0,
    this.featured = 0,
    this.available = 0,
    this.sold = 0,
    this.rented = 0,
  });

  final int total;
  final int sale;
  final int rent;
  final int featured;
  final int available;
  final int sold;
  final int rented;
}

/// All Firestore access for properties.
///
/// Query strategy (kept index-light on purpose):
///  * Server-side: `isPublished == true` + ONE equality/prefix selector
///    (search token, area, city, type, purpose, featured) + ordering.
///  * Everything else (price/size ranges, bedrooms, bathrooms, status) is
///    filtered client-side on the fetched page window.
class PropertyRepository {
  PropertyRepository(FirebaseFirestore? db) : _db = db;

  final FirebaseFirestore? _db;

  FirebaseFirestore get _firestore {
    final FirebaseFirestore? db = _db;
    if (db == null) throw const AppFailure('Firebase غير مهيأ.');
    return db;
  }

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection(FirestorePaths.properties);

  // ------------------------------------------------------------- public API

  Future<PropertyPage> fetchProperties({
    required PropertyFilter filter,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    String? startAfterId,
    int limit = 12,
  }) async {
    if (DemoStore.enabled) {
      return DemoStore.instance.fetchProperties(
        filter: filter,
        startAfterId: startAfterId ?? startAfter?.id,
        limit: limit,
      );
    }

    Query<Map<String, dynamic>> query =
        _col.where('isPublished', isEqualTo: true);

    // ONE server-side selector (keeps composite-index needs small).
    final List<String> tokens = SearchKeywords.queryTokens(filter.query);
    if (tokens.isNotEmpty) {
      query = query.where('searchKeywords', arrayContains: tokens.first);
    } else if (filter.onlyFeatured) {
      query = query.where('isFeatured', isEqualTo: true);
    } else if (filter.areaId != null) {
      query = query.where('areaId', isEqualTo: filter.areaId);
    } else if (filter.cityId != null) {
      query = query.where('cityId', isEqualTo: filter.cityId);
    } else if (filter.typeId != null) {
      query = query.where('typeId', isEqualTo: filter.typeId);
    } else if (filter.purpose != null) {
      query = query.where('purpose', isEqualTo: filter.purpose!.value);
    }

    switch (filter.sort) {
      case PropertySort.priceAsc:
        query = query.orderBy('price');
        break;
      case PropertySort.priceDesc:
        query = query.orderBy('price', descending: true);
        break;
      case PropertySort.newest:
        query = query.orderBy('createdAt', descending: true);
        break;
    }

    // Over-fetch: client-side filters below may drop some docs.
    query = query.limit(limit * 3);
    if (startAfter != null) query = query.startAfterDocument(startAfter);

    final QuerySnapshot<Map<String, dynamic>> snap = await query.get();
    final List<Property> all = snap.docs
        .map((QueryDocumentSnapshot<Map<String, dynamic>> d) =>
            Property.fromMap(d.id, d.data()))
        .where((Property p) => _matchesClientFilters(p, filter))
        .toList();

    // Re-sort when a price ordering was combined with a server selector.
    if (filter.sort == PropertySort.priceAsc) {
      all.sort((Property a, Property b) => a.price.compareTo(b.price));
    } else if (filter.sort == PropertySort.priceDesc) {
      all.sort((Property a, Property b) => b.price.compareTo(a.price));
    }

    final List<Property> page = all.take(limit).toList();
    // Cursor: keep server pagination stable by anchoring to the last
    // fetched server doc (approximation that stays correct because the
    // server order is stable).
    final DocumentSnapshot<Map<String, dynamic>>? lastDoc =
        snap.docs.isEmpty ? null : snap.docs.last;
    return PropertyPage(
      items: page,
      lastDoc: lastDoc,
      hasMore: snap.docs.length >= limit * 3 || all.length > page.length,
    );
  }

  bool _matchesClientFilters(Property p, PropertyFilter filter) {
    if (filter.purpose != null && p.purpose != filter.purpose) return false;
    if (filter.typeId != null && p.typeId != filter.typeId) return false;
    if (filter.cityId != null && p.cityId != filter.cityId) return false;
    if (filter.areaId != null && p.areaId != filter.areaId) return false;
    if (filter.onlyFeatured && !p.isFeatured) return false;
    if (filter.minPrice != null && p.price < filter.minPrice!) return false;
    if (filter.maxPrice != null && p.price > filter.maxPrice!) return false;
    if (filter.minSize != null && p.size < filter.minSize!) return false;
    if (filter.maxSize != null && p.size > filter.maxSize!) return false;
    if (filter.minBedrooms != null && p.bedrooms < filter.minBedrooms!) {
      return false;
    }
    if (filter.minBathrooms != null && p.bathrooms < filter.minBathrooms!) {
      return false;
    }
    if (filter.status != null && p.status != filter.status) return false;
    final List<String> tokens = SearchKeywords.queryTokens(filter.query);
    if (tokens.length > 1) {
      // First token matched server-side; verify the rest locally.
      final String haystack = SearchKeywords.normalize(
        '${p.title} ${p.cityName} ${p.areaName} ${p.typeName} ${p.address}',
      );
      for (final String t in tokens.skip(1)) {
        if (!haystack.contains(t)) return false;
      }
    }
    return true;
  }

  Stream<List<Property>> watchFeatured({int limit = 10}) {
    if (DemoStore.enabled) {
      return DemoStore.instance.watchProperties(
        (List<Property> all) => all
            .where((Property p) => p.isPublished && p.isFeatured)
            .take(limit)
            .toList(),
      );
    }
    return _col
        .where('isPublished', isEqualTo: true)
        .where('isFeatured', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> s) =>
            s.docs.map((d) => Property.fromMap(d.id, d.data())).toList());
  }

  Stream<List<Property>> watchLatest({int limit = 10}) {
    if (DemoStore.enabled) {
      return DemoStore.instance.watchProperties(
        (List<Property> all) =>
            all.where((Property p) => p.isPublished).take(limit).toList(),
      );
    }
    return _col
        .where('isPublished', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> s) =>
            s.docs.map((d) => Property.fromMap(d.id, d.data())).toList());
  }

  Stream<List<Property>> watchByPurpose(PropertyPurpose purpose,
      {int limit = 10}) {
    if (DemoStore.enabled) {
      return DemoStore.instance.watchProperties(
        (List<Property> all) => all
            .where((Property p) => p.isPublished && p.purpose == purpose)
            .take(limit)
            .toList(),
      );
    }
    return _col
        .where('isPublished', isEqualTo: true)
        .where('purpose', isEqualTo: purpose.value)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> s) =>
            s.docs.map((d) => Property.fromMap(d.id, d.data())).toList());
  }

  Stream<Property?> watchProperty(String id) {
    if (DemoStore.enabled) {
      return DemoStore.instance.watchProperties(
        (List<Property> all) {
          try {
            return all.firstWhere((Property p) => p.id == id);
          } catch (_) {
            return null;
          }
        },
      );
    }
    return _col.doc(id).snapshots().map(
        (DocumentSnapshot<Map<String, dynamic>> snap) {
      final Map<String, dynamic>? data = snap.data();
      if (!snap.exists || data == null) return null;
      return Property.fromMap(snap.id, data);
    });
  }

  Future<Property?> getProperty(String id) async {
    if (DemoStore.enabled) return DemoStore.instance.findProperty(id);
    final DocumentSnapshot<Map<String, dynamic>> snap =
        await _col.doc(id).get();
    final Map<String, dynamic>? data = snap.data();
    if (!snap.exists || data == null) return null;
    return Property.fromMap(snap.id, data);
  }

  /// Resolves favorite ids to published properties (10 ids per `whereIn`).
  Future<List<Property>> fetchByIds(List<String> ids) async {
    if (ids.isEmpty) return const <Property>[];
    if (DemoStore.enabled) return DemoStore.instance.findProperties(ids);
    final List<Property> out = <Property>[];
    for (int i = 0; i < ids.length; i += 10) {
      final List<String> chunk = ids.skip(i).take(10).toList();
      final QuerySnapshot<Map<String, dynamic>> snap = await _col
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final d in snap.docs) {
        final Property p = Property.fromMap(d.id, d.data());
        if (p.isPublished) out.add(p);
      }
    }
    // Preserve the favorites order.
    final Map<String, Property> byId = <String, Property>{
      for (final Property p in out) p.id: p,
    };
    return <Property>[
      for (final String id in ids)
        if (byId.containsKey(id)) byId[id]!,
    ];
  }

  // ------------------------------------------------------------------ admin

  Future<PropertyPage> fetchAdminPage({
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = 20,
  }) async {
    if (DemoStore.enabled) {
      return DemoStore.instance.fetchAdminPage(
        startAfterId: startAfter?.id,
        limit: limit,
      );
    }
    Query<Map<String, dynamic>> query =
        _col.orderBy('updatedAt', descending: true).limit(limit);
    if (startAfter != null) query = query.startAfterDocument(startAfter);
    final QuerySnapshot<Map<String, dynamic>> snap = await query.get();
    return PropertyPage(
      items: snap.docs
          .map((d) => Property.fromMap(d.id, d.data()))
          .toList(),
      lastDoc: snap.docs.isEmpty ? null : snap.docs.last,
      hasMore: snap.docs.length >= limit,
    );
  }

  Future<PropertyStats> getStats() async {
    if (DemoStore.enabled) return DemoStore.instance.propertyStats();
    Future<int> count(Query<Map<String, dynamic>> q) async {
      final AggregateQuerySnapshot s = await q.count().get();
      return s.count ?? 0;
    }

    final List<int> results = await Future.wait<int>(<Future<int>>[
      count(_col),
      count(_col.where('purpose', isEqualTo: 'sale')),
      count(_col.where('purpose', isEqualTo: 'rent')),
      count(_col.where('isFeatured', isEqualTo: true)),
      count(_col.where('status', isEqualTo: 'available')),
      count(_col.where('status', isEqualTo: 'sold')),
      count(_col.where('status', isEqualTo: 'rented')),
    ]);
    return PropertyStats(
      total: results[0],
      sale: results[1],
      rent: results[2],
      featured: results[3],
      available: results[4],
      sold: results[5],
      rented: results[6],
    );
  }

  /// Pre-generates a document id so images can be uploaded under the final
  /// `properties/{id}/` storage path before the document exists.
  String newPropertyId() {
    if (DemoStore.enabled) return '';
    return _col.doc().id;
  }

  Future<String> createProperty(Property property, {String? uid}) {
    return createPropertyWithId(newPropertyId(), property, uid: uid);
  }

  Future<String> createPropertyWithId(
    String id,
    Property property, {
    String? uid,
  }) async {
    final Property withKeywords = property.copyWith(
      searchKeywords: SearchKeywords.build(
        title: property.title,
        cityName: property.cityName,
        areaName: property.areaName,
        typeName: property.typeName,
        address: property.address,
        purpose: property.purpose.labelAr,
      ),
    );
    if (DemoStore.enabled) {
      return DemoStore.instance.addProperty(withKeywords);
    }
    await _col.doc(id).set(
          withKeywords.toMap(forCreate: true)
            ..['createdBy'] = uid ?? withKeywords.createdBy,
        );
    return id;
  }

  Future<void> updateProperty(Property property) async {
    final Property withKeywords = property.copyWith(
      searchKeywords: SearchKeywords.build(
        title: property.title,
        cityName: property.cityName,
        areaName: property.areaName,
        typeName: property.typeName,
        address: property.address,
        purpose: property.purpose.labelAr,
      ),
    );
    if (DemoStore.enabled) {
      DemoStore.instance.updateProperty(withKeywords);
      return;
    }
    await _col.doc(property.id).update(withKeywords.toMap());
  }

  Future<void> setPublished(String id, bool value) async {
    if (DemoStore.enabled) {
      DemoStore.instance.patchProperty(id, <String, dynamic>{
        'isPublished': value,
      });
      return;
    }
    await _col.doc(id).update(<String, dynamic>{
      'isPublished': value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setFeatured(String id, bool value) async {
    if (DemoStore.enabled) {
      DemoStore.instance.patchProperty(id, <String, dynamic>{
        'isFeatured': value,
      });
      return;
    }
    await _col.doc(id).update(<String, dynamic>{
      'isFeatured': value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> setStatus(String id, PropertyStatus status) async {
    if (DemoStore.enabled) {
      DemoStore.instance.patchProperty(id, <String, dynamic>{
        'status': status.value,
      });
      return;
    }
    await _col.doc(id).update(<String, dynamic>{
      'status': status.value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Deletes the property doc + its comments + its ratings in batches.
  /// Storage files must be deleted separately via [StorageRepository].
  Future<void> deleteProperty(String id) async {
    if (DemoStore.enabled) {
      DemoStore.instance.deleteProperty(id);
      return;
    }
    await _deleteQuery(
      _firestore.collection(FirestorePaths.comments).where('propertyId', isEqualTo: id),
    );
    await _deleteQuery(
      _firestore.collection(FirestorePaths.ratings).where('propertyId', isEqualTo: id),
    );
    await _col.doc(id).delete();
  }

  Future<void> _deleteQuery(Query<Map<String, dynamic>> query) async {
    QuerySnapshot<Map<String, dynamic>> snap =
        await query.limit(200).get();
    while (snap.docs.isNotEmpty) {
      final WriteBatch batch = _firestore.batch();
      for (final d in snap.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
      snap = await query.limit(200).get();
    }
  }
}
