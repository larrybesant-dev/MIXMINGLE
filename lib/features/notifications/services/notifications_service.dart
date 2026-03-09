import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getNotifications(String userId) async {
    final snapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}
