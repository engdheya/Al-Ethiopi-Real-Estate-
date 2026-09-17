import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../core/errors/app_failure.dart';
import '../firebase/firebase_providers.dart';
import '../models/property.dart';
import '../models/property_filter.dart';
import '../models/property_page.dart';

// ------------------------------------------------------------------- filter

class PropertyFilterNotifier extends Notifier<PropertyFilter> {
  @override
  PropertyFilter build() => const PropertyFilter();

  void set(PropertyFilter filter) {
    state = filter;
  }

  void clear() {
    state = const PropertyFilter();
  }

  void setQuery(String query) {
    state = state.copyWith(query: query);
  }
}

final NotifierProvider<PropertyFilterNotifier, PropertyFilter>
    propertyFilterProvider =
    NotifierProvider<PropertyFilterNotifier, PropertyFilter>(
  PropertyFilterNotifier.new,
);

// ------------------------------------------------------------- paginated list

class PropertyListState extends Equatable {
  const PropertyListState({
    this.items = const <Property>[],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  final List<Property> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;

  PropertyListState copyWith({
    List<Property>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    bool clearError = false,
  }) {
    return PropertyListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        items,
        isLoading,
        isLoadingMore,
        hasMore,
        error,
      ];
}

class PaginatedProperties extends Notifier<PropertyListState> {
  DocumentSnapshot<Map<String, dynamic>>? _cursor;
  String? _demoCursor;
  bool _fetching = false;

  @override
  PropertyListState build() {
    ref.listen<PropertyFilter>(propertyFilterProvider, (
      PropertyFilter? previous,
      PropertyFilter next,
    ) {
      if (previous != next) refresh();
    });
    Future<void>.microtask(refresh);
    return const PropertyListState();
  }

  PropertyFilter get _filter => ref.read(propertyFilterProvider);

  Future<void> refresh() async {
    if (_fetching) return;
    _fetching = true;
    _cursor = null;
    _demoCursor = null;
    state = state.copyWith(
      isLoading: true,
      hasMore: true,
      items: const <Property>[],
      clearError: true,
    );
    try {
      final PropertyPage page = await ref
          .read(propertyRepositoryProvider)
          .fetchProperties(
            filter: _filter,
            limit: AppConstants.propertiesPageSize,
          );
      _cursor = page.lastDoc;
      _demoCursor = page.lastId;
      state = state.copyWith(
        items: page.items,
        isLoading: false,
        hasMore: page.hasMore,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: friendlyErrorMessage(e),
      );
    } finally {
      _fetching = false;
    }
  }

  Future<void> loadMore() async {
    if (_fetching || state.isLoading || state.isLoadingMore || !state.hasMore) {
      return;
    }
    _fetching = true;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    try {
      final PropertyPage page = await ref
          .read(propertyRepositoryProvider)
          .fetchProperties(
            filter: _filter,
            startAfter: _cursor,
            startAfterId: _demoCursor,
            limit: AppConstants.propertiesPageSize,
          );
      _cursor = page.lastDoc ?? _cursor;
      _demoCursor = page.lastId ?? _demoCursor;
      state = state.copyWith(
        items: <Property>[...state.items, ...page.items],
        isLoadingMore: false,
        hasMore: page.hasMore,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: friendlyErrorMessage(e),
      );
    } finally {
      _fetching = false;
    }
  }
}

final NotifierProvider<PaginatedProperties, PropertyListState>
    paginatedPropertiesProvider =
    NotifierProvider<PaginatedProperties, PropertyListState>(
  PaginatedProperties.new,
);
