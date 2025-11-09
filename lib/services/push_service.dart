// lib/services/push_service.dart
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Optional: if you want background messages to be handled,
/// this must be a top-level function (NOT inside a class).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized in background isolates
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  debugPrint('[FCM][BG] ${message.messageId} | ${message.data}');
}

class PushService {
  PushService._();
  static final PushService instance = PushService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  /// Call once in main() after Firebase.initializeApp(...)
  Future<void> init() async {
    // iOS/Apple permission prompt
    if (Platform.isIOS || Platform.isMacOS) {
      final settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
      );
      debugPrint('[FCM] iOS permission: ${settings.authorizationStatus}');
    }

    // Foreground presentation on Apple (so alerts show when app open)
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Optional: subscribe all users to a global topic
    try {
      await _fcm.subscribeToTopic('all');
    } catch (e) {
      debugPrint('[FCM] subscribeToTopic failed: $e');
    }

    // Print (or upload) the token for server use
    try {
      final token = await _fcm.getToken();
      debugPrint('[FCM] token: $token');
      // TODO: send `token` to your backend if you plan to target specific users
    } catch (e) {
      debugPrint('[FCM] getToken error: $e');
    }

    // Background handler (must be set once, typically in init)
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage m) {
      debugPrint('[FCM][FG] ${m.messageId} | title=${m.notification?.title}');
      // If you want a local notification pop-up here, integrate flutter_local_notifications
      // and show a notification from this callback.
    });

    // When user taps a notification and app comes to foreground
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage m) {
      debugPrint('[FCM][OPENED] ${m.messageId} | data=${m.data}');
      // TODO: Deep-link to your in-app "Notifications" screen if desired.
    });
  }
}
