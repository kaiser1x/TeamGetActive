import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Call once from your root screen's initState.
  /// [onData] is invoked for every received message regardless of app state.
  Future<void> initialize({
    required void Function(RemoteMessage) onData,
  }) async {
    // --- Permission ---
    // Required on iOS always, required on Android 13+ (API 33+).
    // On older Android versions this is a no-op and always returns authorized.
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint(
      '[FCM] Permission status: ${settings.authorizationStatus}',
    );

    // --- Foreground ---
    // Fires when a message arrives while the app is open and in the foreground.
    // Without this listener the notification is silent on Android foreground.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[FCM] Foreground message id: ${message.messageId}');
      debugPrint('[FCM] Foreground notification: ${message.notification?.title}');
      debugPrint('[FCM] Foreground data: ${message.data}');
      onData(message);
    });

    // --- Background tap ---
    // Fires when the user taps a notification while the app is in the background
    // (but not terminated). The app comes to foreground and this stream emits.
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[FCM] Opened from background id: ${message.messageId}');
      debugPrint('[FCM] Opened notification: ${message.notification?.title}');
      debugPrint('[FCM] Opened data: ${message.data}');
      onData(message);
    });

    // --- Terminated tap ---
    // When the app is fully closed and the user taps a notification to launch it,
    // getInitialMessage() returns that message once after the app starts.
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('[FCM] Launched from terminated id: ${initialMessage.messageId}');
      debugPrint('[FCM] Initial notification: ${initialMessage.notification?.title}');
      debugPrint('[FCM] Initial data: ${initialMessage.data}');
      onData(initialMessage);
    }
  }

  /// Returns the FCM registration token for this device install.
  /// Will be null if Firebase is not initialized or there is no internet.
  Future<String?> getToken() async {
    final token = await _messaging.getToken();
    debugPrint('[FCM] Device token: $token');
    return token;
  }
}
