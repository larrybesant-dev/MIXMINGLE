import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';

class UserService {
  final _users = FirebaseFirestore.instance.collection('users');

  Stream<UserModel?> watchUser(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromDoc(doc);
    });
  }

  Future<UserModel?> fetchUser(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromDoc(doc);
  }

  Future<void> createUser(UserModel user) async {
    await _users.doc(user.id).set(user.toMap(), SetOptions(merge: true));
  }

  Future<void> updateUser(UserModel user) async {
    await _users.doc(user.id).update(user.toMap());
  }

  Future<void> setOnlineStatus(String uid, bool isOnline) async {
    await _users.doc(uid).update({
      'isOnline': isOnline,
      'lastActive': FieldValue.serverTimestamp(),
    });
  }
}
