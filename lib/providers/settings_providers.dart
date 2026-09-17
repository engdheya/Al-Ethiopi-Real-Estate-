import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../demo/demo_store.dart';
import '../firebase/firebase_providers.dart';
import '../models/app_notification.dart';
import '../models/app_settings.dart';

/// True when the app booted without Firebase (explicit demo banner in UI).
final Provider<bool> demoModeProvider = Provider<bool>((Ref ref) {
  return DemoStore.enabled;
});

final StreamProvider<AppSettings> appSettingsProvider =
    StreamProvider<AppSettings>((Ref ref) {
  return ref.watch(settingsRepositoryProvider).watchSettings();
});

final StreamProvider<List<AppNotification>> notificationsProvider =
    StreamProvider<List<AppNotification>>((Ref ref) {
  return ref.watch(notificationRepositoryProvider).watchNotifications();
});
