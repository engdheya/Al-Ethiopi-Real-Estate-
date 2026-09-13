import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../firebase/firebase_providers.dart';

/// Background/terminated-state FCM handler. Must stay a top-level function.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('FCM background init failed: $e');
  }
  debugPrint('FCM background message: ${message.messageId}');
}

/// Firebase Cloud Messaging + local-notifications glue.
///
///  * Foreground messages are rendered as local notifications.
///  * Tapping any notification deep-opens the linked property when present.
///  * Every device subscribes to `all_users` + `featured_properties` topics.
class NotificationService {
  NotificationService({FirebaseMessaging? messaging}) : _messaging = messaging;

  final FirebaseMessaging? _messaging;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    AppConstants.fcmChannelId,
    AppConstants.fcmChannelName,
    description: 'إشعارات العقارات المميزة والإعلانات المهمة',
    importance: Importance.high,
  );

  Future<void> initialize({
    required void Function(String? propertyId) onOpenProperty,
  }) async {
    final FirebaseMessaging? messaging = _messaging;
    if (_initialized || messaging == null) return;
    _initialized = true;

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings =
        InitializationSettings(android: androidSettings);
    await _local.initialize(
      settings,
      onDidReceiveNotificationResponse:
          (NotificationResponse response) {
        onOpenProperty(response.payload?.isEmpty == true
            ? null
            : response.payload);
      },
    );

    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showForeground(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      onOpenProperty(message.data['propertyId'] as String?);
    });

    final RemoteMessage? initial = await messaging.getInitialMessage();
    if (initial != null) {
      onOpenProperty(initial.data['propertyId'] as String?);
    }
  }

  /// Asks for notification permission (Android 13+) and subscribes to topics.
  /// Returns the FCM token (null when notifications are disabled).
  Future<String?> enableNotifications() async {
    final FirebaseMessaging? messaging = _messaging;
    if (messaging == null) return null;
    try {
      final NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return null;
      }
      await messaging.subscribeToTopic(AppConstants.fcmTopicAll);
      await messaging.subscribeToTopic(AppConstants.fcmTopicFeatured);
      return await messaging.getToken();
    } catch (e) {
      debugPrint('enableNotifications failed: $e');
      return null;
    }
  }

  Future<void> _showForeground(RemoteMessage message) async {
    final RemoteNotification? notification = message.notification;
    if (notification == null) return;
    final String? propertyId = message.data['propertyId'] as String?;
    await _local.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(
            notification.body ?? '',
          ),
        ),
      ),
      payload: propertyId ?? '',
    );
  }
}

final Provider<NotificationService> notificationServiceProvider =
    Provider<NotificationService>((Ref ref) {
  return NotificationService(messaging: ref.watch(firebaseMessagingProvider));
});
