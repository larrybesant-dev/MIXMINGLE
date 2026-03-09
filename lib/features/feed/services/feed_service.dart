import 'package:cloud_firestore/cloud_firestore.dart';

class FeedService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getFeed(String userId) async {
    // Example: Fetch user activity feed from Firestore
    final snapshot = await _firestore
        .collection('user_activity')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}
