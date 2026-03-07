import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:mixmingle/core/routing/app_routes.dart';
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
      _handleNavigation(context, message.data);
    });

    // Handle notification tap when app is terminated
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
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
