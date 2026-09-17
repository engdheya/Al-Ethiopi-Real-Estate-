import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../firebase/firebase_providers.dart';

/// Tiny typed wrapper over SharedPreferences (recent searches, flags).
class CacheService {
  CacheService(this._prefs);

  final SharedPreferences _prefs;

  List<String> recentSearches() {
    return _prefs.getStringList(AppConstants.prefsRecentSearches) ??
        const <String>[];
  }

  Future<void> addRecentSearch(String query) async {
    final String q = query.trim();
    if (q.length < 2) return;
    final List<String> list = recentSearches().toList()
      ..remove(q)
      ..insert(0, q);
    await _prefs.setStringList(
      AppConstants.prefsRecentSearches,
      list.take(AppConstants.maxRecentSearches).toList(),
    );
  }

  Future<void> clearRecentSearches() async {
    await _prefs.remove(AppConstants.prefsRecentSearches);
  }

  bool notificationsEnabled() {
    return _prefs.getBool(AppConstants.prefsNotificationsEnabled) ?? true;
  }

  Future<void> setNotificationsEnabled(bool value) async {
    await _prefs.setBool(AppConstants.prefsNotificationsEnabled, value);
  }
}

final Provider<CacheService> cacheServiceProvider =
    Provider<CacheService>((Ref ref) {
  return CacheService(ref.watch(sharedPreferencesProvider));
});
