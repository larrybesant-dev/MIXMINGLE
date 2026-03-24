
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/friend_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final selectedFriendProvider = StateProvider<FriendModel?>((ref) => null);

final friendStreamProvider = StreamProvider<List<FriendModel>>((ref) {
	final user = FirebaseAuth.instance.currentUser;
	if (user == null) {
		return Stream<List<FriendModel>>.value([]);
	}
	final stream = FirebaseFirestore.instance
			.collection('friends')
			.where('userId', isEqualTo: user.uid)
			.snapshots();
	return stream.map((snapshot) => snapshot.docs
			.map((doc) => FriendModel.fromJson(doc.data()))
			.toList());
});
