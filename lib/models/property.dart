import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

import '../l10n/app_strings.dart';

/// Sale or rent.
enum PropertyPurpose { sale, rent }

extension PropertyPurposeX on PropertyPurpose {
  String get value => this == PropertyPurpose.sale ? 'sale' : 'rent';

  String get labelAr =>
      this == PropertyPurpose.sale ? AppStrings.sale : AppStrings.rent;

  static PropertyPurpose fromValue(String? value) =>
      value == 'rent' ? PropertyPurpose.rent : PropertyPurpose.sale;
}

/// Listing lifecycle status.
enum PropertyStatus { available, rented, sold, unavailable }

extension PropertyStatusX on PropertyStatus {
  String get value {
    switch (this) {
      case PropertyStatus.available:
        return 'available';
      case PropertyStatus.rented:
        return 'rented';
      case PropertyStatus.sold:
        return 'sold';
      case PropertyStatus.unavailable:
        return 'unavailable';
    }
  }

  String get labelAr {
    switch (this) {
      case PropertyStatus.available:
        return AppStrings.statusAvailable;
      case PropertyStatus.rented:
        return AppStrings.statusRented;
      case PropertyStatus.sold:
        return AppStrings.statusSold;
      case PropertyStatus.unavailable:
        return AppStrings.statusUnavailable;
    }
  }

  static PropertyStatus fromValue(String? value) {
    switch (value) {
      case 'rented':
        return PropertyStatus.rented;
      case 'sold':
        return PropertyStatus.sold;
      case 'unavailable':
        return PropertyStatus.unavailable;
      case 'available':
      default:
        return PropertyStatus.available;
    }
  }
}

/// One gallery photo (metadata in Firestore, bytes in Firebase Storage).
class PropertyImage extends Equatable {
  const PropertyImage({
    required this.url,
    required this.path,
    this.isMain = false,
    this.order = 0,
  });

  final String url;
  final String path;
  final bool isMain;
  final int order;

  factory PropertyImage.fromMap(Map<String, dynamic> map) {
    return PropertyImage(
      url: map['url'] as String? ?? '',
      path: map['path'] as String? ?? '',
      isMain: map['isMain'] as bool? ?? false,
      order: (map['order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'url': url,
      'path': path,
      'isMain': isMain,
      'order': order,
    };
  }

  PropertyImage copyWith({String? url, String? path, bool? isMain, int? order}) {
    return PropertyImage(
      url: url ?? this.url,
      path: path ?? this.path,
      isMain: isMain ?? this.isMain,
      order: order ?? this.order,
    );
  }

  @override
  List<Object?> get props => <Object?>[url, path, isMain, order];
}

/// Firestore `properties/{id}` document.
class Property extends Equatable {
  const Property({
    required this.id,
    required this.title,
    required this.description,
    required this.purpose,
    required this.typeId,
    required this.typeName,
    required this.cityId,
    required this.cityName,
    required this.areaId,
    required this.areaName,
    required this.address,
    required this.price,
    required this.currency,
    required this.size,
    required this.bedrooms,
    required this.bathrooms,
    required this.status,
    required this.isPublished,
    required this.isFeatured,
    required this.images,
    required this.featureIds,
    required this.featureNames,
    required this.phone,
    required this.whatsapp,
    required this.ratingAvg,
    required this.ratingCount,
    required this.favoritesCount,
    required this.commentsCount,
    this.floor,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.searchKeywords = const <String>[],
  });

  final String id;
  final String title;
  final String description;
  final PropertyPurpose purpose;
  final String typeId;
  final String typeName;
  final String cityId;
  final String cityName;
  final String areaId;
  final String areaName;
  final String address;
  final double price;
  final String currency;
  final double size;
  final int bedrooms;
  final int bathrooms;
  final int? floor;
  final PropertyStatus status;
  final bool isPublished;
  final bool isFeatured;
  final List<PropertyImage> images;
  final List<String> featureIds;
  final List<String> featureNames;
  final String phone;
  final String whatsapp;
  final double ratingAvg;
  final int ratingCount;
  final int favoritesCount;
  final int commentsCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final List<String> searchKeywords;

  /// Main gallery photo (falls back to the first photo).
  PropertyImage? get mainImage {
    if (images.isEmpty) return null;
    for (final PropertyImage img in images) {
      if (img.isMain) return img;
    }
    return images.first;
  }

  String get locationLabel => '$cityName - $areaName';

  bool get isSoldOrRented =>
      status == PropertyStatus.sold || status == PropertyStatus.rented;

  static DateTime? _toDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }

  static List<PropertyImage> _toImages(dynamic value) {
    if (value is! List) return const <PropertyImage>[];
    final List<PropertyImage> list = value
        .whereType<Map<String, dynamic>>()
        .map(PropertyImage.fromMap)
        .toList()
      ..sort((PropertyImage a, PropertyImage b) => a.order.compareTo(b.order));
    return list;
  }

  static List<String> _toStringList(dynamic value) {
    if (value is! List) return const <String>[];
    return value.map((dynamic e) => e.toString()).toList();
  }

  factory Property.fromMap(String id, Map<String, dynamic> map) {
    return Property(
      id: id,
      title: (map['title'] as String? ?? '').trim(),
      description: (map['description'] as String? ?? '').trim(),
      purpose: PropertyPurposeX.fromValue(map['purpose'] as String?),
      typeId: map['typeId'] as String? ?? '',
      typeName: (map['typeName'] as String? ?? '').trim(),
      cityId: map['cityId'] as String? ?? '',
      cityName: (map['cityName'] as String? ?? '').trim(),
      areaId: map['areaId'] as String? ?? '',
      areaName: (map['areaName'] as String? ?? '').trim(),
      address: (map['address'] as String? ?? '').trim(),
      price: ((map['price'] as num?) ?? 0).toDouble(),
      currency: map['currency'] as String? ?? 'YER',
      size: ((map['size'] as num?) ?? 0).toDouble(),
      bedrooms: ((map['bedrooms'] as num?) ?? 0).toInt(),
      bathrooms: ((map['bathrooms'] as num?) ?? 0).toInt(),
      floor: (map['floor'] as num?)?.toInt(),
      status: PropertyStatusX.fromValue(map['status'] as String?),
      isPublished: map['isPublished'] as bool? ?? false,
      isFeatured: map['isFeatured'] as bool? ?? false,
      images: _toImages(map['images']),
      featureIds: _toStringList(map['featureIds']),
      featureNames: _toStringList(map['featureNames']),
      phone: (map['phone'] as String? ?? '').trim(),
      whatsapp: (map['whatsapp'] as String? ?? '').trim(),
      ratingAvg: ((map['ratingAvg'] as num?) ?? 0).toDouble(),
      ratingCount: ((map['ratingCount'] as num?) ?? 0).toInt(),
      favoritesCount: ((map['favoritesCount'] as num?) ?? 0).toInt(),
      commentsCount: ((map['commentsCount'] as num?) ?? 0).toInt(),
      createdAt: _toDate(map['createdAt']),
      updatedAt: _toDate(map['updatedAt']),
      createdBy: map['createdBy'] as String?,
      searchKeywords: _toStringList(map['searchKeywords']),
    );
  }

  Map<String, dynamic> toMap({bool forCreate = false}) {
    final Map<String, dynamic> map = <String, dynamic>{
      'title': title,
      'description': description,
      'purpose': purpose.value,
      'typeId': typeId,
      'typeName': typeName,
      'cityId': cityId,
      'cityName': cityName,
      'areaId': areaId,
      'areaName': areaName,
      'address': address,
      'price': price,
      'currency': currency,
      'size': size,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'floor': floor,
      'status': status.value,
      'isPublished': isPublished,
      'isFeatured': isFeatured,
      'images': images.map((PropertyImage e) => e.toMap()).toList(),
      'featureIds': featureIds,
      'featureNames': featureNames,
      'phone': phone,
      'whatsapp': whatsapp,
      'ratingAvg': ratingAvg,
      'ratingCount': ratingCount,
      'favoritesCount': favoritesCount,
      'commentsCount': commentsCount,
      'updatedAt': FieldValue.serverTimestamp(),
      'searchKeywords': searchKeywords,
    };
    if (forCreate) {
      map['createdAt'] = FieldValue.serverTimestamp();
      map['createdBy'] = createdBy;
    }
    return map;
  }

  Property copyWith({
    String? title,
    String? description,
    PropertyPurpose? purpose,
    String? typeId,
    String? typeName,
    String? cityId,
    String? cityName,
    String? areaId,
    String? areaName,
    String? address,
    double? price,
    String? currency,
    double? size,
    int? bedrooms,
    int? bathrooms,
    int? floor,
    PropertyStatus? status,
    bool? isPublished,
    bool? isFeatured,
    List<PropertyImage>? images,
    List<String>? featureIds,
    List<String>? featureNames,
    String? phone,
    String? whatsapp,
    double? ratingAvg,
    int? ratingCount,
    int? favoritesCount,
    int? commentsCount,
    List<String>? searchKeywords,
  }) {
    return Property(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      purpose: purpose ?? this.purpose,
      typeId: typeId ?? this.typeId,
      typeName: typeName ?? this.typeName,
      cityId: cityId ?? this.cityId,
      cityName: cityName ?? this.cityName,
      areaId: areaId ?? this.areaId,
      areaName: areaName ?? this.areaName,
      address: address ?? this.address,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      size: size ?? this.size,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      floor: floor ?? this.floor,
      status: status ?? this.status,
      isPublished: isPublished ?? this.isPublished,
      isFeatured: isFeatured ?? this.isFeatured,
      images: images ?? this.images,
      featureIds: featureIds ?? this.featureIds,
      featureNames: featureNames ?? this.featureNames,
      phone: phone ?? this.phone,
      whatsapp: whatsapp ?? this.whatsapp,
      ratingAvg: ratingAvg ?? this.ratingAvg,
      ratingCount: ratingCount ?? this.ratingCount,
      favoritesCount: favoritesCount ?? this.favoritesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
      createdBy: createdBy,
      searchKeywords: searchKeywords ?? this.searchKeywords,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        id,
        title,
        purpose,
        typeId,
        cityId,
        areaId,
        price,
        currency,
        size,
        bedrooms,
        bathrooms,
        status,
        isPublished,
        isFeatured,
        images,
        ratingAvg,
        ratingCount,
      ];
}
