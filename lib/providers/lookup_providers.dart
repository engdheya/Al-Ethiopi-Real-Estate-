import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase/firebase_providers.dart';
import '../models/area.dart';
import '../models/city.dart';
import '../models/feature_item.dart';
import '../models/property_type.dart';

// ------------------------------------------------------------- public (active)

final StreamProvider<List<PropertyType>> propertyTypesProvider =
    StreamProvider<List<PropertyType>>((Ref ref) {
  return ref.watch(lookupRepositoryProvider).watchTypes();
});

final StreamProvider<List<City>> citiesProvider =
    StreamProvider<List<City>>((Ref ref) {
  return ref.watch(lookupRepositoryProvider).watchCities();
});

final StreamProvider<List<FeatureItem>> featuresProvider =
    StreamProvider<List<FeatureItem>>((Ref ref) {
  return ref.watch(lookupRepositoryProvider).watchFeatures();
});

final StreamProviderFamily<List<Area>, String> areasProvider =
    StreamProviderFamily<List<Area>, String>((Ref ref, String cityId) {
  if (cityId.isEmpty) return Stream<List<Area>>.value(const <Area>[]);
  return ref.watch(lookupRepositoryProvider).watchAreas(cityId);
});

// ------------------------------------------------------------------ id maps

final Provider<Map<String, String>> propertyTypeNameProvider =
    Provider<Map<String, String>>((Ref ref) {
  final List<PropertyType> types =
      ref.watch(propertyTypesProvider).valueOrNull ?? const <PropertyType>[];
  return <String, String>{for (final PropertyType t in types) t.id: t.name};
});

final Provider<Map<String, String>> cityNameProvider =
    Provider<Map<String, String>>((Ref ref) {
  final List<City> cities =
      ref.watch(citiesProvider).valueOrNull ?? const <City>[];
  return <String, String>{for (final City c in cities) c.id: c.name};
});

// -------------------------------------------------------------------- admin

final StreamProvider<List<PropertyType>> adminTypesProvider =
    StreamProvider<List<PropertyType>>((Ref ref) {
  return ref.watch(lookupRepositoryProvider).watchTypes(activeOnly: false);
});

final StreamProvider<List<City>> adminCitiesProvider =
    StreamProvider<List<City>>((Ref ref) {
  return ref.watch(lookupRepositoryProvider).watchCities(activeOnly: false);
});

final StreamProvider<List<Area>> adminAreasProvider =
    StreamProvider<List<Area>>((Ref ref) {
  return ref.watch(lookupRepositoryProvider).watchAllAreas();
});

final StreamProvider<List<FeatureItem>> adminFeaturesProvider =
    StreamProvider<List<FeatureItem>>((Ref ref) {
  return ref.watch(lookupRepositoryProvider).watchFeatures(activeOnly: false);
});
