/// Application-wide constants.
class AppConstants {
  AppConstants._();

  static const String appNameAr = 'الأثيوبي للعقارات';
  static const String appNameEn = 'Al-Ethiopi Real Estate';
  static const String androidApplicationId = 'com.alethiopi.realestate';

  /// Placeholder Play Store link used when sharing a property.
  /// Replace with the real link after publishing on Google Play.
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=$androidApplicationId';

  // Pagination
  static const int propertiesPageSize = 12;
  static const int commentsPageSize = 20;
  static const int adminPageSize = 20;

  // Limits / validation
  static const int maxImagesPerProperty = 12;
  static const int maxImageUploadBytes = 5 * 1024 * 1024; // 5 MB
  static const int maxAvatarUploadBytes = 2 * 1024 * 1024; // 2 MB
  static const int maxCommentLength = 1000;
  static const int maxNameLength = 60;
  static const int maxMessageLength = 2000;
  static const int maxRecentSearches = 10;

  // Currencies
  static const String currencyYER = 'YER';
  static const String currencyUSD = 'USD';
  static const String currencySAR = 'SAR';
  static const String defaultCurrency = currencyYER;
  static const List<String> supportedCurrencies = <String>[
    currencyYER,
    currencyUSD,
    currencySAR,
  ];

  // FCM topics
  static const String fcmTopicAll = 'all_users';
  static const String fcmTopicFeatured = 'featured_properties';
  static const String fcmChannelId = 'alethiopi_default';
  static const String fcmChannelName = 'تنبيهات الأثيوبي للعقارات';

  // Local storage keys (SharedPreferences)
  static const String prefsGuestFavorites = 'guest_favorites_v1';
  static const String prefsRecentSearches = 'recent_searches_v1';
  static const String prefsNotificationsEnabled = 'notifications_enabled_v1';

  // Yemen dialing
  static const String yemenCountryCode = '967';

  // Asset paths
  static const String assetLogo = 'assets/branding/logo.png';
  static const String assetDefaultProperty =
      'assets/images/default_property.png';
}
