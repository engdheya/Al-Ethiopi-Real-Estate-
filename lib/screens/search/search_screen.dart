import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_skeleton.dart';
import '../../core/widgets/offline_banner.dart';
import '../../core/widgets/property_card.dart';
import '../../l10n/app_strings.dart';
import '../../models/property_filter.dart';
import '../../providers/filter_provider.dart';
import '../../routes/app_routes.dart';
import '../../services/cache_service.dart';
import '../../theme/app_colors.dart';
import '../filters/filter_bottom_sheet.dart';

/// Powerful search: debounced text query + recent searches + live results.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller.text = ref.read(propertyFilterProvider).query;
    _scroll.addListener(() {
      if (_scroll.position.pixels >=
          _scroll.position.maxScrollExtent - 320) {
        ref.read(paginatedPropertiesProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      final PropertyFilter current = ref.read(propertyFilterProvider);
      ref.read(propertyFilterProvider.notifier).set(
            current.copyWith(query: value.trim()),
          );
    });
  }

  Future<void> _onSubmitted(String value) async {
    await ref.read(cacheServiceProvider).addRecentSearch(value);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final PropertyListState listState =
        ref.watch(paginatedPropertiesProvider);
    final List<String> recent =
        ref.watch(cacheServiceProvider).recentSearches();
    final String query = ref.watch(propertyFilterProvider).query;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: _onChanged,
          onSubmitted: _onSubmitted,
          textInputAction: TextInputAction.search,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: const InputDecoration(
            hintText: AppStrings.searchHint,
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
          ),
        ),
        actions: <Widget>[
          if (_controller.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _controller.clear();
                _onChanged('');
                setState(() {});
              },
            ),
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () => showFilterSheet(context),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          const DemoBanner(),
          const OfflineBanner(),
          if (query.trim().isEmpty && recent.isNotEmpty)
            _RecentSearches(
              recent: recent,
              onSelect: (String q) {
                _controller.text = q;
                _onChanged(q);
                setState(() {});
              },
              onClear: () async {
                await ref
                    .read(cacheServiceProvider)
                    .clearRecentSearches();
                if (mounted) setState(() {});
              },
            ),
          Expanded(child: _buildResults(listState, query)),
        ],
      ),
    );
  }

  Widget _buildResults(PropertyListState state, String query) {
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
        subtitle: query.trim().isEmpty
            ? 'اكتب كلمة للبحث عن عقار.'
            : AppStrings.noResultsHint,
      );
    }
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(paginatedPropertiesProvider.notifier).refresh(),
      child: ListView.separated(
        controller: _scroll,
        padding: const EdgeInsets.all(16),
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

class _RecentSearches extends StatelessWidget {
  const _RecentSearches({
    required this.recent,
    required this.onSelect,
    required this.onClear,
  });

  final List<String> recent;
  final void Function(String q) onSelect;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  AppStrings.recentSearches,
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              InkWell(
                onTap: onClear,
                child: const Text(
                  AppStrings.clearFilters,
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final String q in recent)
                ActionChip(
                  avatar: const Icon(Icons.history, size: 16),
                  label: Text(q),
                  onPressed: () => onSelect(q),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
