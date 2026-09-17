import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase/firebase_providers.dart';
import '../models/property.dart';
import '../models/property_filter.dart';
import '../models/property_page.dart';
import '../models/property_type.dart';
import 'favorite_providers.dart';
import 'lookup_providers.dart';

/// Home page sections.
final StreamProvider<List<Property>> featuredPropertiesProvider =
    StreamProvider<List<Property>>((Ref ref) {
  return ref.watch(propertyRepositoryProvider).watchFeatured(limit: 8);
});

final StreamProvider<List<Property>> latestPropertiesProvider =
    StreamProvider<List<Property>>((Ref ref) {
  return ref.watch(propertyRepositoryProvider).watchLatest(limit: 10);
});

final StreamProvider<List<Property>> rentPropertiesProvider =
    StreamProvider<List<Property>>((Ref ref) {
  return ref
      .watch(propertyRepositoryProvider)
      .watchByPurpose(PropertyPurpose.rent, limit: 8);
});

/// "Lands for sale" home section (resolves the land type id from the catalog).
final FutureProvider<List<Property>> landsForSaleProvider =
    FutureProvider<List<Property>>((Ref ref) async {
  final List<PropertyType> types =
      ref.watch(propertyTypesProvider).valueOrNull ?? const <PropertyType>[];
  String? landId;
  for (final PropertyType t in types) {
    if (t.name.contains('أرض')) {
      landId = t.id;
      break;
    }
  }
  final PropertyPage page = await ref
      .watch(propertyRepositoryProvider)
      .fetchProperties(
        filter: PropertyFilter(purpose: PropertyPurpose.sale, typeId: landId),
        limit: 8,
      );
  // When the catalog has no land type yet, fall back to any sale properties.
  if (page.items.isEmpty && landId != null) return page.items;
  return page.items;
});

/// Property details (live).
final StreamProviderFamily<Property?, String> propertyDetailsProvider =
    StreamProviderFamily<Property?, String>((Ref ref, String id) {
  return ref.watch(propertyRepositoryProvider).watchProperty(id);
});

/// Favorite properties resolved to full documents, in favorites order.
final FutureProvider<List<Property>> favoritePropertiesProvider =
    FutureProvider<List<Property>>((Ref ref) async {
  final Set<String> ids =
      ref.watch(favoriteIdsProvider).valueOrNull ?? <String>{};
  if (ids.isEmpty) return const <Property>[];
  // Re-resolve whenever the ids change.
  ref.watch(favoriteIdsProvider);
  return ref
      .watch(propertyRepositoryProvider)
      .fetchByIds(ids.toList());
});
