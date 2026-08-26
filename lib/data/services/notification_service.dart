import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:presenza/config/routes.dart';

// Background message handler must be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // 1. Request Permissions
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted notification permission');
      } else {
        debugPrint('User declined or has not accepted notification permission');
      }

      // 2. Initialize Local Notifications (for foreground notifications)
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher'); // Ensure icon exists
      const DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings();
      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      );

      await _localNotifications.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      // Create high importance channel for Android
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel', // id
        'High Importance Notifications', // name
        description: 'This channel is used for important notifications.', // description
        importance: Importance.max,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // 3. Set up foreground message handler
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // 4. Set up background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 5. Set up handler for when app is opened from background state via notification
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenApp);

      // 6. Handle initial message if app was terminated
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        // Delay navigation slightly to ensure router is ready
        Future.delayed(const Duration(milliseconds: 500), () {
          _handleMessageOpenApp(initialMessage);
        });
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('Failed to initialize notifications: $e');
    }
  }

  Future<String?> getToken() async {
    try {
      return await _fcm.getToken();
    } catch (e) {
      debugPrint('Failed to get FCM token: $e');
      return null;
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Received foreground message: ${message.notification?.title}');
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null && android != null) {
      _localNotifications.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'High Importance Notifications',
            channelDescription: 'This channel is used for important notifications.',
            icon: '@mipmap/ic_launcher',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  void _onNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(response.payload!);
        _navigateToRelevantScreen(data);
      } catch (e) {
        debugPrint('Failed to parse notification payload: $e');
      }
    }
  }

  void _handleMessageOpenApp(RemoteMessage message) {
    debugPrint('App opened from notification: ${message.data}');
    _navigateToRelevantScreen(message.data);
  }

  void _navigateToRelevantScreen(Map<String, dynamic> data) {
    final target = data['target'];
    final id = data['id'];
    
    if (target == null) return;
    
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;

    if (target == 'activity' && id != null) {
       // context.push('/activity/$id'); (assuming route exists, or handle generally)
       // We'll navigate to student shell or teacher shell based on roles, but for now we can just debugPrint
       debugPrint('Navigating to activity $id');
    } else if (target == 'attendance') {
       debugPrint('Navigating to attendance $id');
    }
  }
}
