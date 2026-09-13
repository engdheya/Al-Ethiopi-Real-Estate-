import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/contact_utils.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/share_helper.dart';
import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/network_image.dart';
import '../../core/widgets/offline_banner.dart';
import '../../core/widgets/rating_stars.dart';
import '../../firebase/firebase_providers.dart';
import '../../l10n/app_strings.dart';
import '../../models/property.dart';
import '../../providers/auth_providers.dart';
import '../../providers/favorite_providers.dart';
import '../../providers/property_providers.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import 'comments_widgets.dart';
import 'rating_section.dart';

/// Complete property details: gallery, specs, contact, rating, comments.
class PropertyDetailsScreen extends ConsumerWidget {
  const PropertyDetailsScreen({super.key, required this.propertyId});

  final String propertyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Property?> async =
        ref.watch(propertyDetailsProvider(propertyId));

    return Scaffold(
      body: async.when(
        data: (Property? property) {
          if (property == null) {
            return SafeArea(
              child: Column(
                children: <Widget>[
                  AppBar(
                    title: const Text(AppStrings.navProperties),
                  ),
                  const Expanded(
                    child: EmptyState(
                      icon: Icons.home_work_outlined,
                      title: 'العقار غير موجود أو تم حذفه.',
                    ),
                  ),
                ],
              ),
            );
          }
          return _DetailsBody(property: property);
        },
        loading: () => const SafeArea(
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (Object e, StackTrace _) => SafeArea(
          child: Column(
            children: <Widget>[
              AppBar(title: const Text(AppStrings.navProperties)),
              Expanded(
                child: ErrorState(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(
                    propertyDetailsProvider(propertyId),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailsBody extends ConsumerStatefulWidget {
  const _DetailsBody({required this.property});

  final Property property;

  @override
  ConsumerState<_DetailsBody> createState() => _DetailsBodyState();
}

class _DetailsBodyState extends ConsumerState<_DetailsBody> {
  final PageController _galleryController = PageController();
  int _galleryIndex = 0;

  @override
  void dispose() {
    _galleryController.dispose();
    super.dispose();
  }

  Property get p => widget.property;

  @override
  Widget build(BuildContext context) {
    final bool isFavorite =
        ref.watch(isFavoriteProvider(p.id));
    final bool isAdmin =
        ref.watch(isAdminProvider).valueOrNull ?? false;

    return Column(
      children: <Widget>[
        const DemoBanner(),
        const OfflineBanner(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(propertyDetailsProvider(p.id));
            },
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _buildGallery(context, isFavorite, isAdmin),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _buildTitle(),
                        const SizedBox(height: 12),
                        _buildPriceCard(),
                        const SizedBox(height: 16),
                        _buildSpecs(),
                        const SizedBox(height: 16),
                        _buildDescription(),
                        const SizedBox(height: 16),
                        _buildFeatures(),
                        const SizedBox(height: 16),
                        _buildAdvertiserCard(context),
                        const SizedBox(height: 12),
                        _buildActionsRow(context, isFavorite),
                        const SizedBox(height: 8),
                        RatingSection(property: p),
                        const SizedBox(height: 8),
                        CommentsSection(propertyId: p.id),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        _buildBottomBar(context),
      ],
    );
  }

  // ---------------------------------------------------------------- gallery

  Widget _buildGallery(
    BuildContext context,
    bool isFavorite,
    bool isAdmin,
  ) {
    final List<PropertyImage> images = p.images;
    return SizedBox(
      height: 300,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (images.isEmpty)
            const AppNetworkImage(url: null)
          else
            PageView.builder(
              controller: _galleryController,
              itemCount: images.length,
              onPageChanged: (int i) =>
                  setState(() => _galleryIndex = i),
              itemBuilder: (BuildContext context, int i) {
                return GestureDetector(
                  onTap: () => AppRoutes.openGallery(
                    context,
                    images: images,
                    initialIndex: i,
                  ),
                  child: AppNetworkImage(url: images[i].url),
                );
              },
            ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: <Color>[
                    Colors.black.withOpacity(0.55),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  child: Row(
                    children: <Widget>[
                      _CircleButton(
                        icon: Icons.arrow_back,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const Spacer(),
                      if (isAdmin)
                        _CircleButton(
                          icon: Icons.edit,
                          onTap: () =>
                              Navigator.of(context).pushNamed(
                            AppRoutes.propertyForm,
                            arguments: PropertyFormArgs(p.id),
                          ),
                        ),
                      _CircleButton(
                        icon: Icons.share_outlined,
                        onTap: () => _shareProperty(),
                      ),
                      _CircleButton(
                        icon: isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: isFavorite
                            ? AppColors.favoriteRed
                            : Colors.white,
                        onTap: () =>
                            _toggleFavorite(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            right: 12,
            child: Row(
              children: <Widget>[
                _Badge(
                  text: p.purpose.labelAr,
                  color: p.purpose == PropertyPurpose.sale
                      ? AppColors.saleBadge
                      : AppColors.rentBadge,
                ),
                const SizedBox(width: 8),
                _Badge(
                  text: p.status.labelAr,
                  color: _statusColor(p.status),
                ),
              ],
            ),
          ),
          if (images.length > 1)
            Positioned(
              bottom: 12,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  for (int i = 0; i < images.length; i++)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _galleryIndex ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _galleryIndex
                            ? Colors.white
                            : Colors.white54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                ],
              ),
            ),
          if (images.isNotEmpty)
            Positioned(
              top: 70,
              left: 12,
              child: _Badge(
                text:
                    '${Formatters.toArabicDigits((_galleryIndex + 1).toString())} / ${Formatters.toArabicDigits(images.length.toString())}',
                color: Colors.black54,
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- content

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (p.isFeatured)
          const Row(
            children: <Widget>[
              Icon(Icons.star, color: AppColors.goldDark, size: 18),
              SizedBox(width: 4),
              Text(
                AppStrings.featured,
                style: TextStyle(
                  color: AppColors.goldDark,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        Text(
          p.title,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: <Widget>[
            const Icon(
              Icons.location_on_outlined,
              size: 17,
              color: AppColors.textMuted,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                '${p.typeName} • ${p.locationLabel}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            if (p.ratingCount > 0)
              RatingStars(
                rating: p.ratingAvg,
                count: p.ratingCount,
              )
            else
              const Text(
                AppStrings.noRatingYet,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textMuted,
                ),
              ),
            const SizedBox(width: 12),
            const Icon(
              Icons.comment_outlined,
              size: 16,
              color: AppColors.textMuted,
            ),
            const SizedBox(width: 4),
            Text(
              '${Formatters.toArabicDigits(p.commentsCount.toString())} ${AppStrings.comments}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${AppStrings.price} ${p.purpose.labelAr}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  Formatters.formatPrice(p.price, p.currency),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: <Widget>[
                const Icon(
                  Icons.straighten,
                  color: AppColors.gold,
                ),
                const SizedBox(height: 4),
                Text(
                  Formatters.formatArea(p.size),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecs() {
    final List<_Spec> specs = <_Spec>[
      _Spec(
        icon: Icons.category_outlined,
        label: AppStrings.propertyType,
        value: p.typeName,
      ),
      _Spec(
        icon: Icons.sell_outlined,
        label: AppStrings.purpose,
        value: p.purpose.labelAr,
      ),
      _Spec(
        icon: Icons.flag_outlined,
        label: AppStrings.status,
        value: p.status.labelAr,
      ),
      _Spec(
        icon: Icons.location_city_outlined,
        label: AppStrings.city,
        value: p.cityName,
      ),
      _Spec(
        icon: Icons.map_outlined,
        label: AppStrings.area,
        value: p.areaName,
      ),
      if (p.bedrooms > 0)
        _Spec(
          icon: Icons.bed_outlined,
          label: AppStrings.bedrooms,
          value: Formatters.toArabicDigits(p.bedrooms.toString()),
        ),
      if (p.bathrooms > 0)
        _Spec(
          icon: Icons.bathtub_outlined,
          label: AppStrings.bathrooms,
          value: Formatters.toArabicDigits(p.bathrooms.toString()),
        ),
      if (p.floor != null)
        _Spec(
          icon: Icons.layers_outlined,
          label: AppStrings.floor,
          value: Formatters.toArabicDigits(p.floor.toString()),
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          AppStrings.specifications,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.6,
          ),
          itemCount: specs.length,
          itemBuilder: (BuildContext context, int i) {
            final _Spec s = specs[i];
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: <Widget>[
                  Icon(s.icon,
                      color: AppColors.primary, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          s.label,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                        Text(
                          s.value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        if (p.address.isNotEmpty) ...<Widget>[
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              const Icon(
                Icons.pin_drop_outlined,
                size: 17,
                color: AppColors.primary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${AppStrings.address}: ${p.address}',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDescription() {
    if (p.description.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          AppStrings.description,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          p.description,
          style: const TextStyle(
            fontSize: 14.5,
            height: 1.8,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatures() {
    if (p.featureNames.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          AppStrings.features,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final String f in p.featureNames)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      f,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdvertiserCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            AppStrings.contactInfo,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.real_estate_agent_outlined,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      AppStrings.appName,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    if (p.phone.isNotEmpty)
                      Text(
                        p.phone,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                        textDirection: TextDirection.ltr,
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: p.phone.isEmpty
                      ? null
                      : () => ContactUtils.callPhone(context, p.phone),
                  icon: const Icon(Icons.call_outlined, size: 19),
                  label: const Text(AppStrings.callNow),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (p.whatsapp.isEmpty && p.phone.isEmpty)
                      ? null
                      : () => ContactUtils.openWhatsApp(
                            context,
                            p.whatsapp.isEmpty
                                ? p.phone
                                : p.whatsapp,
                            message: AppStrings
                                .whatsappPropertyInquiry(p.title),
                          ),
                  icon: const Icon(Icons.chat_outlined, size: 19),
                  label: const Text(AppStrings.whatsapp),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionsRow(BuildContext context, bool isFavorite) {
    return Row(
      children: <Widget>[
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _toggleFavorite(context),
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              size: 19,
            ),
            label: Text(
              isFavorite ? AppStrings.saved : AppStrings.save,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _shareProperty,
            icon: const Icon(Icons.share_outlined, size: 19),
            label: const Text(AppStrings.share),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: <Widget>[
            Expanded(
              child: ElevatedButton.icon(
                onPressed: p.phone.isEmpty
                    ? null
                    : () => ContactUtils.callPhone(context, p.phone),
                icon: const Icon(Icons.call_outlined, size: 19),
                label: const Text(AppStrings.callNow),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: (p.whatsapp.isEmpty && p.phone.isEmpty)
                    ? null
                    : () => ContactUtils.openWhatsApp(
                          context,
                          p.whatsapp.isEmpty ? p.phone : p.whatsapp,
                          message: AppStrings.whatsappPropertyInquiry(
                            p.title,
                          ),
                        ),
                icon: const Icon(Icons.chat_outlined, size: 19),
                label: const Text(AppStrings.whatsapp),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- actions

  Future<void> _toggleFavorite(BuildContext context) async {
    try {
      final bool nowFavorite =
          await ref.read(favoriteActionsProvider).toggle(p.id);
      if (context.mounted) {
        showSuccessSnack(
          context,
          nowFavorite
              ? AppStrings.favoriteAdded
              : AppStrings.favoriteRemoved,
        );
      }
    } catch (e) {
      if (context.mounted) showErrorSnack(context, e);
    }
  }

  Future<void> _shareProperty() async {
    final String? choice = await showModalBottomSheet<String>(
      context: context,
      builder: (BuildContext sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text(AppStrings.shareViaApps),
              onTap: () => Navigator.of(sheetContext).pop('share'),
            ),
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: const Text(AppStrings.copyTextLabel),
              onTap: () => Navigator.of(sheetContext).pop('copy'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!context.mounted) {
      return;
    }
    if (choice == 'copy') {
      await ShareHelper.copyText(
        context,
        AppStrings.sharePropertyText(
          title: p.title,
          priceText: Formatters.formatPrice(p.price, p.currency),
          location: '${p.cityName} - ${p.areaName}',
          playStoreUrl: AppConstants.playStoreUrl,
        ),
      );
      return;
    }
    if (choice == 'share') {
      await ShareHelper.shareProperty(
        title: p.title,
        price: p.price,
        currency: p.currency,
        cityName: p.cityName,
        areaName: p.areaName,
      );
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

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.color = Colors.white,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.black45,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Icon(icon, color: color, size: 21),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Spec {
  const _Spec({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}

/// Admin overflow actions (edit / publish / feature / delete).
class AdminPropertyMenu extends ConsumerWidget {
  const AdminPropertyMenu({super.key, required this.property});

  final Property property;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isAdmin =
        ref.watch(isAdminProvider).valueOrNull ?? false;
    if (!isAdmin) return const SizedBox.shrink();
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (String value) =>
          _handle(context, ref, value),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'edit',
          child: Text(AppStrings.editProperty),
        ),
        PopupMenuItem<String>(
          value: 'publish',
          child: Text(
            property.isPublished
                ? AppStrings.unpublish
                : AppStrings.publish,
          ),
        ),
        PopupMenuItem<String>(
          value: 'featured',
          child: Text(
            property.isFeatured
                ? AppStrings.unmarkFeatured
                : AppStrings.markFeatured,
          ),
        ),
        const PopupMenuItem<String>(
          value: 'delete',
          child: Text(
            AppStrings.deleteProperty,
            style: TextStyle(color: AppColors.error),
          ),
        ),
      ],
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
          break;
        case 'publish':
          await repo.setPublished(
            property.id,
            !property.isPublished,
          );
          if (context.mounted) {
            showSuccessSnack(context, AppStrings.propertySaved);
          }
          break;
        case 'featured':
          await repo.setFeatured(
            property.id,
            !property.isFeatured,
          );
          if (context.mounted) {
            showSuccessSnack(context, AppStrings.propertySaved);
          }
          break;
        case 'delete':
          final bool confirm = await showConfirmDialog(
            context,
            title: AppStrings.deleteProperty,
            message: AppStrings.deletePropertyConfirm,
          );
          if (!confirm) return;
          final storageRepo = ref.read(storageRepositoryProvider);
          for (final PropertyImage img in property.images) {
            await storageRepo.deleteImage(img.path);
          }
          await repo.deleteProperty(property.id);
          if (context.mounted) {
            showSuccessSnack(context, AppStrings.propertyDeleted);
            Navigator.of(context).pop();
          }
          break;
      }
    } catch (e) {
      if (context.mounted) showErrorSnack(context, e);
    }
  }
}
