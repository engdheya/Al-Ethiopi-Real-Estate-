import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'demo/demo_store.dart';
import 'firebase/firebase_providers.dart';
import 'routes/app_routes.dart';
import 'services/notification_service.dart';

/// Application bootstrap.
///
/// Tries to initialize Firebase (Android reads `google-services.json`
/// automatically). When Firebase is unavailable the app boots into an
/// explicit demo mode instead of crashing, so UI evaluation can continue.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final SharedPreferences prefs = await SharedPreferences.getInstance();

  bool firebaseReady = false;
  try {
    await Firebase.initializeApp();
    AppBackend.firestore = FirebaseFirestore.instance;
    AppBackend.auth = FirebaseAuth.instance;
    AppBackend.storage = FirebaseStorage.instance;
    AppBackend.messaging = FirebaseMessaging.instance;

    // Offline persistence: previously loaded data stays usable offline.
    AppBackend.firestore!.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    // Play Integrity (release) / debug token (debug builds).
    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider: kDebugMode
            ? AndroidProvider.debug
            : AndroidProvider.playIntegrity,
      );
    } catch (e) {
      debugPrint('App Check activation skipped: $e');
    }

    firebaseReady = true;
  } catch (e) {
    debugPrint('Firebase unavailable, enabling demo mode: $e');
    DemoStore.enabled = true;
  }

  final ProviderContainer container = ProviderContainer(
    overrides: <Override>[
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
  );

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const AlEthiopiApp(),
    ),
  );

  if (firebaseReady) {
    await _initMessaging(container);
  }
}

Future<void> _initMessaging(ProviderContainer container) async {
  try {
    await container.read(notificationServiceProvider).initialize(
      onOpenProperty: (String? propertyId) {
        final NavigatorState? navigator = rootNavigatorKey.currentState;
        if (navigator == null) return;
        if (propertyId != null && propertyId.isNotEmpty) {
          navigator.pushNamed(
            AppRoutes.propertyDetails,
            arguments: PropertyDetailsArgs(propertyId),
          );
        } else {
          navigator.pushNamed(AppRoutes.notifications);
        }
      },
    );

    // Keep the stored FCM token fresh for push targeting.
    FirebaseMessaging.instance.onTokenRefresh.listen((String token) async {
      final String? uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null || token.isEmpty) return;
      try {
        await container
            .read(authRepositoryProvider)
            .saveFcmToken(uid, token);
      } catch (e) {
        debugPrint('saveFcmToken failed: $e');
      }
    });
  } catch (e) {
    debugPrint('Messaging init failed: $e');
  }
}
