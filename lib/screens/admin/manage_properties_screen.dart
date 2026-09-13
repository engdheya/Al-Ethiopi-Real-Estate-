import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/network_image.dart';
import '../../firebase/firebase_providers.dart';
import '../../l10n/app_strings.dart';
import '../../models/property.dart';
import '../../models/property_page.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';

enum _AdminFilter { all, published, hidden, featured }

/// "إدارة العقارات": search + filter + edit / publish / feature / delete.
class ManagePropertiesTab extends ConsumerStatefulWidget {
  const ManagePropertiesTab({super.key});

  @override
  ConsumerState<ManagePropertiesTab> createState() =>
      _ManagePropertiesTabState();
}

class _ManagePropertiesTabState
    extends ConsumerState<ManagePropertiesTab> {
  final ScrollController _scroll = ScrollController();
  final TextEditingController _search = TextEditingController();
  final List<Property> _items = <Property>[];
  DocumentSnapshot<Map<String, dynamic>>? _cursor;
  String? _demoCursor;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  bool _fetching = false;
  String? _error;
  _AdminFilter _filter = _AdminFilter.all;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels >=
          _scroll.position.maxScrollExtent - 320) {
        _loadMore();
      }
    });
    Future<void>.microtask(() => _load(reset: true));
  }

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load({required bool reset}) async {
    if (_fetching) return;
    _fetching = true;
    if (reset) {
      _cursor = null;
      _demoCursor = null;
      _hasMore = true;
      _items.clear();
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final PropertyPage page = await ref
          .read(propertyRepositoryProvider)
          .fetchAdminPage(
            startAfter: _cursor,
            limit: AppConstants.adminPageSize,
          );
      _cursor = page.lastDoc ?? _cursor;
      _demoCursor = page.lastId ?? _demoCursor;
      if (reset) {
        _items
          ..clear()
          ..addAll(page.items);
      } else {
        _items.addAll(page.items);
      }
      setState(() {
        _loading = false;
        _loadingMore = false;
        _hasMore = page.hasMore;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _loadingMore = false;
        _error = e.toString();
      });
    } finally {
      _fetching = false;
    }
  }

  Future<void> _loadMore() async {
    if (_fetching || _loadingMore || !_hasMore || _loading) return;
    setState(() => _loadingMore = true);
    await _load(reset: false);
  }

  List<Property> get _visible {
    final String q = _search.text.trim();
    return _items.where((Property p) {
      switch (_filter) {
        case _AdminFilter.published:
          if (!p.isPublished) return false;
          break;
        case _AdminFilter.hidden:
          if (p.isPublished) return false;
          break;
        case _AdminFilter.featured:
          if (!p.isFeatured) return false;
          break;
        case _AdminFilter.all:
          break;
      }
      if (q.isEmpty) return true;
      final String haystack =
          '${p.title} ${p.cityName} ${p.areaName} ${p.typeName}';
      return haystack.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final List<Property> visible = _visible;
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context)
            .pushNamed(
              AppRoutes.propertyForm,
              arguments: const PropertyFormArgs(null),
            )
            .then((_) => _load(reset: true)),
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.addProperty),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: AppStrings.searchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(
                          _search.clear,
                        ),
                      ),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: <Widget>[
                _FilterChip(
                  label: AppStrings.all,
                  selected: _filter == _AdminFilter.all,
                  onTap: () =>
                      setState(() => _filter = _AdminFilter.all),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: AppStrings.published,
                  selected:
                      _filter == _AdminFilter.published,
                  onTap: () => setState(
                    () => _filter = _AdminFilter.published,
                  ),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: AppStrings.unpublished,
                  selected: _filter == _AdminFilter.hidden,
                  onTap: () => setState(
                    () => _filter = _AdminFilter.hidden,
                  ),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: AppStrings.featured,
                  selected:
                      _filter == _AdminFilter.featured,
                  onTap: () => setState(
                    () => _filter = _AdminFilter.featured,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildList(visible)),
        ],
      ),
    );
  }

  Widget _buildList(List<Property> visible) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _items.isEmpty) {
      return ErrorState(
        message: _error!,
        onRetry: () => _load(reset: true),
      );
    }
    if (visible.isEmpty) {
      return const EmptyState(
        icon: Icons.home_work_outlined,
        title: AppStrings.noResults,
      );
    }
    return RefreshIndicator(
      onRefresh: () => _load(reset: true),
      child: ListView.separated(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
        itemCount: visible.length + (_hasMore ? 1 : 0),
        separatorBuilder: (BuildContext context, int _) =>
            const SizedBox(height: 10),
        itemBuilder: (BuildContext context, int i) {
          if (i >= visible.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _AdminPropertyRow(
            property: visible[i],
            onChanged: () => _load(reset: true),
          );
        },
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _AdminPropertyRow extends ConsumerWidget {
  const _AdminPropertyRow({
    required this.property,
    required this.onChanged,
  });

  final Property property;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Property p = property;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => AppRoutes.openProperty(context, p.id),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: <Widget>[
              AppNetworkImage(
                url: p.mainImage?.url,
                width: 86,
                height: 86,
                borderRadius: BorderRadius.circular(12),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      p.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${p.typeName} • ${p.locationLabel}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      Formatters.formatPrice(p.price, p.currency),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      children: <Widget>[
                        _MiniBadge(
                          text: p.isPublished
                              ? AppStrings.published
                              : AppStrings.unpublished,
                          color: p.isPublished
                              ? AppColors.success
                              : AppColors.textMuted,
                        ),
                        if (p.isFeatured)
                          const _MiniBadge(
                            text: AppStrings.featured,
                            color: AppColors.goldDark,
                          ),
                        _MiniBadge(
                          text: p.status.labelAr,
                          color: _statusColor(p.status),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (String v) =>
                    _handle(context, ref, v),
                itemBuilder: (BuildContext context) =>
                    <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'edit',
                    child: Text(AppStrings.edit),
                  ),
                  PopupMenuItem<String>(
                    value: 'publish',
                    child: Text(
                      p.isPublished
                          ? AppStrings.unpublish
                          : AppStrings.publish,
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'featured',
                    child: Text(
                      p.isFeatured
                          ? AppStrings.unmarkFeatured
                          : AppStrings.markFeatured,
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: 'delete',
                    child: Text(
                      AppStrings.delete,
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handle(
    BuildContext context,
    WidgetRef ref,
    String value,
  ) async {
    final repo = ref.read(propertyRepositoryProvider);
    try {
      switch (value) {
        case 'edit':
          await Navigator.of(context).pushNamed(
            AppRoutes.propertyForm,
            arguments: PropertyFormArgs(property.id),
          );
          onChanged();
          break;
        case 'publish':
          await repo.setPublished(
            property.id,
            !property.isPublished,
          );
          if (context.mounted) {
            showSuccessSnack(context, AppStrings.propertySaved);
          }
          onChanged();
          break;
        case 'featured':
          await repo.setFeatured(
            property.id,
            !property.isFeatured,
          );
          if (context.mounted) {
            showSuccessSnack(context, AppStrings.propertySaved);
          }
          onChanged();
          break;
        case 'delete':
          final bool confirm = await showConfirmDialog(
            context,
            title: AppStrings.deleteProperty,
            message: AppStrings.deletePropertyConfirm,
          );
          if (!confirm) return;
          final storageRepo =
              ref.read(storageRepositoryProvider);
          for (final PropertyImage img in property.images) {
            await storageRepo.deleteImage(img.path);
          }
          await repo.deleteProperty(property.id);
          if (context.mounted) {
            showSuccessSnack(
              context,
              AppStrings.propertyDeleted,
            );
          }
          onChanged();
          break;
      }
    } catch (e) {
      if (context.mounted) showErrorSnack(context, e);
    }
  }

  Color _statusColor(PropertyStatus status) {
    switch (status) {
      case PropertyStatus.available:
        return AppColors.statusAvailable;
      case PropertyStatus.rented:
        return AppColors.statusRented;
      case PropertyStatus.sold:
        return AppColors.statusSold;
      case PropertyStatus.unavailable:
        return AppColors.statusUnavailable;
    }
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
