import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Types of notifications
enum NotificationType {
  message,
  eventInvite,
  match,
  follow,
  like,
  eventReminder,
  systemAlert,
}

/// Service to handle push notifications with FCM
class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  String? _fcmToken;

  /// Initialize push notifications
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Request permission
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('Push notification permission granted');

        // Initialize local notifications for foreground display
        await _initializeLocalNotifications();

        // Get FCM token
        _fcmToken = await _messaging.getToken();
        if (_fcmToken != null) {
          debugPrint('FCM Token: $_fcmToken');
          await _saveFCMToken(_fcmToken!);
        }

        // Listen for token refresh
        _messaging.onTokenRefresh.listen(_saveFCMToken);

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // Handle background message taps
        FirebaseMessaging.onMessageOpenedApp
            .listen(_handleBackgroundMessageTap);

        // Handle notification when app is terminated
        final initialMessage = await _messaging.getInitialMessage();
        if (initialMessage != null) {
          _handleBackgroundMessageTap(initialMessage);
        }

        _initialized = true;
      } else {
        debugPrint('Push notification permission denied');
      }
    } catch (e) {
      debugPrint('Error initializing push notifications: $e');
    }
  }

  /// Initialize local notifications for foreground display
  Future<void> _initializeLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _handleLocalNotificationTap,
    );
  }

  /// Save FCM token to Firestore
  Future<void> _saveFCMToken(String token) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Use subcollection to avoid arrayUnion + serverTimestamp conflict
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('tokens')
          .doc(token) // Use token as doc ID to prevent duplicates
          .set({
        'token': token,
        'platform': defaultTargetPlatform.name,
        'addedAt': FieldValue.serverTimestamp(),
        'lastUsed': FieldValue.serverTimestamp(),
      });

      // Also update main user doc with latest token (for quick access)
      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': token,
        'lastFcmTokenUpdate': FieldValue.serverTimestamp(),
      });

      debugPrint('FCM token saved to Firestore');
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  /// Handle foreground messages (show local notification)
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Foreground message received: ${message.messageId}');

    final notification = message.notification;

    if (notification != null) {
      // Show local notification
      await _localNotifications.show(
        id: notification.hashCode,
        title: notification.title ?? '',
        body: notification.body ?? '',
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'default_channel',
            'Default Notifications',
            channelDescription: 'Default notification channel',
            importance: Importance.high,
            priority: Priority.high,
            icon: message.notification?.android?.smallIcon ??
                '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data['payload'],
      );

      // Save to in-app notification center
      await _saveNotificationToFirestore(message);
    }
  }

  /// Handle background message tap (navigate to appropriate screen)
  Future<void> _handleBackgroundMessageTap(RemoteMessage message) async {
    debugPrint('Background message tapped: ${message.messageId}');
    _handleNotificationTap(message.data);
  }

  /// Handle local notification tap
  Future<void> _handleLocalNotificationTap(
      NotificationResponse response) async {
    debugPrint('Local notification tapped: ${response.payload}');
    if (response.payload != null) {
      // Parse payload and navigate
      // Implementation depends on your navigation setup
    }
  }

  /// Handle notification tap routing
  void _handleNotificationTap(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final id = data['id'] as String?;

    debugPrint('Notification tap - Type: $type, ID: $id');

    // Navigation will be handled by the app's router
    // This method can be called from main navigation observers
    switch (type) {
      case 'message':
        // Navigate to chat with conversationId: id
        break;
      case 'event':
        // Navigate to event details with eventId: id
        break;
      case 'match':
        // Navigate to matches page
        break;
      case 'follow':
        // Navigate to user profile with userId: id
        break;
      default:
        // Navigate to notifications page
        break;
    }
  }

  /// Save notification to Firestore for in-app notification center
  Future<void> _saveNotificationToFirestore(RemoteMessage message) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('notifications').add({
        'userId': user.uid,
        'title': message.notification?.title,
        'body': message.notification?.body,
        'data': message.data,
        'type': message.data['type'],
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error saving notification to Firestore: $e');
    }
  }

  /// Send notification to a user (called from backend or Cloud Functions)
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    required NotificationType type,
    Map<String, String>? data,
  }) async {
    try {
      // Get user's FCM tokens
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final fcmTokens = userDoc.data()?['fcmTokens'] as List?;

      if (fcmTokens == null || fcmTokens.isEmpty) {
        debugPrint('No FCM tokens for user: $userId');
        return;
      }

      // Create notification document in Firestore
      // The Cloud Function will handle sending the actual push notification
      await _firestore.collection('notificationQueue').add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': type.name,
        'data': data ?? {},
        'tokens': fcmTokens.map((t) => t['token']).toList(),
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('Notification queued for user: $userId');
    } catch (e) {
      debugPrint('Error queuing notification: $e');
    }
  }

  /// Get current FCM token
  String? get fcmToken => _fcmToken;

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic: $e');
    }
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic: $e');
    }
  }

  /// Delete FCM token (on logout)
  Future<void> deleteFCMToken() async {
    final user = _auth.currentUser;
    if (user == null || _fcmToken == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'fcmTokens': FieldValue.arrayRemove([
          {
            'token': _fcmToken,
            'platform': defaultTargetPlatform.name,
          }
        ]),
      });
      await _messaging.deleteToken();
      _fcmToken = null;
      debugPrint('FCM token deleted');
    } catch (e) {
      debugPrint('Error deleting FCM token: $e');
    }
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background message received: ${message.messageId}');
  // Handle background message
  // Note: Cannot update UI or call setState from here
}
