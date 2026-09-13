import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/app_text_field.dart';
import '../../l10n/app_strings.dart';
import '../../models/area.dart';
import '../../models/city.dart';
import '../../models/property.dart';
import '../../models/property_filter.dart';
import '../../models/property_type.dart';
import '../../providers/filter_provider.dart';
import '../../providers/lookup_providers.dart';
import '../../theme/app_colors.dart';

/// Opens the filter bottom sheet.
Future<void> showFilterSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (BuildContext context) => const FilterSheet(),
  );
}

/// Full filter editor (purpose, type, city, area, price, size, rooms, sort).
class FilterSheet extends ConsumerStatefulWidget {
  const FilterSheet({super.key});

  @override
  ConsumerState<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<FilterSheet> {
  late PropertyFilter _draft;
  late final TextEditingController _minPrice;
  late final TextEditingController _maxPrice;
  late final TextEditingController _minSize;
  late final TextEditingController _maxSize;

  @override
  void initState() {
    super.initState();
    _draft = ref.read(propertyFilterProvider);
    String num(double? v) =>
        v == null ? '' : v.truncateToDouble() == v ? v.toStringAsFixed(0) : '$v';
    _minPrice = TextEditingController(text: num(_draft.minPrice));
    _maxPrice = TextEditingController(text: num(_draft.maxPrice));
    _minSize = TextEditingController(text: num(_draft.minSize));
    _maxSize = TextEditingController(text: num(_draft.maxSize));
  }

  @override
  void dispose() {
    _minPrice.dispose();
    _maxPrice.dispose();
    _minSize.dispose();
    _maxSize.dispose();
    super.dispose();
  }

  double? _parse(TextEditingController c) {
    final String t = c.text.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t.replaceAll(',', ''));
  }

  void _apply() {
    final PropertyFilter applied = _draft.copyWith(
      minPrice: () => _parse(_minPrice),
      maxPrice: () => _parse(_maxPrice),
      minSize: () => _parse(_minSize),
      maxSize: () => _parse(_maxSize),
    );
    ref.read(propertyFilterProvider.notifier).set(applied);
    Navigator.of(context).pop();
  }

  void _clear() {
    ref.read(propertyFilterProvider.notifier).clear();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final List<PropertyType> types =
        ref.watch(propertyTypesProvider).valueOrNull ?? const <PropertyType>[];
    final List<City> cities =
        ref.watch(citiesProvider).valueOrNull ?? const <City>[];
    final List<Area> areas = ref
            .watch(areasProvider(_draft.cityId ?? ''))
            .valueOrNull ??
        const <Area>[];

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      builder: (BuildContext context, ScrollController scroll) {
        return SingleChildScrollView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Center(
                child: Text(
                  AppStrings.filters,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _Label(AppStrings.purpose),
              const SizedBox(height: 8),
              SegmentedButton<PropertyPurpose?>(
                segments: const <ButtonSegment<PropertyPurpose?>>[
                  ButtonSegment<PropertyPurpose?>(
                    value: null,
                    label: Text(AppStrings.all),
                  ),
                  ButtonSegment<PropertyPurpose?>(
                    value: PropertyPurpose.sale,
                    label: Text(AppStrings.sale),
                  ),
                  ButtonSegment<PropertyPurpose?>(
                    value: PropertyPurpose.rent,
                    label: Text(AppStrings.rent),
                  ),
                ],
                selected: <PropertyPurpose?>{_draft.purpose},
                onSelectionChanged: (Set<PropertyPurpose?> s) {
                  setState(() {
                    _draft =
                        _draft.copyWith(purpose: () => s.first);
                  });
                },
              ),
              const SizedBox(height: 16),
              _Label(AppStrings.propertyType),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  ChoiceChip(
                    label: const Text(AppStrings.all),
                    selected: _draft.typeId == null,
                    onSelected: (_) => setState(() {
                      _draft = _draft.copyWith(typeId: () => null);
                    }),
                  ),
                  for (final PropertyType t in types)
                    ChoiceChip(
                      label: Text(t.name),
                      selected: _draft.typeId == t.id,
                      onSelected: (_) => setState(() {
                        _draft = _draft.copyWith(typeId: () => t.id);
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _Dropdown<String?>(
                      label: AppStrings.city,
                      value: _draft.cityId,
                      hint: AppStrings.anyCity,
                      items: <DropdownMenuItem<String?>>[
                        const DropdownMenuItem<String?>(
                          child: Text(AppStrings.anyCity),
                        ),
                        for (final City c in cities)
                          DropdownMenuItem<String?>(
                            value: c.id,
                            child: Text(c.name),
                          ),
                      ],
                      onChanged: (String? v) => setState(() {
                        _draft = _draft.copyWith(
                          cityId: () => v,
                          areaId: () => null,
                        );
                      }),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Dropdown<String?>(
                      label: AppStrings.area,
                      value: _draft.areaId,
                      hint: _draft.cityId == null
                          ? AppStrings.pickCityFirst
                          : AppStrings.anyArea,
                      items: <DropdownMenuItem<String?>>[
                        DropdownMenuItem<String?>(
                          child: Text(
                            _draft.cityId == null
                                ? AppStrings.pickCityFirst
                                : AppStrings.anyArea,
                          ),
                        ),
                        for (final Area a in areas)
                          DropdownMenuItem<String?>(
                            value: a.id,
                            child: Text(a.name),
                          ),
                      ],
                      onChanged: _draft.cityId == null
                          ? null
                          : (String? v) => setState(() {
                                _draft =
                                    _draft.copyWith(areaId: () => v);
                              }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: AppTextField(
                      label: AppStrings.minPrice,
                      controller: _minPrice,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      label: AppStrings.maxPrice,
                      controller: _maxPrice,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: AppTextField(
                      label: AppStrings.minSize,
                      controller: _minSize,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppTextField(
                      label: AppStrings.maxSize,
                      controller: _maxSize,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _Dropdown<int?>(
                      label: AppStrings.minBedrooms,
                      value: _draft.minBedrooms,
                      hint: AppStrings.all,
                      items: <DropdownMenuItem<int?>>[
                        const DropdownMenuItem<int?>(
                          child: Text(AppStrings.all),
                        ),
                        for (int i = 1; i <= 6; i++)
                          DropdownMenuItem<int?>(
                            value: i,
                            child: Text('$i+'),
                          ),
                      ],
                      onChanged: (int? v) => setState(() {
                        _draft =
                            _draft.copyWith(minBedrooms: () => v);
                      }),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Dropdown<PropertyStatus?>(
                      label: AppStrings.status,
                      value: _draft.status,
                      hint: AppStrings.all,
                      items: <DropdownMenuItem<PropertyStatus?>>[
                        const DropdownMenuItem<PropertyStatus?>(
                          child: Text(AppStrings.all),
                        ),
                        for (final PropertyStatus s
                            in PropertyStatus.values)
                          DropdownMenuItem<PropertyStatus?>(
                            value: s,
                            child: Text(s.labelAr),
                          ),
                      ],
                      onChanged: (PropertyStatus? v) => setState(() {
                        _draft = _draft.copyWith(status: () => v);
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                value: _draft.onlyFeatured,
                onChanged: (bool v) => setState(() {
                  _draft = _draft.copyWith(onlyFeatured: v);
                }),
                title: const Text(
                  AppStrings.featured,
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                contentPadding: EdgeInsets.zero,
              ),
              _Label(AppStrings.sortBy),
              const SizedBox(height: 8),
              SegmentedButton<PropertySort>(
                segments: <ButtonSegment<PropertySort>>[
                  for (final PropertySort s in PropertySort.values)
                    ButtonSegment<PropertySort>(
                      value: s,
                      label: Text(
                        s.labelAr,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                ],
                selected: <PropertySort>{_draft.sort},
                onSelectionChanged: (Set<PropertySort> s) {
                  setState(() {
                    _draft = _draft.copyWith(sort: s.first);
                  });
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _clear,
                      child: const Text(AppStrings.clearFilters),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _apply,
                      child: const Text(AppStrings.applyFilters),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
      ),
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  const _Dropdown({
    required this.label,
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _Label(label),
        const SizedBox(height: 6),
        DropdownButtonFormField<T>(
          initialValue: value,
          hint: Text(hint),
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
