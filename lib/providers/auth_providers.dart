import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase/firebase_providers.dart';
import '../models/app_user.dart';

/// Reactive auth session (null = guest).
final StreamProvider<AppUser?> authStateProvider =
    StreamProvider<AppUser?>((Ref ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

/// Current signed-in user or null (guest).
final Provider<AppUser?> currentUserProvider = Provider<AppUser?>((Ref ref) {
  return ref.watch(authStateProvider).valueOrNull;
});

/// True only when the Firebase Auth token carries `admin: true`.
/// Force-refreshes the token so a freshly granted claim applies immediately.
final FutureProvider<bool> isAdminProvider = FutureProvider<bool>((Ref ref) async {
  final AppUser? user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return false;
  return ref.watch(authRepositoryProvider).isAdmin(forceRefresh: true);
});
