

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';



class FriendService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> sendFriendRequest(String fromUserId, String toUserId) async {
    await _firestore.collection('friend_requests').add({
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> acceptFriendRequest(String requestId) async {
    final requestRef = _firestore.collection('friend_requests').doc(requestId);
    final requestSnap = await requestRef.get();
    if (!requestSnap.exists) return;
    final data = requestSnap.data() as Map<String, dynamic>;
    final fromUserId = data['fromUserId'];
    final toUserId = data['toUserId'];

    // Add each user to the other's friends list
    await _firestore.collection('users').doc(fromUserId).update({
      'friends': FieldValue.arrayUnion([toUserId])
    });
    await _firestore.collection('users').doc(toUserId).update({
      'friends': FieldValue.arrayUnion([fromUserId])
    });

    // Update request status
    await requestRef.update({'status': 'accepted'});
  }

  Future<List<UserModel>> getFriends(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) return [];
    final data = userDoc.data() as Map<String, dynamic>;
    final List<dynamic> friendIds = data['friends'] ?? [];
    if (friendIds.isEmpty) return [];

    final friendsQuery = await _firestore
        .collection('users')
        .where(FieldPath.documentId, whereIn: friendIds)
        .get();
    return friendsQuery.docs
        .map((doc) => UserModel.fromJson(doc.data()))
        .toList();
  }
}
