// ...existing code...
import 'package:cloud_firestore/cloud_firestore.dart';

class PresenceService {
	final FirebaseFirestore firestore;
	PresenceService(this.firestore);

	Future<void> setPresence(String roomId, String userId, bool isOnline) async {
		await firestore.collection('rooms').doc(roomId).collection('presence').doc(userId).set({
			'isOnline': isOnline,
			'timestamp': DateTime.now(),
		});
	}

	Stream<List<Map<String, dynamic>>> getPresence(String roomId) {
		return firestore.collection('rooms').doc(roomId).collection('presence').snapshots().map((snapshot) =>
			snapshot.docs.map((doc) => doc.data()).toList());
	}
}
