import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/app_logo.dart';
import '../../core/widgets/loading_skeleton.dart';
import '../../core/widgets/network_image.dart';
import '../../core/widgets/property_card.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/type_icon.dart';
import '../../l10n/app_strings.dart';
import '../../models/city.dart';
import '../../models/property.dart';
import '../../models/property_filter.dart';
import '../../models/property_type.dart';
import '../../providers/filter_provider.dart';
import '../../providers/lookup_providers.dart';
import '../../providers/property_providers.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../main/main_shell.dart';

/// Home tab: hero, quick actions, categories, featured / latest / rent / land.
class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  void _openProperties(WidgetRef ref, PropertyFilter filter) {
    ref.read(propertyFilterProvider.notifier).set(filter);
    ref.read(mainTabIndexProvider.notifier).state = 1;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(featuredPropertiesProvider);
        ref.invalidate(latestPropertiesProvider);
        ref.invalidate(rentPropertiesProvider);
        ref.invalidate(landsForSaleProvider);
      },
      child: CustomScrollView(
        slivers: <Widget>[
          SliverToBoxAdapter(child: _Header(ref)),
          SliverToBoxAdapter(
            child: _HeroCard(
              onRent: () => _openProperties(
                ref,
                const PropertyFilter(purpose: PropertyPurpose.rent),
              ),
              onSale: () => _openProperties(
                ref,
                const PropertyFilter(purpose: PropertyPurpose.sale),
              ),
            ),
          ),
          SliverToBoxAdapter(child: _QuickActions(ref)),
          SliverToBoxAdapter(
            child: _Categories(
              onSelect: (PropertyType t) => _openProperties(
                ref,
                PropertyFilter(typeId: t.id),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _HorizontalSection(
              title: AppStrings.featuredProperties,
              provider: featuredPropertiesProvider,
              onViewAll: () => _openProperties(
                ref,
                const PropertyFilter(onlyFeatured: true),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _HorizontalSection(
              title: AppStrings.apartmentsForRent,
              provider: rentPropertiesProvider,
              onViewAll: () => _openProperties(
                ref,
                const PropertyFilter(purpose: PropertyPurpose.rent),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _LandsSection(
              onViewAll: () => _openProperties(
                ref,
                const PropertyFilter(purpose: PropertyPurpose.sale),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _PopularCities(
              onSelect: (City c) => _openProperties(
                ref,
                PropertyFilter(cityId: c.id),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _LatestSection(
              onViewAll: () => _openProperties(
                ref,
                const PropertyFilter(),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ header

class _Header extends ConsumerWidget {
  const _Header(this.ref);

  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              const AppLogoMark(size: 46, radius: 12),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      AppStrings.appName,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      AppStrings.appNameEn,
                      style: TextStyle(
                        color: AppColors.goldSoft,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context)
                    .pushNamed(AppRoutes.notifications),
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () =>
                Navigator.of(context).pushNamed(AppRoutes.search),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 13,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: <Widget>[
                  Icon(Icons.search, color: AppColors.primary),
                  SizedBox(width: 10),
                  Text(
                    AppStrings.searchHint,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
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
}

// --------------------------------------------------------------------- hero

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.onRent, required this.onSale});

  final VoidCallback onRent;
  final VoidCallback onSale;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: const DecorationImage(
          image: AssetImage('assets/images/default_property.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.55),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              AppStrings.heroTitle,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              AppStrings.heroSubtitle,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onRent,
                    icon: const Icon(Icons.key_outlined, size: 18),
                    label: const Text(AppStrings.quickRent),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.primaryDarker,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onSale,
                    icon: const Icon(Icons.sell_outlined, size: 18),
                    label: const Text(AppStrings.quickSale),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ quick actions

class _QuickActions extends StatelessWidget {
  const _QuickActions(this.ref);

  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    void openProperties(PropertyFilter filter) {
      ref.read(propertyFilterProvider.notifier).set(filter);
      ref.read(mainTabIndexProvider.notifier).state = 1;
    }

    final List<_QuickAction> actions = <_QuickAction>[
      _QuickAction(
        icon: Icons.key_outlined,
        label: AppStrings.quickRent,
        onTap: () => openProperties(
          const PropertyFilter(purpose: PropertyPurpose.rent),
        ),
      ),
      _QuickAction(
        icon: Icons.sell_outlined,
        label: AppStrings.quickSale,
        onTap: () => openProperties(
          const PropertyFilter(purpose: PropertyPurpose.sale),
        ),
      ),
      _QuickAction(
        icon: Icons.favorite_border,
        label: AppStrings.quickFavorites,
        onTap: () =>
            ref.read(mainTabIndexProvider.notifier).state = 2,
      ),
      _QuickAction(
        icon: Icons.headset_mic_outlined,
        label: AppStrings.quickContact,
        onTap: () =>
            Navigator.of(context).pushNamed(AppRoutes.contact),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Row(
        children: <Widget>[
          for (final _QuickAction a in actions)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  onTap: a.onTap,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: <Widget>[
                        Icon(a.icon,
                            color: AppColors.primary, size: 26),
                        const SizedBox(height: 6),
                        Text(
                          a.label,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuickAction {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
}

// -------------------------------------------------------------- categories

class _Categories extends ConsumerWidget {
  const _Categories({required this.onSelect});

  final void Function(PropertyType type) onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<PropertyType>> async =
        ref.watch(propertyTypesProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SectionHeader(
            title: AppStrings.browseCategories,
            onViewAll: () => ref
                .read(mainTabIndexProvider.notifier)
                .state = 1,
          ),
          const SizedBox(height: 12),
          async.when(
            data: (List<PropertyType> types) {
              if (types.isEmpty) return const SizedBox.shrink();
              return SizedBox(
                height: 104,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: types.length,
                  separatorBuilder: (BuildContext context, int _) =>
                      const SizedBox(width: 10),
                  itemBuilder: (BuildContext context, int i) {
                    final PropertyType t = types[i];
                    return InkWell(
                      onTap: () => onSelect(t),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 86,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border:
                              Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                color: AppColors.primarySoft,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                typeIconFromName(t.icon),
                                color: AppColors.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              t.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const SizedBox(
              height: 104,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (Object e, StackTrace _) =>
                const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------- horizontal sections

class _HorizontalSection extends ConsumerWidget {
  const _HorizontalSection({
    required this.title,
    required this.provider,
    required this.onViewAll,
  });

  final String title;
  final StreamProvider<List<Property>> provider;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Property>> async = ref.watch(provider);
    return async.when(
      data: (List<Property> items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 0, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: SectionHeader(
                  title: title,
                  onViewAll: onViewAll,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 348,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 16),
                  itemCount: items.length,
                  separatorBuilder: (BuildContext context, int _) =>
                      const SizedBox(width: 12),
                  itemBuilder: (BuildContext context, int i) {
                    return SizedBox(
                      width: 280,
                      child: PropertyCard(
                        property: items[i],
                        onTap: () => AppRoutes.openProperty(
                          context,
                          items[i].id,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (Object e, StackTrace _) => const SizedBox.shrink(),
    );
  }
}

class _LandsSection extends ConsumerWidget {
  const _LandsSection({required this.onViewAll});

  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Property>> async =
        ref.watch(landsForSaleProvider);
    return async.when(
      data: (List<Property> items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 0, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: SectionHeader(
                  title: AppStrings.landsForSale,
                  onViewAll: onViewAll,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 348,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 16),
                  itemCount: items.length,
                  separatorBuilder: (BuildContext context, int _) =>
                      const SizedBox(width: 12),
                  itemBuilder: (BuildContext context, int i) {
                    return SizedBox(
                      width: 280,
                      child: PropertyCard(
                        property: items[i],
                        onTap: () => AppRoutes.openProperty(
                          context,
                          items[i].id,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (Object e, StackTrace _) => const SizedBox.shrink(),
    );
  }
}

// ------------------------------------------------------------ popular cities

class _PopularCities extends ConsumerWidget {
  const _PopularCities({required this.onSelect});

  final void Function(City city) onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<City>> async = ref.watch(citiesProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SectionHeader(title: AppStrings.popularCities),
          const SizedBox(height: 12),
          async.when(
            data: (List<City> cities) {
              if (cities.isEmpty) return const SizedBox.shrink();
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  for (final City c in cities.take(8))
                    InkWell(
                      onTap: () => onSelect(c),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            const Icon(
                              Icons.location_city_outlined,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              c.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (Object e, StackTrace _) =>
                const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ latest

class _LatestSection extends ConsumerWidget {
  const _LatestSection({required this.onViewAll});

  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Property>> async =
        ref.watch(latestPropertiesProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SectionHeader(
            title: AppStrings.latestProperties,
            onViewAll: onViewAll,
          ),
          const SizedBox(height: 12),
          async.when(
            data: (List<Property> items) {
              if (items.isEmpty) return const SizedBox.shrink();
              return Column(
                children: <Widget>[
                  for (final Property p in items.take(4)) ...<Widget>[
                    PropertyCard(
                      property: p,
                      onTap: () =>
                          AppRoutes.openProperty(context, p.id),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              );
            },
            loading: () => const PropertyCardSkeleton(),
            error: (Object e, StackTrace _) =>
                const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// Re-exported for the pre-compiled hero image reference.
class HomeHeroImage extends StatelessWidget {
  const HomeHeroImage({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppNetworkImage(
      url: 'assets/images/default_property.png',
    );
  }
}
