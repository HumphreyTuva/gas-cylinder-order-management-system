import 'package:firebase_messaging/firebase_messaging.dart';
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
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Foreground messages: FCM does not auto-show a system tray notification
    // while the app is open, so we display one via flutter_local_notifications.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
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
    _messaging.onTokenRefresh.listen((_) => syncTokenWithBackend());
  }

  static Future<void> syncTokenWithBackend() async {
    final token = await _messaging.getToken();
    if (token != null) {
      try {
        await _authService.registerFcmToken(token);
      } catch (_) {
        // Non-fatal: user may not be logged in yet, or backend unreachable.
      }
    }
  }
}
