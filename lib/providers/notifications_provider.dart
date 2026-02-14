/// Notifications Provider
/// FCM token management and notification handling
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

/// Notifications State
class NotificationsState {
  final String? fcmToken;
  final bool isInitialized;
  final bool notificationsEnabled;

  const NotificationsState({
    this.fcmToken,
    this.isInitialized = false,
    this.notificationsEnabled = false,
  });

  NotificationsState copyWith({
    String? fcmToken,
    bool? isInitialized,
    bool? notificationsEnabled,
  }) {
    return NotificationsState(
      fcmToken: fcmToken ?? this.fcmToken,
      isInitialized: isInitialized ?? this.isInitialized,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}

/// Notifications Controller
class NotificationsController extends Notifier<NotificationsState> {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  NotificationsState build() {
    return const NotificationsState();
  }

  /// Initialize FCM
  Future<void> initialize(String userId) async {
    try {
      // Request permission
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      final enabled = settings.authorizationStatus == AuthorizationStatus.authorized;

      debugPrint('📱 Notification permission: ${settings.authorizationStatus}');

      if (enabled) {
        // Get FCM token
        final token = await _messaging.getToken();
        debugPrint('📱 FCM Token: $token');

        if (token != null) {
          // Save token to Firestore
          await _firestore.collection('users').doc(userId).update({
            'fcmToken': token,
            'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
          });

          state = state.copyWith(
            fcmToken: token,
            isInitialized: true,
            notificationsEnabled: true,
          );

          // Listen for token refresh
          _messaging.onTokenRefresh.listen((newToken) {
            debugPrint('📱 FCM Token refreshed: $newToken');
            _firestore.collection('users').doc(userId).update({
              'fcmToken': newToken,
              'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
            });
            state = state.copyWith(fcmToken: newToken);
          });

          // Setup foreground message handler
          FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

          // Setup background message handler
          FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessage);

          // Check if app was opened from terminated state
          final initialMessage = await _messaging.getInitialMessage();
          if (initialMessage != null) {
            _handleBackgroundMessage(initialMessage);
          }

          debugPrint('✅ FCM initialized successfully');
        }
      } else {
        state = state.copyWith(
          isInitialized: true,
          notificationsEnabled: false,
        );
        debugPrint('❌ Notification permission denied');
      }
    } catch (e) {
      debugPrint('❌ Error initializing FCM: $e');
      state = state.copyWith(isInitialized: true);
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📨 Foreground message: ${message.notification?.title}');

    // TODO: Show in-app notification
    // You can use a package like flutter_local_notifications
    // or display a custom banner/snackbar
  }

  /// Handle background/terminated messages
  void _handleBackgroundMessage(RemoteMessage message) {
    debugPrint('📨 Background message: ${message.notification?.title}');

    // Handle notification tap - deep link to relevant screen
    final data = message.data;

    if (data.containsKey('type')) {
      switch (data['type']) {
        case 'message':
          // Navigate to chat
          final chatId = data['chatId'];
          if (chatId != null) {
            // TODO: Navigate to /chat/$chatId
            debugPrint('Navigate to chat: $chatId');
          }
          break;

        case 'match':
          // Navigate to matches
          debugPrint('Navigate to matches');
          break;

        case 'speed_dating_match':
          // Navigate to speed dating session
          final sessionId = data['sessionId'];
          if (sessionId != null) {
            debugPrint('Navigate to speed dating session: $sessionId');
          }
          break;

        case 'room_invite':
          // Navigate to room
          final roomId = data['roomId'];
          if (roomId != null) {
            debugPrint('Navigate to room: $roomId');
          }
          break;

        default:
          debugPrint('Unknown notification type: ${data['type']}');
      }
    }
  }

  /// Send notification (via Cloud Function)
  Future<void> sendNotification({
    required String targetUserId,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      // In production, call Cloud Function to send notification
      // This keeps FCM server key secure on the backend

      await _firestore.collection('notifications').add({
        'targetUserId': targetUserId,
        'title': title,
        'body': body,
        'data': data ?? {},
        'sent': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Notification queued for $targetUserId');
    } catch (e) {
      debugPrint('❌ Error sending notification: $e');
    }
  }

  /// Unsubscribe from notifications
  Future<void> unsubscribe(String userId) async {
    try {
      await _messaging.deleteToken();

      await _firestore.collection('users').doc(userId).update({
        'fcmToken': FieldValue.delete(),
      });

      state = state.copyWith(
        fcmToken: null,
        notificationsEnabled: false,
      );

      debugPrint('✅ Unsubscribed from notifications');
    } catch (e) {
      debugPrint('❌ Error unsubscribing: $e');
    }
  }
}

/// Provider
final notificationsProvider =
    NotifierProvider<NotificationsController, NotificationsState>(
  NotificationsController.new,
);

/// Notification badge count provider
final notificationBadgeProvider = StreamProvider.family<int, String>((ref, userId) {
  return FirebaseFirestore.instance
      .collection('chats')
      .where('participantIds', arrayContains: userId)
      .snapshots()
      .map((snapshot) {
    int totalUnread = 0;
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final unreadCount = (data['unreadCount'] as Map<String, dynamic>?)?[userId] ?? 0;
      totalUnread += unreadCount as int;
    }
    return totalUnread;
  });
});
