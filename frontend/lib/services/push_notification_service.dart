import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'auth_service.dart';

/// Must be a top-level function (not a class method) per firebase_messaging requirements.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Runs in a separate isolate when the app is backgrounded/terminated.
  // Kept minimal -- the OS already shows the system notification.
}

class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static final AuthService _authService = AuthService();

  /// Call once after Firebase.initializeApp() and after the user is logged in.
  static Future<void> initialize() async {
    try {
      final settings = await _messaging.requestPermission(alert: true, badge: true, sound: true);
      debugPrint('[Push] Permission status: ${settings.authorizationStatus}');
    } catch (e, st) {
      debugPrint('[Push] requestPermission() threw: $e');
      debugPrint('$st');
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    try {
      await _localNotifications.initialize(
        const InitializationSettings(android: androidInit, iOS: iosInit),
      );
    } catch (e) {
      debugPrint('[Push] Local notifications init failed: $e');
    }

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Foreground messages: FCM does not auto-show a system tray notification
    // while the app is open, so we display one via flutter_local_notifications.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[Push] Foreground message received: ${message.notification?.title}');
      final notification = message.notification;
      if (notification != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'gas_cylinder_channel',
              'Order Updates',
              channelDescription: 'Notifications about your gas cylinder orders, payments, and deliveries.',
              importance: Importance.high,
              priority: Priority.high,
            ),
            iOS: DarwinNotificationDetails(),
          ),
        );
      }
    });

    await syncTokenWithBackend();
    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint('[Push] Token refreshed: $newToken');
      syncTokenWithBackend();
    });
  }

  static Future<void> syncTokenWithBackend() async {
    String? token;
    try {
      token = await _messaging.getToken().timeout(const Duration(seconds: 10));
      debugPrint('[Push] getToken() returned: $token');
    } catch (e, st) {
      debugPrint('[Push] getToken() FAILED: $e');
      debugPrint('$st');
      return;
    }

    if (token == null) {
      debugPrint('[Push] getToken() returned null -- nothing to register.');
      return;
    }

    try {
      await _authService.registerFcmToken(token).timeout(const Duration(seconds: 10));
      debugPrint('[Push] Token registered with backend successfully.');
    } catch (e, st) {
      debugPrint('[Push] registerFcmToken() FAILED: $e');
      debugPrint('$st');
    }
  }
}
