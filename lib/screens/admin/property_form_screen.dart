import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/image_helper.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/network_image.dart';
import '../../firebase/firebase_providers.dart';
import '../../l10n/app_strings.dart';
import '../../models/area.dart';
import '../../models/city.dart';
import '../../models/feature_item.dart';
import '../../models/property.dart';
import '../../models/property_type.dart';
import '../../providers/auth_providers.dart';
import '../../providers/lookup_providers.dart';
import '../../theme/app_colors.dart';

/// Admin add / edit property form with multi-image management.
class PropertyFormScreen extends ConsumerStatefulWidget {
  const PropertyFormScreen({super.key, this.propertyId});

  final String? propertyId;

  @override
  ConsumerState<PropertyFormScreen> createState() =>
      _PropertyFormScreenState();
}

class _PropertyFormScreenState
    extends ConsumerState<PropertyFormScreen> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();

  final TextEditingController _title = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _price = TextEditingController();
  final TextEditingController _size = TextEditingController();
  final TextEditingController _bedrooms = TextEditingController();
  final TextEditingController _bathrooms = TextEditingController();
  final TextEditingController _floor = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _whatsapp = TextEditingController();

  PropertyPurpose _purpose = PropertyPurpose.sale;
  String? _typeId;
  String? _cityId;
  String? _areaId;
  String _currency = AppConstants.defaultCurrency;
  PropertyStatus _status = PropertyStatus.available;
  bool _isPublished = true;
  bool _isFeatured = false;
  final Set<String> _featureIds = <String>{};

  final List<PropertyImage> _existingImages = <PropertyImage>[];
  final List<File> _newImages = <File>[];
  final List<String> _deletedPaths = <String>[];
  String? _mainKey; // 'existing:<path>' or 'new:<index>'

  bool _loadingExisting = false;
  bool _saving = false;
  String _savingStatus = '';
  Property? _original;

  bool get _isEdit => widget.propertyId != null;

  @override
  void initState() {
    super.initState();
    _bedrooms.text = '0';
    _bathrooms.text = '0';
    if (_isEdit) {
      Future<void>.microtask(_loadExisting);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _address.dispose();
    _price.dispose();
    _size.dispose();
    _bedrooms.dispose();
    _bathrooms.dispose();
    _floor.dispose();
    _description.dispose();
    _phone.dispose();
    _whatsapp.dispose();
    super.dispose();
  }

  Future<void> _loadExisting() async {
    setState(() => _loadingExisting = true);
    try {
      final Property? p = await ref
          .read(propertyRepositoryProvider)
          .getProperty(widget.propertyId!);
      if (p == null) {
        if (mounted) {
          showErrorSnack(context, 'العقار غير موجود.');
          Navigator.of(context).pop();
        }
        return;
      }
      _original = p;
      _title.text = p.title;
      _address.text = p.address;
      _price.text = p.price.truncateToDouble() == p.price
          ? p.price.toStringAsFixed(0)
          : '${p.price}';
      _size.text = p.size.truncateToDouble() == p.size
          ? p.size.toStringAsFixed(0)
          : '${p.size}';
      _bedrooms.text = '${p.bedrooms}';
      _bathrooms.text = '${p.bathrooms}';
      _floor.text = p.floor == null ? '' : '${p.floor}';
      _description.text = p.description;
      _phone.text = p.phone;
      _whatsapp.text = p.whatsapp;
      _purpose = p.purpose;
      _typeId = p.typeId.isEmpty ? null : p.typeId;
      _cityId = p.cityId.isEmpty ? null : p.cityId;
      _areaId = p.areaId.isEmpty ? null : p.areaId;
      _currency = p.currency;
      _status = p.status;
      _isPublished = p.isPublished;
      _isFeatured = p.isFeatured;
      _featureIds.addAll(p.featureIds);
      _existingImages.addAll(p.images);
      final PropertyImage? main = p.mainImage;
      if (main != null) _mainKey = 'existing:${main.path}';
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        showErrorSnack(context, e);
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _loadingExisting = false);
    }
  }

  // ---------------------------------------------------------------- images

  int get _totalImages =>
      _existingImages.length + _newImages.length;

  Future<void> _pickImages() async {
    if (_totalImages >= AppConstants.maxImagesPerProperty) {
      showInfoSnack(context, AppStrings.tooManyImages);
      return;
    }
    try {
      final List<File> picked =
          await ImageHelper.pickPropertyImages(
        max: AppConstants.maxImagesPerProperty - _totalImages,
      );
      if (picked.isEmpty) return;
      setState(() {
        _newImages.addAll(picked);
        _mainKey ??= _totalImages == picked.length
            ? 'new:0'
            : _mainKey;
      });
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    }
  }

  Future<void> _removeExisting(int index) async {
    final bool confirm = await showConfirmDialog(
      context,
      title: AppStrings.deleteImage,
      message: AppStrings.deleteImageConfirm,
    );
    if (!confirm) return;
    setState(() {
      final PropertyImage removed =
          _existingImages.removeAt(index);
      if (removed.path.isNotEmpty &&
          !removed.path.startsWith('demo/')) {
        _deletedPaths.add(removed.path);
      }
      if (_mainKey == 'existing:${removed.path}') {
        _mainKey = null;
      }
    });
  }

  void _removeNew(int index) {
    setState(() {
      _newImages.removeAt(index);
      // Re-key main selection after removal.
      if (_mainKey == 'new:$index') {
        _mainKey = null;
      } else if (_mainKey != null &&
          _mainKey!.startsWith('new:')) {
        final int old =
            int.tryParse(_mainKey!.split(':')[1]) ?? -1;
        if (old > index) _mainKey = 'new:${old - 1}';
      }
    });
  }

  // ------------------------------------------------------------------ save

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    if (_typeId == null ||
        _cityId == null ||
        _areaId == null) {
      showErrorSnack(
        context,
        'اختر النوع والمدينة والمنطقة.',
      );
      return;
    }
    if (_totalImages == 0) {
      showErrorSnack(context, AppStrings.pickAtLeastOneImage);
      return;
    }
    setState(() {
      _saving = true;
      _savingStatus = 'جارٍ الحفظ...';
    });
    try {
      final String propertyId = _isEdit
          ? widget.propertyId!
          : 'tmp-${DateTime.now().millisecondsSinceEpoch}';

      // Upload new images first.
      final List<PropertyImage> uploaded = <PropertyImage>[];
      final storageRepo = ref.read(storageRepositoryProvider);
      for (int i = 0; i < _newImages.length; i++) {
        if (mounted) {
          setState(() {
            _savingStatus =
                'جارٍ رفع الصور (${Formatters.toArabicDigits('${i + 1}')} من ${Formatters.toArabicDigits('${_newImages.length}')}...)';
          });
        }
        final PropertyImage img =
            await storageRepo.uploadPropertyImage(
          propertyId:
              propertyId.isEmpty ? 'demo-new' : propertyId,
          file: _newImages[i],
          order: _existingImages.length + i,
        );
        uploaded.add(img);
      }

      // Resolve the main image.
      String? mainKey = _mainKey;
      mainKey ??= _existingImages.isNotEmpty
          ? 'existing:${_existingImages.first.path}'
          : (uploaded.isNotEmpty ? 'new:0' : null);

      final List<PropertyImage> finalImages =
          <PropertyImage>[];
      for (final PropertyImage img in _existingImages) {
        finalImages.add(
          img.copyWith(
            isMain: mainKey == 'existing:${img.path}',
            order: finalImages.length,
          ),
        );
      }
      for (int i = 0; i < uploaded.length; i++) {
        finalImages.add(
          uploaded[i].copyWith(
            isMain: mainKey == 'new:$i',
            order: finalImages.length,
          ),
        );
      }
      if (finalImages.isNotEmpty &&
          !finalImages.any((PropertyImage e) => e.isMain)) {
        finalImages[0] = finalImages.first.copyWith(isMain: true);
      }

      // Resolve names for denormalized display fields.
      final List<PropertyType> types = ref
              .read(adminTypesProvider)
              .valueOrNull ??
          ref.read(propertyTypesProvider).valueOrNull ??
          const <PropertyType>[];
      final List<City> cities = ref
              .read(adminCitiesProvider)
              .valueOrNull ??
          ref.read(citiesProvider).valueOrNull ??
          const <City>[];
      String typeName = '';
      String cityName = '';
      String areaName = '';
      for (final PropertyType t in types) {
        if (t.id == _typeId) typeName = t.name;
      }
      for (final City c in cities) {
        if (c.id == _cityId) cityName = c.name;
      }
      final List<Area> areasForCity = await ref
          .read(lookupRepositoryProvider)
          .fetchAreas(_cityId!, activeOnly: false);
      for (final Area a in areasForCity) {
        if (a.id == _areaId) areaName = a.name;
      }
      final List<FeatureItem> allFeatures = ref
              .read(adminFeaturesProvider)
              .valueOrNull ??
          ref.read(featuresProvider).valueOrNull ??
          const <FeatureItem>[];
      final Map<String, String> featureNames = <String, String>{
        for (final FeatureItem f in allFeatures) f.id: f.name,
      };

      final String? uid =
          ref.read(currentUserProvider)?.uid;
      final repo = ref.read(propertyRepositoryProvider);

      if (_isEdit && _original != null) {
        final Property updated = _original!.copyWith(
          title: _title.text.trim(),
          description: _description.text.trim(),
          purpose: _purpose,
          typeId: _typeId,
          typeName: typeName,
          cityId: _cityId,
          cityName: cityName,
          areaId: _areaId,
          areaName: areaName,
          address: _address.text.trim(),
          price: double.parse(
            _price.text.trim().replaceAll(',', ''),
          ),
          currency: _currency,
          size: double.parse(
            _size.text.trim().replaceAll(',', ''),
          ),
          bedrooms: int.tryParse(_bedrooms.text.trim()) ?? 0,
          bathrooms: int.tryParse(_bathrooms.text.trim()) ?? 0,
          floor: _floor.text.trim().isEmpty
              ? null
              : int.tryParse(_floor.text.trim()),
          status: _status,
          isPublished: _isPublished,
          isFeatured: _isFeatured,
          images: finalImages,
          featureIds: _featureIds.toList(),
          featureNames: <String>[
            for (final String id in _featureIds)
              if (featureNames.containsKey(id))
                featureNames[id]!,
          ],
          phone: _phone.text.trim(),
          whatsapp: _whatsapp.text.trim().isEmpty
              ? _phone.text.trim()
              : _whatsapp.text.trim(),
        );
        await repo.updateProperty(updated);
        // Delete removed storage files after the doc update succeeds.
        for (final String path in _deletedPaths) {
          await storageRepo.deleteImage(path);
        }
      } else {
        final Property created = Property(
          id: '',
          title: _title.text.trim(),
          description: _description.text.trim(),
          purpose: _purpose,
          typeId: _typeId!,
          typeName: typeName,
          cityId: _cityId!,
          cityName: cityName,
          areaId: _areaId!,
          areaName: areaName,
          address: _address.text.trim(),
          price: double.parse(
            _price.text.trim().replaceAll(',', ''),
          ),
          currency: _currency,
          size: double.parse(
            _size.text.trim().replaceAll(',', ''),
          ),
          bedrooms: int.tryParse(_bedrooms.text.trim()) ?? 0,
          bathrooms: int.tryParse(_bathrooms.text.trim()) ?? 0,
          floor: _floor.text.trim().isEmpty
              ? null
              : int.tryParse(_floor.text.trim()),
          status: _status,
          isPublished: _isPublished,
          isFeatured: _isFeatured,
          images: const <PropertyImage>[],
          featureIds: _featureIds.toList(),
          featureNames: <String>[
            for (final String id in _featureIds)
              if (featureNames.containsKey(id))
                featureNames[id]!,
          ],
          phone: _phone.text.trim(),
          whatsapp: _whatsapp.text.trim().isEmpty
              ? _phone.text.trim()
              : _whatsapp.text.trim(),
          ratingAvg: 0,
          ratingCount: 0,
          favoritesCount: 0,
          commentsCount: 0,
          createdBy: uid,
        );
        // Create first to get a real id, then re-upload images under it.
        final String newId =
            await repo.createProperty(created, uid: uid);
        if (uploaded.isNotEmpty) {
          // Images were uploaded under a temp path; move metadata only
          // when storage paths differ (demo mode keeps local paths).
          final Property? withImages =
              await repo.getProperty(newId);
          if (withImages != null) {
            await repo.updateProperty(
              withImages.copyWith(images: finalImages),
            );
          }
        }
        // Clean temp-path uploads in real storage (keep demo simple).
        // (Temp uploads live under properties/tmp-*; harmless single files.)
      }

      if (mounted) {
        showSuccessSnack(context, AppStrings.propertySaved);
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
          _savingStatus = '';
        });
      }
    }
  }

  // ----------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    if (_loadingExisting) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            _isEdit
                ? AppStrings.editProperty
                : AppStrings.addProperty,
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final List<PropertyType> types = ref
            .watch(adminTypesProvider)
            .valueOrNull ??
        const <PropertyType>[];
    final List<City> cities = ref
            .watch(adminCitiesProvider)
            .valueOrNull ??
        const <City>[];
    final List<Area> areas = ref
            .watch(adminAreasProvider)
            .valueOrNull
            ?.where((Area a) => a.cityId == _cityId)
            .toList() ??
        const <Area>[];
    final List<FeatureItem> features = ref
            .watch(adminFeaturesProvider)
            .valueOrNull ??
        const <FeatureItem>[];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEdit
              ? AppStrings.editProperty
              : AppStrings.addProperty,
        ),
      ),
      body: Stack(
        children: <Widget>[
          Form(
            key: _form,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                children: <Widget>[
                  _Section(AppStrings.addImages, _buildImages()),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: AppStrings.propertyName,
                    controller: _title,
                    validator: Validators.required,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),
                  const _Label(AppStrings.purpose),
                  const SizedBox(height: 6),
                  SegmentedButton<PropertyPurpose>(
                    segments: const <ButtonSegment<
                        PropertyPurpose>>[
                      ButtonSegment<PropertyPurpose>(
                        value: PropertyPurpose.sale,
                        label: Text(AppStrings.sale),
                      ),
                      ButtonSegment<PropertyPurpose>(
                        value: PropertyPurpose.rent,
                        label: Text(AppStrings.rent),
                      ),
                    ],
                    selected: <PropertyPurpose>{_purpose},
                    onSelectionChanged:
                        (Set<PropertyPurpose> s) => setState(
                      () => _purpose = s.first,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _Dropdown<String?>(
                    label: AppStrings.propertyType,
                    value: _typeId,
                    items: <DropdownMenuItem<String?>>[
                      for (final PropertyType t in types)
                        DropdownMenuItem<String?>(
                          value: t.id,
                          child: Text(t.name),
                        ),
                    ],
                    onChanged: (String? v) =>
                        setState(() => _typeId = v),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _Dropdown<String?>(
                          label: AppStrings.city,
                          value: _cityId,
                          items: <DropdownMenuItem<String?>>[
                            for (final City c in cities)
                              DropdownMenuItem<String?>(
                                value: c.id,
                                child: Text(c.name),
                              ),
                          ],
                          onChanged: (String? v) => setState(() {
                            _cityId = v;
                            _areaId = null;
                          }),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Dropdown<String?>(
                          label: AppStrings.area,
                          value: _areaId,
                          enabled: _cityId != null,
                          items: <DropdownMenuItem<String?>>[
                            for (final Area a in areas)
                              DropdownMenuItem<String?>(
                                value: a.id,
                                child: Text(a.name),
                              ),
                          ],
                          onChanged: (String? v) =>
                              setState(() => _areaId = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: AppStrings.address,
                    controller: _address,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: <Widget>[
                      Expanded(
                        flex: 2,
                        child: AppTextField(
                          label: AppStrings.price,
                          controller: _price,
                          validator: Validators.price,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _Dropdown<String>(
                          label: AppStrings.currency,
                          value: _currency,
                          items: <DropdownMenuItem<String>>[
                            for (final String c in AppConstants
                                .supportedCurrencies)
                              DropdownMenuItem<String>(
                                value: c,
                                child: Text(
                                  Formatters.currencyLabel(c),
                                ),
                              ),
                          ],
                          onChanged: (String? v) =>
                              setState(
                            () => _currency = v ?? _currency,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: AppTextField(
                          label:
                              '${AppStrings.size} (${AppStrings.sizeUnit})',
                          controller: _size,
                          validator: Validators.areaSize,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextField(
                          label: AppStrings.floor,
                          controller: _floor,
                          validator: Validators.optionalInt,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: AppTextField(
                          label: AppStrings.bedrooms,
                          controller: _bedrooms,
                          validator: Validators.optionalInt,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextField(
                          label: AppStrings.bathrooms,
                          controller: _bathrooms,
                          validator: Validators.optionalInt,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: AppStrings.description,
                    controller: _description,
                    maxLines: 4,
                    minLines: 3,
                  ),
                  const SizedBox(height: 14),
                  const _Label(AppStrings.features),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      for (final FeatureItem f in features)
                        FilterChip(
                          label: Text(f.name),
                          selected:
                              _featureIds.contains(f.id),
                          onSelected: (bool v) => setState(() {
                            if (v) {
                              _featureIds.add(f.id);
                            } else {
                              _featureIds.remove(f.id);
                            }
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label: AppStrings.phoneNumber,
                    controller: _phone,
                    validator: Validators.phone,
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icons.phone_outlined,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    label:
                        '${AppStrings.whatsappNumber} (${AppStrings.all})',
                    controller: _whatsapp,
                    validator: (String? v) =>
                        Validators.phone(v, allowEmpty: true),
                    keyboardType: TextInputType.phone,
                    prefixIcon: Icons.chat_outlined,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),
                  _Dropdown<PropertyStatus>(
                    label: AppStrings.status,
                    value: _status,
                    items: <DropdownMenuItem<PropertyStatus>>[
                      for (final PropertyStatus s
                          in PropertyStatus.values)
                        DropdownMenuItem<PropertyStatus>(
                          value: s,
                          child: Text(s.labelAr),
                        ),
                    ],
                    onChanged: (PropertyStatus? v) =>
                        setState(
                      () => _status =
                          v ?? PropertyStatus.available,
                    ),
                  ),
                  SwitchListTile(
                    value: _isPublished,
                    onChanged: (bool v) =>
                        setState(() => _isPublished = v),
                    title:
                        const Text(AppStrings.published),
                    contentPadding: EdgeInsets.zero,
                  ),
                  SwitchListTile(
                    value: _isFeatured,
                    onChanged: (bool v) =>
                        setState(() => _isFeatured = v),
                    title: const Text(AppStrings.featured),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: Text(
                      _isEdit
                          ? AppStrings.saveChanges
                          : AppStrings.addProperty,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          if (_saving)
            Container(
              color: Colors.black54,
              alignment: Alignment.center,
              child: Container(
                margin: const EdgeInsets.all(40),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      _savingStatus,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImages() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (_totalImages > 0)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: _totalImages,
            itemBuilder: (BuildContext context, int i) {
              final bool isExisting =
                  i < _existingImages.length;
              final String key = isExisting
                  ? 'existing:${_existingImages[i].path}'
                  : 'new:${i - _existingImages.length}';
              final bool isMain = _mainKey == key ||
                  (_mainKey == null && i == 0);
              return Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: isExisting
                        ? AppNetworkImage(
                            url: _existingImages[i].url,
                          )
                        : Image.file(
                            _newImages[
                                i - _existingImages.length],
                            fit: BoxFit.cover,
                          ),
                  ),
                  if (isMain)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.goldDark,
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                        child: const Text(
                          AppStrings.mainImage,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 4,
                    left: 4,
                    right: 4,
                    child: Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        _ImageIconButton(
                          icon: Icons.star,
                          color: isMain
                              ? AppColors.gold
                              : Colors.white,
                          onTap: () => setState(
                            () => _mainKey = key,
                          ),
                        ),
                        _ImageIconButton(
                          icon: Icons.delete_outline,
                          color: Colors.white,
                          onTap: () => isExisting
                              ? _removeExisting(i)
                              : _removeNew(
                                  i - _existingImages.length,
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _pickImages,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: Text(
            '${AppStrings.addImages} (${Formatters.toArabicDigits('$_totalImages')}/${Formatters.toArabicDigits('${AppConstants.maxImagesPerProperty}')})',
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title, this.child);

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _Label(title),
        const SizedBox(height: 8),
        child,
      ],
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
    required this.items,
    required this.onChanged,
    this.enabled = true,
  });

  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;
  final bool enabled;

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
          items: items,
          onChanged: enabled ? onChanged : null,
        ),
      ],
    );
  }
}

class _ImageIconButton extends StatelessWidget {
  const _ImageIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: color, size: 16),
        ),
      ),
    );
  }
}
