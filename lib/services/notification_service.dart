import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    await _messaging.requestPermission();
  }

  void sendRoomInvite(String userId) {}
  void sendEventReminder(String userId) {}
  void sendNewFollower(String userId) {}
  void sendMessageNotification(String userId) {}
}
