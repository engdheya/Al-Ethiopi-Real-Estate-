import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase/firebase_providers.dart';
import 'auth_providers.dart';

/// Favorite property ids: Firestore for users, SharedPreferences for guests.
final StreamProvider<Set<String>> favoriteIdsProvider =
    StreamProvider<Set<String>>((Ref ref) {
  final String? uid = ref.watch(authStateProvider).valueOrNull?.uid;
  final repo = ref.watch(favoriteRepositoryProvider);
  if (uid == null) return repo.watchGuestFavorites();
  return repo.watchFavorites(uid);
});

final ProviderFamily<bool, String> isFavoriteProvider =
    ProviderFamily<bool, String>((Ref ref, String propertyId) {
  return ref.watch(favoriteIdsProvider).valueOrNull?.contains(propertyId) ??
      false;
});

class FavoriteActions {
  FavoriteActions(this._ref);

  final Ref _ref;

  /// Returns the new state (`true` = now a favorite).
  Future<bool> toggle(String propertyId) {
    final String? uid = _ref.read(authStateProvider).valueOrNull?.uid;
    return _ref.read(favoriteRepositoryProvider).toggleFavorite(
          uid: uid,
          propertyId: propertyId,
        );
  }

  Future<void> remove(String propertyId) {
    final String? uid = _ref.read(authStateProvider).valueOrNull?.uid;
    return _ref.read(favoriteRepositoryProvider).removeFavorite(
          uid: uid,
          propertyId: propertyId,
        );
  }
}

final Provider<FavoriteActions> favoriteActionsProvider =
    Provider<FavoriteActions>((Ref ref) => FavoriteActions(ref));
