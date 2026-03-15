<<<<<<< HEAD
=======
/// FCM Notifications Service - Friend Presence Alerts
///
/// Monitors friend presence changes and sends push notifications
/// Reference: DESIGN_BIBLE.md Section G (Backend Integration)
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
>>>>>>> origin/develop
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../features/chat_room_page.dart';

class FcmNotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> initialize(BuildContext context) async {
    // Request permissions
    await _fcm.requestPermission();

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // You can show an in-app banner here if you want
    });

    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (!context.mounted) return;
      _handleNavigation(context, message.data);
    });

    // Handle notification tap when app is terminated
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      if (!context.mounted) return;
      _handleNavigation(context, initialMessage.data);
    }
  }

  void _handleNavigation(BuildContext context, Map<String, dynamic> data) {
    final conversationId = data['conversationId'];
    final otherUserId = data['senderId'];

    if (conversationId == null || otherUserId == null) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatRoomPage(
          otherUserId: otherUserId,
          conversationId: conversationId,
        ),
      ),
    );
  }

  /// Build FCM payload for sending notifications
  Map<String, dynamic> buildMessagePayload({
    required String conversationId,
    required String senderId,
    required String senderName,
    required String text,
  }) {
    return {
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'messageText': text,
    };
  }
}
<<<<<<< HEAD
=======

/// FCM notification service provider
/// Note: Typically used in conjunction with PresenceNotificationService
/// which handles the actual presence monitoring and calls this service.
final fcmNotificationServiceProvider = Provider<FcmNotificationService>((ref) {
  final firestore = FirestoreService();
  return FcmNotificationService(firestore: firestore);
});

/// Watch notification permissions status
final notificationPermissionsProvider =
    FutureProvider<NotificationSettings>((ref) async {
  final messaging = FirebaseMessaging.instance;
  return messaging.getNotificationSettings();
});
>>>>>>> origin/develop
