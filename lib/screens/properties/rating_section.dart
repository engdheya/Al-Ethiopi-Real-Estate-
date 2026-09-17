import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/app_snackbar.dart';
import '../../core/widgets/rating_stars.dart';
import '../../l10n/app_strings.dart';
import '../../models/app_user.dart';
import '../../models/property.dart';
import '../../models/rating_entry.dart';
import '../../providers/auth_providers.dart';
import '../../providers/rating_providers.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';

/// Average rating display + the signed-in user's own rating input.
class RatingSection extends ConsumerWidget {
  const RatingSection({super.key, required this.property});

  final Property property;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppUser? user = ref.watch(currentUserProvider);
    final AsyncValue<RatingEntry?> myRating =
        ref.watch(myRatingProvider(property.id));

    return Container(
      width: double.infinity,
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
            AppStrings.rateProperty,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              RatingStars(
                rating: property.ratingAvg,
                size: 22,
                count: property.ratingCount,
              ),
              const Spacer(),
              if (property.ratingCount > 0)
                Text(
                  AppStrings.ratingsCount,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
            ],
          ),
          const Divider(height: 24),
          if (user == null)
            OutlinedButton.icon(
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.login),
              icon: const Icon(Icons.login, size: 18),
              label: const Text(AppStrings.loginRequired),
            )
          else
            myRating.when(
              data: (RatingEntry? rating) => Row(
                children: <Widget>[
                  const Text(
                    AppStrings.yourRating,
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 12),
                  RatingBar.builder(
                    initialRating:
                        (rating?.value ?? 0).toDouble(),
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: false,
                    itemCount: 5,
                    itemSize: 32,
                    unratedColor: AppColors.border,
                    itemBuilder: (BuildContext context, int _) =>
                        const Icon(
                      Icons.star,
                      color: AppColors.goldDark,
                    ),
                    onRatingUpdate: (double value) =>
                        _submit(context, ref, value.toInt()),
                  ),
                ],
              ),
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (Object e, StackTrace _) => Text(
                e.toString(),
                style: const TextStyle(color: AppColors.error),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _submit(
    BuildContext context,
    WidgetRef ref,
    int value,
  ) async {
    try {
      await ref.read(ratingActionsProvider).submit(property.id, value);
      if (context.mounted) {
        showSuccessSnack(context, AppStrings.ratingSaved);
      }
    } catch (e) {
      if (context.mounted) showErrorSnack(context, e);
    }
  }
}
