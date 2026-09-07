import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  StreamSubscription<String>? _tokenRefreshSub;
  
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    if (kIsWeb) {
      _isInitialized = true;
      return;
    }

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
        'presenza_high_importance_channel', // id
        'Presenza Notifications', // name
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

  /// Persist the device FCM token to the user document in Firestore.
  Future<void> syncUserToken(String uid) async {
    if (kIsWeb) return;
    try {
      final token = await getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint('FCM Token synced for user $uid');
      }

      // Listen for token rotations
      await _tokenRefreshSub?.cancel();
      _tokenRefreshSub = _fcm.onTokenRefresh.listen((newToken) async {
        try {
          await FirebaseFirestore.instance.collection('users').doc(uid).set({
            'fcmToken': newToken,
            'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          debugPrint('FCM Token refreshed and synced for user $uid');
        } catch (e) {
          debugPrint('Error syncing refreshed FCM token: $e');
        }
      });

      // Subscribe to general announcements
      await _fcm.subscribeToTopic('all_announcements');
    } catch (e) {
      debugPrint('Error syncing user FCM token: $e');
    }
  }

  /// Subscribe user to a specific batch topic
  Future<void> subscribeToBatchTopic(String batchId) async {
    if (kIsWeb) return;
    try {
      final sanitized = batchId.replaceAll(RegExp(r'[^a-zA-Z0-9-_.~%]'), '_');
      await _fcm.subscribeToTopic('batch_$sanitized');
    } catch (e) {
      debugPrint('Error subscribing to batch topic: $e');
    }
  }

  /// Show an in-app local notification banner/heads-up
  Future<void> showInAppNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    if (kIsWeb) return;
    try {
      await _localNotifications.show(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'presenza_high_importance_channel',
            'Presenza Notifications',
            channelDescription: 'This channel is used for important notifications.',
            icon: '@mipmap/ic_launcher',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: data != null ? jsonEncode(data) : null,
      );
    } catch (e) {
      debugPrint('Error displaying in-app notification: $e');
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
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'presenza_high_importance_channel',
            'Presenza Notifications',
            channelDescription: 'This channel is used for important notifications.',
            icon: '@mipmap/ic_launcher',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
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
