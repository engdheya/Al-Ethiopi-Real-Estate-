import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_strings.dart';
import '../../models/property.dart';
import '../../providers/favorite_providers.dart';
import '../../theme/app_colors.dart';
import '../utils/formatters.dart';
import 'app_snackbar.dart';
import 'network_image.dart';
import 'rating_stars.dart';

/// Modern property card used across home, listings, search and favorites.
class PropertyCard extends ConsumerWidget {
  const PropertyCard({super.key, required this.property, this.onTap});

  final Property property;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isFavorite =
        ref.watch(isFavoriteProvider(property.id));
    final Property p = property;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Stack(
              children: <Widget>[
                AppNetworkImage(
                  url: p.mainImage?.url,
                  height: 175,
                  width: double.infinity,
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: _Badge(
                    text: p.purpose.labelAr,
                    color: p.purpose == PropertyPurpose.sale
                        ? AppColors.saleBadge
                        : AppColors.rentBadge,
                  ),
                ),
                if (p.isSoldOrRented)
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: _Badge(
                      text: p.status.labelAr,
                      color: p.status == PropertyStatus.sold
                          ? AppColors.statusSold
                          : AppColors.statusRented,
                    ),
                  ),
                if (p.isFeatured)
                  const Positioned(
                    bottom: 10,
                    left: 10,
                    child: _Badge(
                      text: '★ ${AppStrings.featured}',
                      color: AppColors.goldDark,
                    ),
                  ),
                Positioned(
                  top: 6,
                  left: 6,
                  child: Material(
                    color: Colors.black45,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => _toggleFavorite(context, ref),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          isFavorite
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: isFavorite
                              ? AppColors.favoriteRed
                              : Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    p.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: <Widget>[
                      const Icon(
                        Icons.location_on_outlined,
                        size: 15,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${p.typeName} • ${p.locationLabel}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          Formatters.formatPrice(p.price, p.currency),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      if (p.ratingCount > 0)
                        RatingStars(rating: p.ratingAvg, size: 14),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      _Spec(
                        icon: Icons.straighten,
                        label: Formatters.formatArea(p.size),
                      ),
                      if (p.bedrooms > 0) ...<Widget>[
                        const SizedBox(width: 14),
                        _Spec(
                          icon: Icons.bed_outlined,
                          label: Formatters.toArabicDigits(
                            p.bedrooms.toString(),
                          ),
                        ),
                      ],
                      if (p.bathrooms > 0) ...<Widget>[
                        const SizedBox(width: 14),
                        _Spec(
                          icon: Icons.bathtub_outlined,
                          label: Formatters.toArabicDigits(
                            p.bathrooms.toString(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleFavorite(BuildContext context, WidgetRef ref) async {
    try {
      final bool nowFavorite = await ref
          .read(favoriteActionsProvider)
          .toggle(property.id);
      if (context.mounted) {
        showSuccessSnack(
          context,
          nowFavorite ? AppStrings.favoriteAdded : AppStrings.favoriteRemoved,
        );
      }
    } catch (e) {
      if (context.mounted) showErrorSnack(context, e);
    }
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
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
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

class _Spec extends StatelessWidget {
  const _Spec({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
      ],
    );
  }
}
