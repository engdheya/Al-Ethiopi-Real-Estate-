import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../core/widgets/loading_skeleton.dart';
import '../../core/widgets/property_card.dart';
import '../../l10n/app_strings.dart';
import '../../models/property.dart';
import '../../providers/property_providers.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../main/main_shell.dart';

/// "المفضلة" — Firestore for users, local storage for guests.
class FavoritesTab extends ConsumerWidget {
  const FavoritesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Property>> async =
        ref.watch(favoritePropertiesProvider);

    return Column(
      children: <Widget>[
        Container(
          width: double.infinity,
          color: AppColors.primary,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: const Text(
            AppStrings.navFavorites,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: async.when(
            data: (List<Property> items) {
              if (items.isEmpty) {
                return EmptyState(
                  icon: Icons.favorite_border,
                  title: AppStrings.noFavorites,
                  subtitle: AppStrings.noFavoritesHint,
                  actionLabel: AppStrings.navProperties,
                  onAction: () => ref
                      .read(mainTabIndexProvider.notifier)
                      .state = 1,
                );
              }
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(favoritePropertiesProvider);
                },
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder:
                      (BuildContext context, int _) =>
                          const SizedBox(height: 12),
                  itemBuilder: (BuildContext context, int i) {
                    return PropertyCard(
                      property: items[i],
                      onTap: () => AppRoutes.openProperty(
                        context,
                        items[i].id,
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const SkeletonList(count: 2),
            error: (Object e, StackTrace _) => ErrorState(
              message: e.toString(),
              onRetry: () =>
                  ref.invalidate(favoritePropertiesProvider),
            ),
          ),
        ),
      ],
    );
  }
}
