import '../models/friend_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FriendsService {
  final _usersRef = FirebaseFirestore.instance.collection('users');

  Future<void> addFriend(String userId, Friend friend) async {
    await _usersRef.doc(userId).collection('friends').doc(friend.friendId).set(friend.toMap());
  }

  Future<void> removeFriend(String userId, String friendId) async {
    await _usersRef.doc(userId).collection('friends').doc(friendId).delete();
  }

  Stream<List<Friend>> streamFriends(String userId) {
    return _usersRef.doc(userId).collection('friends').snapshots().map((snapshot) =>
      snapshot.docs.map((doc) => Friend.fromMap(doc.data())).toList());
  }
}
