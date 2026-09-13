import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/app_failure.dart';
import '../firebase/firebase_providers.dart';
import '../l10n/app_strings.dart';
import '../models/app_user.dart';
import '../models/rating_entry.dart';
import 'auth_providers.dart';

/// The signed-in user's rating for a property (null = guest / not rated).
final StreamProviderFamily<RatingEntry?, String> myRatingProvider =
    StreamProviderFamily<RatingEntry?, String>((Ref ref, String propertyId) {
  final AppUser? user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream<RatingEntry?>.value(null);
  return ref
      .watch(ratingRepositoryProvider)
      .watchMyRating(propertyId, user.uid);
});

class RatingActions {
  RatingActions(this._ref);

  final Ref _ref;

  Future<void> submit(String propertyId, int value) async {
    final AppUser? user = _ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      throw const AppFailure(AppStrings.loginRequiredToComment);
    }
    final int clamped = value.clamp(1, 5);
    await _ref.read(ratingRepositoryProvider).submitRating(
          propertyId: propertyId,
          uid: user.uid,
          value: clamped,
        );
  }
}

final Provider<RatingActions> ratingActionsProvider =
    Provider<RatingActions>((Ref ref) => RatingActions(ref));
