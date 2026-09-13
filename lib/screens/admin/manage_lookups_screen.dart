import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/type_icon.dart';
import '../../firebase/firebase_providers.dart';
import '../../l10n/app_strings.dart';
import '../../models/area.dart';
import '../../models/city.dart';
import '../../models/feature_item.dart';
import '../../models/property_type.dart';
import '../../providers/lookup_providers.dart';
import '../../theme/app_colors.dart';

/// Admin catalog management: types, cities, areas, features.
class ManageLookupsScreen extends StatelessWidget {
  const ManageLookupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('إدارة التصنيفات والمدن'),
          bottom: const TabBar(
            indicatorColor: AppColors.gold,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: <Widget>[
              Tab(text: AppStrings.manageTypes),
              Tab(text: AppStrings.manageCities),
              Tab(text: AppStrings.manageAreas),
              Tab(text: AppStrings.manageFeatures),
            ],
          ),
        ),
        body: const TabBarView(
          children: <Widget>[
            _TypesTab(),
            _CitiesTab(),
            _AreasTab(),
            _FeaturesTab(),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------- types

class _TypesTab extends ConsumerWidget {
  const _TypesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<PropertyType>> async =
        ref.watch(adminTypesProvider);
    return _CatalogScaffold<PropertyType>(
      itemsAsync: async,
      emptyIcon: Icons.category_outlined,
      tileBuilder: (PropertyType t) => ListTile(
        leading: Icon(
          typeIconFromName(t.icon),
          color: AppColors.primary,
        ),
        title: Text(t.name),
        subtitle: Text('${AppStrings.order}: ${t.order}'),
        trailing: _ActiveDot(active: t.isActive),
      ),
      onAdd: () => _showTypeDialog(context, ref, null),
      onEdit: (PropertyType t) =>
          _showTypeDialog(context, ref, t),
      onDelete: (PropertyType t) =>
          _delete(context, ref, () => ref
              .read(lookupRepositoryProvider)
              .deleteType(t.id)),
    );
  }

  Future<void> _showTypeDialog(
    BuildContext context,
    WidgetRef ref,
    PropertyType? existing,
  ) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) => _LookupDialog(
        title: existing == null
            ? '${AppStrings.addNew} — نوع عقار'
            : AppStrings.edit,
        initialName: existing?.name ?? '',
        initialOrder: existing?.order ?? 0,
        initialActive: existing?.isActive ?? true,
        iconOptions: _typeIcons,
        initialIcon: existing?.icon ?? 'home',
        onSave: ({
          required String name,
          required int order,
          required bool active,
          String? icon,
          String? cityId,
        }) async {
          final repo = ref.read(lookupRepositoryProvider);
          if (existing == null) {
            await repo.addType(
              PropertyType(
                id: '',
                name: name,
                icon: icon ?? 'home',
                order: order,
                isActive: active,
              ),
            );
          } else {
            await repo.updateType(
              PropertyType(
                id: existing.id,
                name: name,
                icon: icon ?? existing.icon,
                order: order,
                isActive: active,
              ),
            );
          }
        },
      ),
    );
  }
}

// ------------------------------------------------------------------ cities

class _CitiesTab extends ConsumerWidget {
  const _CitiesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<City>> async =
        ref.watch(adminCitiesProvider);
    return _CatalogScaffold<City>(
      itemsAsync: async,
      emptyIcon: Icons.location_city_outlined,
      tileBuilder: (City c) => ListTile(
        leading: const Icon(
          Icons.location_city_outlined,
          color: AppColors.primary,
        ),
        title: Text(c.name),
        subtitle: Text('${AppStrings.order}: ${c.order}'),
        trailing: _ActiveDot(active: c.isActive),
      ),
      onAdd: () => _showDialog(context, ref, null),
      onEdit: (City c) => _showDialog(context, ref, c),
      onDelete: (City c) => _delete(context, ref,
          () => ref.read(lookupRepositoryProvider).deleteCity(c.id)),
    );
  }

  Future<void> _showDialog(
    BuildContext context,
    WidgetRef ref,
    City? existing,
  ) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) => _LookupDialog(
        title: existing == null
            ? '${AppStrings.addNew} — مدينة'
            : AppStrings.edit,
        initialName: existing?.name ?? '',
        initialOrder: existing?.order ?? 0,
        initialActive: existing?.isActive ?? true,
        onSave: ({
          required String name,
          required int order,
          required bool active,
          String? icon,
          String? cityId,
        }) async {
          final repo = ref.read(lookupRepositoryProvider);
          if (existing == null) {
            await repo.addCity(
              City(id: '', name: name, order: order, isActive: active),
            );
          } else {
            await repo.updateCity(
              City(
                id: existing.id,
                name: name,
                order: order,
                isActive: active,
              ),
            );
          }
        },
      ),
    );
  }
}

// ------------------------------------------------------------------- areas

class _AreasTab extends ConsumerStatefulWidget {
  const _AreasTab();

  @override
  ConsumerState<_AreasTab> createState() => _AreasTabState();
}

class _AreasTabState extends ConsumerState<_AreasTab> {
  String? _cityFilter;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Area>> async =
        ref.watch(adminAreasProvider);
    final List<City> cities =
        ref.watch(adminCitiesProvider).valueOrNull ?? const <City>[];
    final Map<String, String> cityNames = <String, String>{
      for (final City c in cities) c.id: c.name,
    };

    return Column(
      children: <Widget>[
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: <Widget>[
              ChoiceChip(
                label: const Text(AppStrings.all),
                selected: _cityFilter == null,
                onSelected: (_) =>
                    setState(() => _cityFilter = null),
              ),
              const SizedBox(width: 8),
              for (final City c in cities) ...<Widget>[
                ChoiceChip(
                  label: Text(c.name),
                  selected: _cityFilter == c.id,
                  onSelected: (_) =>
                      setState(() => _cityFilter = c.id),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        Expanded(
          child: _CatalogScaffold<Area>(
            itemsAsync: async.map(
              (List<Area> list) => _cityFilter == null
                  ? list
                  : list
                      .where((Area a) =>
                          a.cityId == _cityFilter)
                      .toList(),
            ),
            emptyIcon: Icons.map_outlined,
            tileBuilder: (Area a) => ListTile(
              leading: const Icon(
                Icons.place_outlined,
                color: AppColors.primary,
              ),
              title: Text(a.name),
              subtitle: Text(
                cityNames[a.cityId] ?? a.cityId,
              ),
              trailing: _ActiveDot(active: a.isActive),
            ),
            onAdd: () => _showDialog(context, null, cities),
            onEdit: (Area a) =>
                _showDialog(context, a, cities),
            onDelete: (Area a) => _delete(
              context,
              ref,
              () => ref
                  .read(lookupRepositoryProvider)
                  .deleteArea(a.id),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showDialog(
    BuildContext context,
    Area? existing,
    List<City> cities,
  ) {
    if (cities.isEmpty) {
      showErrorSnack(context, 'أضف مدينة أولاً.');
      return Future<void>.value();
    }
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) => _LookupDialog(
        title: existing == null
            ? '${AppStrings.addNew} — منطقة'
            : AppStrings.edit,
        initialName: existing?.name ?? '',
        initialOrder: existing?.order ?? 0,
        initialActive: existing?.isActive ?? true,
        cities: cities,
        initialCityId: existing?.cityId ?? _cityFilter,
        onSave: ({
          required String name,
          required int order,
          required bool active,
          String? icon,
          String? cityId,
        }) async {
          if (cityId == null || cityId.isEmpty) {
            throw Exception(AppStrings.selectCityFirst);
          }
          final repo = ref.read(lookupRepositoryProvider);
          if (existing == null) {
            await repo.addArea(
              Area(
                id: '',
                name: name,
                cityId: cityId,
                order: order,
                isActive: active,
              ),
            );
          } else {
            await repo.updateArea(
              Area(
                id: existing.id,
                name: name,
                cityId: cityId,
                order: order,
                isActive: active,
              ),
            );
          }
        },
      ),
    );
  }
}

// ---------------------------------------------------------------- features

class _FeaturesTab extends ConsumerWidget {
  const _FeaturesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<FeatureItem>> async =
        ref.watch(adminFeaturesProvider);
    return _CatalogScaffold<FeatureItem>(
      itemsAsync: async,
      emptyIcon: Icons.checklist_outlined,
      tileBuilder: (FeatureItem f) => ListTile(
        leading: Icon(
          featureIconFromName(f.icon),
          color: AppColors.primary,
        ),
        title: Text(f.name),
        subtitle: Text('${AppStrings.order}: ${f.order}'),
        trailing: _ActiveDot(active: f.isActive),
      ),
      onAdd: () => _showDialog(context, ref, null),
      onEdit: (FeatureItem f) =>
          _showDialog(context, ref, f),
      onDelete: (FeatureItem f) => _delete(context, ref,
          () => ref.read(lookupRepositoryProvider).deleteFeature(f.id)),
    );
  }

  Future<void> _showDialog(
    BuildContext context,
    WidgetRef ref,
    FeatureItem? existing,
  ) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) => _LookupDialog(
        title: existing == null
            ? '${AppStrings.addNew} — ميزة'
            : AppStrings.edit,
        initialName: existing?.name ?? '',
        initialOrder: existing?.order ?? 0,
        initialActive: existing?.isActive ?? true,
        iconOptions: _featureIcons,
        initialIcon: existing?.icon ?? 'check_circle',
        onSave: ({
          required String name,
          required int order,
          required bool active,
          String? icon,
          String? cityId,
        }) async {
          final repo = ref.read(lookupRepositoryProvider);
          if (existing == null) {
            await repo.addFeature(
              FeatureItem(
                id: '',
                name: name,
                icon: icon ?? 'check_circle',
                order: order,
                isActive: active,
              ),
            );
          } else {
            await repo.updateFeature(
              FeatureItem(
                id: existing.id,
                name: name,
                icon: icon ?? existing.icon,
                order: order,
                isActive: active,
              ),
            );
          }
        },
      ),
    );
  }
}

// ----------------------------------------------------------------- generic

Future<void> _delete(
  BuildContext context,
  WidgetRef ref,
  Future<void> Function() action,
) async {
  final bool confirm = await showConfirmDialog(
    context,
    title: AppStrings.delete,
    message: 'هل أنت متأكد من حذف هذا العنصر؟',
  );
  if (!confirm) return;
  try {
    await action();
    if (context.mounted) {
      showSuccessSnack(context, AppStrings.propertyDeleted);
    }
  } catch (e) {
    if (context.mounted) showErrorSnack(context, e);
  }
}

class _CatalogScaffold<T> extends StatelessWidget {
  const _CatalogScaffold({
    required this.itemsAsync,
    required this.emptyIcon,
    required this.tileBuilder,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  final AsyncValue<List<T>> itemsAsync;
  final IconData emptyIcon;
  final Widget Function(T item) tileBuilder;
  final VoidCallback onAdd;
  final void Function(T item) onEdit;
  final void Function(T item) onDelete;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: onAdd,
        child: const Icon(Icons.add),
      ),
      body: itemsAsync.when(
        data: (List<T> items) {
          if (items.isEmpty) {
            return EmptyState(
              icon: emptyIcon,
              title: 'لا توجد عناصر بعد.',
              actionLabel: AppStrings.addNew,
              onAction: onAdd,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
            itemCount: items.length,
            separatorBuilder:
                (BuildContext context, int _) =>
                    const SizedBox(height: 8),
            itemBuilder: (BuildContext context, int i) {
              return Card(
                child: Row(
                  children: <Widget>[
                    Expanded(
                        child: tileBuilder(items[i])),
                    IconButton(
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: AppColors.primary,
                      ),
                      onPressed: () => onEdit(items[i]),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.error,
                      ),
                      onPressed: () => onDelete(items[i]),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (Object e, StackTrace _) => Center(
          child: Text(
            e.toString(),
            style: const TextStyle(color: AppColors.error),
          ),
        ),
      ),
    );
  }
}

class _LookupDialog extends StatefulWidget {
  const _LookupDialog({
    required this.title,
    required this.initialName,
    required this.initialOrder,
    required this.initialActive,
    required this.onSave,
    this.iconOptions,
    this.initialIcon,
    this.cities,
    this.initialCityId,
  });

  final String title;
  final String initialName;
  final int initialOrder;
  final bool initialActive;
  final Future<void> Function({
    required String name,
    required int order,
    required bool active,
    String? icon,
    String? cityId,
  }) onSave;
  final List<String>? iconOptions;
  final String? initialIcon;
  final List<City>? cities;
  final String? initialCityId;

  @override
  State<_LookupDialog> createState() => _LookupDialogState();
}

class _LookupDialogState extends State<_LookupDialog> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _order;
  late bool _active;
  String? _icon;
  String? _cityId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.initialName);
    _order =
        TextEditingController(text: '${widget.initialOrder}');
    _active = widget.initialActive;
    _icon = widget.initialIcon;
    _cityId = widget.initialCityId;
  }

  @override
  void dispose() {
    _name.dispose();
    _order.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await widget.onSave(
        name: _name.text.trim(),
        order: int.tryParse(_order.text.trim()) ?? 0,
        active: _active,
        icon: _icon,
        cityId: _cityId,
      );
      if (mounted) {
        showSuccessSnack(context, AppStrings.propertySaved);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AppTextField(
                label: AppStrings.itemName,
                controller: _name,
                validator: (String? v) =>
                    v == null || v.trim().isEmpty
                        ? AppStrings.requiredField
                        : null,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: AppStrings.order,
                controller: _order,
                keyboardType: TextInputType.number,
              ),
              if (widget.cities != null) ...<Widget>[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _cityId,
                  decoration: const InputDecoration(
                    labelText: AppStrings.city,
                  ),
                  items: <DropdownMenuItem<String>>[
                    for (final City c in widget.cities!)
                      DropdownMenuItem<String>(
                        value: c.id,
                        child: Text(c.name),
                      ),
                  ],
                  onChanged: (String? v) =>
                      setState(() => _cityId = v),
                ),
              ],
              if (widget.iconOptions != null) ...<Widget>[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _icon,
                  decoration: const InputDecoration(
                    labelText: 'الأيقونة',
                  ),
                  items: <DropdownMenuItem<String>>[
                    for (final String icon
                        in widget.iconOptions!)
                      DropdownMenuItem<String>(
                        value: icon,
                        child: Row(
                          children: <Widget>[
                            Icon(
                              widget.iconOptions ==
                                      _typeIcons
                                  ? typeIconFromName(icon)
                                  : featureIconFromName(icon),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(icon),
                          ],
                        ),
                      ),
                  ],
                  onChanged: (String? v) =>
                      setState(() => _icon = v),
                ),
              ],
              SwitchListTile(
                value: _active,
                onChanged: (bool v) =>
                    setState(() => _active = v),
                title: const Text(AppStrings.showInApp),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(AppStrings.saveAction),
        ),
      ],
    );
  }
}

class _ActiveDot extends StatelessWidget {
  const _ActiveDot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: active ? AppColors.success : AppColors.border,
        shape: BoxShape.circle,
      ),
    );
  }
}

const List<String> _typeIcons = <String>[
  'apartment',
  'home',
  'villa',
  'landscape',
  'terrain',
  'store',
  'business',
  'domain',
  'real_estate_agent',
  'hotel',
  'warehouse',
  'cabin',
];

const List<String> _featureIcons = <String>[
  'check_circle',
  'water',
  'electric',
  'parking',
  'kitchen',
  'ac',
  'yard',
  'elevator',
  'furniture',
  'road',
  'tank',
  'internet',
  'security',
];
