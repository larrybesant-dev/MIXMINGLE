import 'package:cloud_firestore/cloud_firestore.dart';

class DiscoveryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getDiscoveries() async {
    final snapshot = await _firestore
        .collection('discovery')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}
