import 'package:cloud_firestore/cloud_firestore.dart';
// Removed unused import
// Handles profile background color customization
class ProfileBackgroundManager {
  final FirebaseFirestore firestore;
  ProfileBackgroundManager(this.firestore);

  Future<void> setBackgroundColor(String userId, String colorHex) async {
    await firestore.collection('users').doc(userId).update({
      'backgroundColor': colorHex,
    });
  }

  Future<String?> getBackgroundColor(String userId) async {
    final doc = await firestore.collection('users').doc(userId).get();
    if (!doc.exists || doc.data()?['backgroundColor'] == null) return null;
    return doc.data()!['backgroundColor'];
  }
}
