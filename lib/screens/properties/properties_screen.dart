import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/formatters.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_skeleton.dart';
import '../../core/widgets/property_card.dart';
import '../../l10n/app_strings.dart';
import '../../models/property_filter.dart';
import '../../providers/filter_provider.dart';
import '../../providers/lookup_providers.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../filters/filter_bottom_sheet.dart';

/// Properties tab: paginated list + active-filter chips + filter sheet.
class PropertiesTab extends ConsumerStatefulWidget {
  const PropertiesTab({super.key});

  @override
  ConsumerState<PropertiesTab> createState() => _PropertiesTabState();
}

class _PropertiesTabState extends ConsumerState<PropertiesTab> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels >=
          _scroll.position.maxScrollExtent - 320) {
        ref.read(paginatedPropertiesProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final PropertyListState listState =
        ref.watch(paginatedPropertiesProvider);
    final PropertyFilter filter = ref.watch(propertyFilterProvider);

    return Column(
      children: <Widget>[
        _TabHeader(filter: filter),
        if (filter.hasActiveFilters) _ActiveChips(filter: filter),
        Expanded(child: _buildBody(listState)),
      ],
    );
  }

  Widget _buildBody(PropertyListState state) {
    if (state.isLoading) return const SkeletonList(count: 3);
    if (state.error != null && state.items.isEmpty) {
      return ErrorState(
        message: state.error!,
        onRetry: () =>
            ref.read(paginatedPropertiesProvider.notifier).refresh(),
      );
    }
    if (state.items.isEmpty) {
      return EmptyState(
        icon: Icons.search_off_outlined,
        title: AppStrings.noResults,
        subtitle: AppStrings.noResultsHint,
        actionLabel: AppStrings.clearFilters,
        onAction: () =>
            ref.read(propertyFilterProvider.notifier).clear(),
      );
    }
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(paginatedPropertiesProvider.notifier).refresh(),
      child: ListView.separated(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: state.items.length + (state.hasMore ? 1 : 0),
        separatorBuilder: (BuildContext context, int _) =>
            const SizedBox(height: 12),
        itemBuilder: (BuildContext context, int i) {
          if (i >= state.items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final property = state.items[i];
          return PropertyCard(
            property: property,
            onTap: () => AppRoutes.openProperty(context, property.id),
          );
        },
      ),
    );
  }
}

class _TabHeader extends ConsumerWidget {
  const _TabHeader({required this.filter});

  final PropertyFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int count = filter.activeFilterCount;
    return Container(
      color: AppColors.primary,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: <Widget>[
          const Expanded(
            child: Text(
              AppStrings.navProperties,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          InkWell(
            onTap: () =>
                Navigator.of(context).pushNamed(AppRoutes.search),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.search, color: Colors.white),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => showFilterSheet(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Badge(
                isLabelVisible: count > 0,
                label: Text(
                  Formatters.toArabicDigits(count.toString()),
                ),
                child: const Icon(
                  Icons.tune,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveChips extends ConsumerWidget {
  const _ActiveChips({required this.filter});

  final PropertyFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(propertyFilterProvider.notifier);
    final Map<String, String> typeNames =
        ref.watch(propertyTypeNameProvider);
    final Map<String, String> cityNames = ref.watch(cityNameProvider);

    final List<_Chip> chips = <_Chip>[];
    if (filter.query.trim().isNotEmpty) {
      chips.add(_Chip(
        label: '«${filter.query.trim()}»',
        onDelete: () => notifier.set(filter.copyWith(query: '')),
      ));
    }
    if (filter.purpose != null) {
      chips.add(_Chip(
        label: filter.purpose!.labelAr,
        onDelete: () => notifier.set(filter.copyWith(purpose: () => null)),
      ));
    }
    if (filter.typeId != null) {
      chips.add(_Chip(
        label: typeNames[filter.typeId] ?? AppStrings.propertyType,
        onDelete: () =>
            notifier.set(filter.copyWith(typeId: () => null)),
      ));
    }
    if (filter.cityId != null) {
      chips.add(_Chip(
        label: cityNames[filter.cityId] ?? AppStrings.city,
        onDelete: () => notifier.set(filter.copyWith(
          cityId: () => null,
          areaId: () => null,
        )),
      ));
    }
    if (filter.minPrice != null || filter.maxPrice != null) {
      chips.add(_Chip(
        label: AppStrings.price,
        onDelete: () => notifier.set(filter.copyWith(
          minPrice: () => null,
          maxPrice: () => null,
        )),
      ));
    }
    if (filter.minSize != null || filter.maxSize != null) {
      chips.add(_Chip(
        label: AppStrings.size,
        onDelete: () => notifier.set(filter.copyWith(
          minSize: () => null,
          maxSize: () => null,
        )),
      ));
    }
    if (filter.minBedrooms != null) {
      chips.add(_Chip(
        label:
            '${AppStrings.bedrooms}: ${Formatters.toArabicDigits(filter.minBedrooms.toString())}+',
        onDelete: () =>
            notifier.set(filter.copyWith(minBedrooms: () => null)),
      ));
    }
    if (filter.status != null) {
      chips.add(_Chip(
        label: filter.status!.labelAr,
        onDelete: () =>
            notifier.set(filter.copyWith(status: () => null)),
      ));
    }
    if (filter.onlyFeatured) {
      chips.add(_Chip(
        label: AppStrings.featured,
        onDelete: () =>
            notifier.set(filter.copyWith(onlyFeatured: false)),
      ));
    }

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length + 1,
        separatorBuilder: (BuildContext context, int _) =>
            const SizedBox(width: 8),
        itemBuilder: (BuildContext context, int i) {
          if (i == 0) {
            return ActionChip(
              label: const Text(AppStrings.clearFilters),
              onPressed: () => notifier.clear(),
            );
          }
          final _Chip chip = chips[i - 1];
          return Chip(
            label: Text(chip.label),
            deleteIcon: const Icon(Icons.close, size: 16),
            onDeleted: chip.onDelete,
          );
        },
      ),
    );
  }
}

class _Chip {
  const _Chip({required this.label, required this.onDelete});

  final String label;
  final VoidCallback onDelete;
}
