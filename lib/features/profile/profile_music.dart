import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileMusicManager {
  final FirebaseFirestore firestore;
  ProfileMusicManager(this.firestore);

  Future<void> uploadMusic(String userId, String url) async {
    await firestore.collection('users').doc(userId).update({
      'musicUrl': url,
    });
  }

  Future<String?> getMusicUrl(String userId) async {
    final doc = await firestore.collection('users').doc(userId).get();
    if (!doc.exists || doc.data()?['musicUrl'] == null) return null;
    return doc.data()!['musicUrl'];
  }
// Cleaned up class definition. No patch marker.
}
