import 'package:cloud_firestore/cloud_firestore.dart';

class PresenceService {
	final FirebaseFirestore _firestore = FirebaseFirestore.instance;

	Stream<bool> userPresenceStream(String userId) {
		return _firestore.collection('presence').doc(userId).snapshots().map((doc) {
			final data = doc.data();
			return (data != null && data['isOnline'] == true);
		});
	}

	Future<void> setUserOnline(String userId, bool isOnline) async {
		await _firestore.collection('presence').doc(userId).set({
			'isOnline': isOnline,
			'lastSeen': FieldValue.serverTimestamp(),
		}, SetOptions(merge: true));
	}
}
