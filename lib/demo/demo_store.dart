import 'dart:async';

import '../core/utils/keywords.dart';
import '../models/app_notification.dart';
import '../models/app_settings.dart';
import '../models/app_user.dart';
import '../models/area.dart';
import '../models/city.dart';
import '../models/comment.dart';
import '../models/comment_report.dart';
import '../models/contact_message.dart';
import '../models/feature_item.dart';
import '../models/property.dart';
import '../models/property_filter.dart';
import '../models/property_page.dart';
import '../models/property_type.dart';
import '../models/rating_entry.dart';
import 'demo_data.dart';

/// In-memory backend used ONLY when Firebase is not configured.
///
/// Every repository branches to this store when [DemoStore.enabled] is true,
/// which makes the whole app (browse, search, favorites, comments, ratings,
/// admin panel) fully interactive for UI evaluation. Production data always
/// comes from Firebase — nothing here is shipped as a "final data source".
class DemoStore {
  DemoStore._() {
    reset();
  }

  static final DemoStore instance = DemoStore._();

  /// Set once at bootstrap when `Firebase.initializeApp()` fails.
  static bool enabled = false;

  // ------------------------------------------------------------------- state

  late List<Property> properties;
  late List<PropertyType> types;
  late List<City> cities;
  late List<Area> areas;
  late List<FeatureItem> features;
  late List<PropertyComment> comments;
  late Map<String, RatingEntry> ratings;
  late List<AppUser> users;
  late List<CommentReport> reports;
  late List<ContactMessage> messages;
  late List<AppNotification> notifications;
  late AppSettings settings;

  AppUser? currentUser;
  bool isAdminSession = false;

  final StreamController<void> _changes =
      StreamController<void>.broadcast();
  final StreamController<AppUser?> _authController =
      StreamController<AppUser?>.broadcast();

  int _seq = 1000;
  String _nextId(String prefix) =>
      '$prefix-${DateTime.now().millisecondsSinceEpoch}-${_seq++}';

  void reset() {
    properties = DemoData.properties();
    types = DemoData.types();
    cities = DemoData.cities();
    areas = DemoData.areas();
    features = DemoData.features();
    comments = DemoData.comments();
    ratings = DemoData.ratings();
    users = DemoData.users();
    reports = DemoData.reports();
    messages = DemoData.messages();
    notifications = DemoData.notifications();
    settings = DemoData.settings();
    currentUser = null;
    isAdminSession = false;
    _notify();
  }

  void _notify() {
    if (!_changes.isClosed) _changes.add(null);
  }

  Stream<T> _watch<T>(T Function() select) async* {
    yield select();
    await for (final _ in _changes.stream) {
      yield select();
    }
  }

  // -------------------------------------------------------------------- auth

  Stream<AppUser?> authStateChanges() async* {
    yield currentUser;
    yield* _authController.stream;
  }

  /// Demo login: any e-mail works. `admin@alethiopi.com` becomes the admin.
  Future<AppUser> demoSignIn({required String email, String? name}) async {
    final String clean = email.trim().isEmpty ? 'demo@example.com' : email.trim();
    final bool admin = clean.toLowerCase() == 'admin@alethiopi.com';
    AppUser? existing;
    try {
      existing = users.firstWhere(
        (AppUser u) => u.email.toLowerCase() == clean.toLowerCase(),
      );
    } catch (_) {
      existing = null;
    }
    existing ??= AppUser(
      uid: _nextId('demo-user'),
      displayName: (name ?? '').trim().isEmpty
          ? clean.split('@').first
          : name!.trim(),
      email: clean,
      createdAt: DateTime.now(),
    );
    if (!users.any((AppUser u) => u.uid == existing!.uid)) {
      users.add(existing);
    }
    currentUser = existing;
    isAdminSession = admin || existing.uid == 'demo-admin';
    _authController.add(currentUser);
    _notify();
    return existing;
  }

  Future<void> demoSignOut() async {
    currentUser = null;
    isAdminSession = false;
    _authController.add(null);
    _notify();
  }

  Future<AppUser> demoUpdateProfile({String? displayName, String? photoUrl}) {
    final AppUser? user = currentUser;
    if (user == null) throw StateError('No demo user');
    final AppUser updated = user.copyWith(
      displayName: (displayName == null || displayName.trim().isEmpty)
          ? null
          : displayName.trim(),
      photoUrl: photoUrl,
    );
    currentUser = updated;
    final int i = users.indexWhere((AppUser u) => u.uid == updated.uid);
    if (i >= 0) users[i] = updated;
    _authController.add(updated);
    _notify();
    return Future<AppUser>.value(updated);
  }

  AppUser? findUser(String uid) {
    try {
      return users.firstWhere((AppUser u) => u.uid == uid);
    } catch (_) {
      return null;
    }
  }

  // -------------------------------------------------------------- properties

  Stream<T> watchProperties<T>(T Function(List<Property> all) select) =>
      _watch(() => select(properties));

  Property? findProperty(String id) {
    try {
      return properties.firstWhere((Property p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Property> findProperties(List<String> ids) {
    final Map<String, Property> byId = <String, Property>{
      for (final Property p in properties) p.id: p,
    };
    return <Property>[
      for (final String id in ids)
        if (byId.containsKey(id) && byId[id]!.isPublished) byId[id]!,
    ];
  }

  Future<PropertyPage> fetchProperties({
    required PropertyFilter filter,
    String? startAfterId,
    int limit = 12,
  }) async {
    List<Property> all =
        properties.where((Property p) => p.isPublished).toList();

    final List<String> tokens = SearchKeywords.queryTokens(filter.query);
    if (tokens.isNotEmpty) {
      all = all.where((Property p) {
        final String haystack = SearchKeywords.normalize(
          '${p.title} ${p.cityName} ${p.areaName} ${p.typeName} ${p.address}',
        );
        return tokens.every(haystack.contains);
      }).toList();
    }
    if (filter.onlyFeatured) {
      all = all.where((Property p) => p.isFeatured).toList();
    }
    if (filter.purpose != null) {
      all = all.where((Property p) => p.purpose == filter.purpose).toList();
    }
    if (filter.typeId != null) {
      all = all.where((Property p) => p.typeId == filter.typeId).toList();
    }
    if (filter.cityId != null) {
      all = all.where((Property p) => p.cityId == filter.cityId).toList();
    }
    if (filter.areaId != null) {
      all = all.where((Property p) => p.areaId == filter.areaId).toList();
    }
    if (filter.minPrice != null) {
      all = all.where((Property p) => p.price >= filter.minPrice!).toList();
    }
    if (filter.maxPrice != null) {
      all = all.where((Property p) => p.price <= filter.maxPrice!).toList();
    }
    if (filter.minSize != null) {
      all = all.where((Property p) => p.size >= filter.minSize!).toList();
    }
    if (filter.maxSize != null) {
      all = all.where((Property p) => p.size <= filter.maxSize!).toList();
    }
    if (filter.minBedrooms != null) {
      all = all
          .where((Property p) => p.bedrooms >= filter.minBedrooms!)
          .toList();
    }
    if (filter.minBathrooms != null) {
      all = all
          .where((Property p) => p.bathrooms >= filter.minBathrooms!)
          .toList();
    }
    if (filter.status != null) {
      all = all.where((Property p) => p.status == filter.status).toList();
    }

    switch (filter.sort) {
      case PropertySort.priceAsc:
        all.sort((Property a, Property b) => a.price.compareTo(b.price));
        break;
      case PropertySort.priceDesc:
        all.sort((Property a, Property b) => b.price.compareTo(a.price));
        break;
      case PropertySort.newest:
        all.sort((Property a, Property b) =>
            (b.createdAt ?? DateTime(2000))
                .compareTo(a.createdAt ?? DateTime(2000)));
        break;
    }

    int start = 0;
    if (startAfterId != null) {
      final int idx = all.indexWhere((Property p) => p.id == startAfterId);
      if (idx >= 0) start = idx + 1;
    }
    final List<Property> page = all.skip(start).take(limit).toList();
    return PropertyPage(items: page, hasMore: start + page.length < all.length);
  }

  Future<PropertyPage> fetchAdminPage({String? startAfterId, int limit = 20}) async {
    final List<Property> all = properties.toList()
      ..sort((Property a, Property b) =>
          (b.updatedAt ?? DateTime(2000))
              .compareTo(a.updatedAt ?? DateTime(2000)));
    int start = 0;
    if (startAfterId != null) {
      final int idx = all.indexWhere((Property p) => p.id == startAfterId);
      if (idx >= 0) start = idx + 1;
    }
    final List<Property> page = all.skip(start).take(limit).toList();
    return PropertyPage(items: page, hasMore: start + page.length < all.length);
  }

  PropertyStats propertyStats() {
    return PropertyStats(
      total: properties.length,
      sale: properties.where((Property p) => p.purpose == PropertyPurpose.sale).length,
      rent: properties.where((Property p) => p.purpose == PropertyPurpose.rent).length,
      featured: properties.where((Property p) => p.isFeatured).length,
      available: properties.where((Property p) => p.status == PropertyStatus.available).length,
      sold: properties.where((Property p) => p.status == PropertyStatus.sold).length,
      rented: properties.where((Property p) => p.status == PropertyStatus.rented).length,
    );
  }

  Future<String> addProperty(Property property) async {
    final String id = _nextId('demo-p');
    final Property created = property.copyWith(
      searchKeywords: SearchKeywords.build(
        title: property.title,
        cityName: property.cityName,
        areaName: property.areaName,
        typeName: property.typeName,
        address: property.address,
        purpose: property.purpose.labelAr,
      ),
    );
    properties.insert(
      0,
      Property(
        id: id,
        title: created.title,
        description: created.description,
        purpose: created.purpose,
        typeId: created.typeId,
        typeName: created.typeName,
        cityId: created.cityId,
        cityName: created.cityName,
        areaId: created.areaId,
        areaName: created.areaName,
        address: created.address,
        price: created.price,
        currency: created.currency,
        size: created.size,
        bedrooms: created.bedrooms,
        bathrooms: created.bathrooms,
        floor: created.floor,
        status: created.status,
        isPublished: created.isPublished,
        isFeatured: created.isFeatured,
        images: created.images,
        featureIds: created.featureIds,
        featureNames: created.featureNames,
        phone: created.phone,
        whatsapp: created.whatsapp,
        ratingAvg: 0,
        ratingCount: 0,
        favoritesCount: 0,
        commentsCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: currentUser?.uid,
        searchKeywords: created.searchKeywords,
      ),
    );
    _notify();
    return id;
  }

  void updateProperty(Property property) {
    final int i = properties.indexWhere((Property p) => p.id == property.id);
    if (i < 0) return;
    final Property prev = properties[i];
    properties[i] = property.copyWith(
      ratingAvg: prev.ratingAvg,
      ratingCount: prev.ratingCount,
      favoritesCount: prev.favoritesCount,
      commentsCount: prev.commentsCount,
    );
    _notify();
  }

  void patchProperty(String id, Map<String, dynamic> patch) {
    final Property? p = findProperty(id);
    if (p == null) return;
    Property next = p;
    if (patch.containsKey('isPublished')) {
      next = next.copyWith(isPublished: patch['isPublished'] as bool);
    }
    if (patch.containsKey('isFeatured')) {
      next = next.copyWith(isFeatured: patch['isFeatured'] as bool);
    }
    if (patch.containsKey('status')) {
      next = next.copyWith(
        status: PropertyStatusX.fromValue(patch['status'] as String?),
      );
    }
    updateProperty(next);
  }

  void deleteProperty(String id) {
    properties.removeWhere((Property p) => p.id == id);
    comments.removeWhere((PropertyComment c) => c.propertyId == id);
    ratings.removeWhere((String key, RatingEntry r) => r.propertyId == id);
    _notify();
  }

  // ---------------------------------------------------------------- lookups

  Stream<T> watchLookups<T>(T Function() select) => _watch(select);

  Future<String> addType(PropertyType type) async {
    final String id = _nextId('type');
    types.add(PropertyType(id: id, name: type.name, icon: type.icon, order: type.order, isActive: type.isActive));
    _notify();
    return id;
  }

  void updateType(PropertyType type) {
    final int i = types.indexWhere((PropertyType t) => t.id == type.id);
    if (i >= 0) types[i] = type;
    _notify();
  }

  void deleteType(String id) {
    types.removeWhere((PropertyType t) => t.id == id);
    _notify();
  }

  Future<String> addCity(City city) async {
    final String id = _nextId('city');
    cities.add(City(id: id, name: city.name, order: city.order, isActive: city.isActive));
    _notify();
    return id;
  }

  void updateCity(City city) {
    final int i = cities.indexWhere((City c) => c.id == city.id);
    if (i >= 0) cities[i] = city;
    _notify();
  }

  void deleteCity(String id) {
    cities.removeWhere((City c) => c.id == id);
    _notify();
  }

  Future<String> addArea(Area area) async {
    final String id = _nextId('area');
    areas.add(Area(id: id, name: area.name, cityId: area.cityId, order: area.order, isActive: area.isActive));
    _notify();
    return id;
  }

  void updateArea(Area area) {
    final int i = areas.indexWhere((Area a) => a.id == area.id);
    if (i >= 0) areas[i] = area;
    _notify();
  }

  void deleteArea(String id) {
    areas.removeWhere((Area a) => a.id == id);
    _notify();
  }

  Future<String> addFeature(FeatureItem feature) async {
    final String id = _nextId('feat');
    features.add(FeatureItem(id: id, name: feature.name, icon: feature.icon, order: feature.order, isActive: feature.isActive));
    _notify();
    return id;
  }

  void updateFeature(FeatureItem feature) {
    final int i = features.indexWhere((FeatureItem f) => f.id == feature.id);
    if (i >= 0) features[i] = feature;
    _notify();
  }

  void deleteFeature(String id) {
    features.removeWhere((FeatureItem f) => f.id == id);
    _notify();
  }

  // ---------------------------------------------------------------- comments

  Stream<T> watchComments<T>(T Function(List<PropertyComment> all) select) =>
      _watch(() => select(comments));

  Future<String> addComment(PropertyComment comment) async {
    final String id = _nextId('demo-c');
    comments.insert(
      0,
      PropertyComment(
        id: id,
        propertyId: comment.propertyId,
        userId: comment.userId,
        userName: comment.userName,
        userPhotoUrl: comment.userPhotoUrl,
        text: comment.text,
        rating: comment.rating,
        createdAt: DateTime.now(),
      ),
    );
    _incrementCommentsCount(comment.propertyId, 1);
    _notify();
    return id;
  }

  void updateComment(PropertyComment comment) {
    final int i = comments.indexWhere((PropertyComment c) => c.id == comment.id);
    if (i >= 0) comments[i] = comment;
    _notify();
  }

  void deleteComment(String id) {
    PropertyComment? removed;
    try {
      removed = comments.firstWhere((PropertyComment c) => c.id == id);
    } catch (_) {
      removed = null;
    }
    comments.removeWhere((PropertyComment c) => c.id == id);
    if (removed != null) _incrementCommentsCount(removed.propertyId, -1);
    _notify();
  }

  void setCommentHidden(String id, bool hidden) {
    final int i = comments.indexWhere((PropertyComment c) => c.id == id);
    if (i >= 0) comments[i] = comments[i].copyWith(isHidden: hidden);
    _notify();
  }

  void toggleCommentLike(String commentId, String uid) {
    final int i = comments.indexWhere((PropertyComment c) => c.id == commentId);
    if (i < 0) return;
    final List<String> liked = comments[i].likedBy.toList();
    if (liked.contains(uid)) {
      liked.remove(uid);
    } else {
      liked.add(uid);
    }
    comments[i] = comments[i].copyWith(likedBy: liked);
    _notify();
  }

  void _incrementCommentsCount(String propertyId, int delta) {
    final Property? p = findProperty(propertyId);
    if (p == null) return;
    final int i = properties.indexWhere((Property e) => e.id == propertyId);
    properties[i] = p.copyWith(
      commentsCount: (p.commentsCount + delta).clamp(0, 1 << 30),
    );
  }

  // ----------------------------------------------------------------- ratings

  Stream<T> watchRatings<T>(T Function() select) => _watch(select);

  RatingEntry? findRating(String propertyId, String uid) =>
      ratings[RatingEntry.docId(propertyId, uid)];

  void submitRating({
    required String propertyId,
    required String uid,
    required int value,
  }) {
    final String id = RatingEntry.docId(propertyId, uid);
    ratings[id] = RatingEntry(
      id: id,
      propertyId: propertyId,
      userId: uid,
      value: value,
      createdAt: ratings[id]?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
    // Recompute aggregates (Cloud Functions do this in production).
    final List<RatingEntry> all = ratings.values
        .where((RatingEntry r) => r.propertyId == propertyId)
        .toList();
    final double avg = all.isEmpty
        ? 0
        : all.map((RatingEntry r) => r.value).reduce((int a, int b) => a + b) /
            all.length;
    final Property? p = findProperty(propertyId);
    if (p != null) {
      final int i = properties.indexWhere((Property e) => e.id == propertyId);
      properties[i] = p.copyWith(ratingAvg: avg, ratingCount: all.length);
    }
    _notify();
  }

  // ----------------------------------------------------------------- reports

  Stream<T> watchReports<T>(T Function() select) => _watch(select);

  Future<String> fileReport(CommentReport report) async {
    final String id = _nextId('demo-r');
    reports.insert(
      0,
      CommentReport(
        id: id,
        commentId: report.commentId,
        propertyId: report.propertyId,
        reporterId: report.reporterId,
        reason: report.reason,
        details: report.details,
        commentText: report.commentText,
        status: 'pending',
        createdAt: DateTime.now(),
      ),
    );
    _notify();
    return id;
  }

  void setReportStatus(String id, String status) {
    final int i = reports.indexWhere((CommentReport r) => r.id == id);
    if (i < 0) return;
    final CommentReport r = reports[i];
    reports[i] = CommentReport(
      id: r.id,
      commentId: r.commentId,
      propertyId: r.propertyId,
      reporterId: r.reporterId,
      reason: r.reason,
      details: r.details,
      commentText: r.commentText,
      status: status,
      createdAt: r.createdAt,
    );
    _notify();
  }

  void deleteReport(String id) {
    reports.removeWhere((CommentReport r) => r.id == id);
    _notify();
  }

  // ---------------------------------------------------------------- messages

  Stream<T> watchMessages<T>(T Function() select) => _watch(select);

  Future<String> sendMessage(ContactMessage message) async {
    final String id = _nextId('demo-m');
    messages.insert(
      0,
      ContactMessage(
        id: id,
        name: message.name,
        phone: message.phone,
        message: message.message,
        userId: message.userId,
        createdAt: DateTime.now(),
      ),
    );
    _notify();
    return id;
  }

  void markMessageRead(String id) {
    final int i = messages.indexWhere((ContactMessage m) => m.id == id);
    if (i < 0) return;
    final ContactMessage m = messages[i];
    messages[i] = ContactMessage(
      id: m.id,
      name: m.name,
      phone: m.phone,
      message: m.message,
      userId: m.userId,
      isRead: true,
      createdAt: m.createdAt,
    );
    _notify();
  }

  void deleteMessage(String id) {
    messages.removeWhere((ContactMessage m) => m.id == id);
    _notify();
  }

  // ---------------------------------------------------------------- settings

  Stream<T> watchSettings<T>(T Function() select) => _watch(select);

  void saveSettings(AppSettings value) {
    settings = value;
    _notify();
  }

  // ----------------------------------------------------------- notifications

  Stream<T> watchNotifications<T>(T Function() select) => _watch(select);

  Future<String> sendNotification(AppNotification notification) async {
    final String id = _nextId('demo-n');
    notifications.insert(
      0,
      AppNotification(
        id: id,
        title: notification.title,
        body: notification.body,
        type: notification.type,
        propertyId: notification.propertyId,
        imageUrl: notification.imageUrl,
        createdAt: DateTime.now(),
      ),
    );
    _notify();
    return id;
  }

  void deleteNotification(String id) {
    notifications.removeWhere((AppNotification n) => n.id == id);
    _notify();
  }
}
