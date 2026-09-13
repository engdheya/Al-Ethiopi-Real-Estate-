import 'package:equatable/equatable.dart';

import 'property.dart';

enum PropertySort { newest, priceAsc, priceDesc }

extension PropertySortX on PropertySort {
  String get labelAr {
    switch (this) {
      case PropertySort.newest:
        return 'الأحدث';
      case PropertySort.priceAsc:
        return 'السعر: من الأقل';
      case PropertySort.priceDesc:
        return 'السعر: من الأعلى';
    }
  }
}

/// Immutable search/filter state shared by list, search and home shortcuts.
class PropertyFilter extends Equatable {
  const PropertyFilter({
    this.query = '',
    this.purpose,
    this.typeId,
    this.cityId,
    this.areaId,
    this.minPrice,
    this.maxPrice,
    this.minSize,
    this.maxSize,
    this.minBedrooms,
    this.minBathrooms,
    this.status,
    this.sort = PropertySort.newest,
    this.onlyFeatured = false,
  });

  final String query;
  final PropertyPurpose? purpose;
  final String? typeId;
  final String? cityId;
  final String? areaId;
  final double? minPrice;
  final double? maxPrice;
  final double? minSize;
  final double? maxSize;
  final int? minBedrooms;
  final int? minBathrooms;
  final PropertyStatus? status;
  final PropertySort sort;
  final bool onlyFeatured;

  bool get hasActiveFilters =>
      query.trim().isNotEmpty ||
      purpose != null ||
      typeId != null ||
      cityId != null ||
      areaId != null ||
      minPrice != null ||
      maxPrice != null ||
      minSize != null ||
      maxSize != null ||
      minBedrooms != null ||
      minBathrooms != null ||
      status != null ||
      onlyFeatured;

  int get activeFilterCount {
    int count = 0;
    if (query.trim().isNotEmpty) count++;
    if (purpose != null) count++;
    if (typeId != null) count++;
    if (cityId != null) count++;
    if (areaId != null) count++;
    if (minPrice != null || maxPrice != null) count++;
    if (minSize != null || maxSize != null) count++;
    if (minBedrooms != null) count++;
    if (minBathrooms != null) count++;
    if (status != null) count++;
    if (onlyFeatured) count++;
    return count;
  }

  PropertyFilter copyWith({
    String? query,
    PropertyPurpose? Function()? purpose,
    String? Function()? typeId,
    String? Function()? cityId,
    String? Function()? areaId,
    double? Function()? minPrice,
    double? Function()? maxPrice,
    double? Function()? minSize,
    double? Function()? maxSize,
    int? Function()? minBedrooms,
    int? Function()? minBathrooms,
    PropertyStatus? Function()? status,
    PropertySort? sort,
    bool? onlyFeatured,
  }) {
    return PropertyFilter(
      query: query ?? this.query,
      purpose: purpose != null ? purpose() : this.purpose,
      typeId: typeId != null ? typeId() : this.typeId,
      cityId: cityId != null ? cityId() : this.cityId,
      areaId: areaId != null ? areaId() : this.areaId,
      minPrice: minPrice != null ? minPrice() : this.minPrice,
      maxPrice: maxPrice != null ? maxPrice() : this.maxPrice,
      minSize: minSize != null ? minSize() : this.minSize,
      maxSize: maxSize != null ? maxSize() : this.maxSize,
      minBedrooms: minBedrooms != null ? minBedrooms() : this.minBedrooms,
      minBathrooms: minBathrooms != null ? minBathrooms() : this.minBathrooms,
      status: status != null ? status() : this.status,
      sort: sort ?? this.sort,
      onlyFeatured: onlyFeatured ?? this.onlyFeatured,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        query,
        purpose,
        typeId,
        cityId,
        areaId,
        minPrice,
        maxPrice,
        minSize,
        maxSize,
        minBedrooms,
        minBathrooms,
        status,
        sort,
        onlyFeatured,
      ];
}
