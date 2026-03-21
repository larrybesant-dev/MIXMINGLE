import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/presence_model.dart';

abstract class PresenceRepository {
  Future<List<PresenceModel>> getPresence(String roomId);
  Future<void> setPresence(String roomId, PresenceModel presence);
}

class PresenceRepositoryImpl implements PresenceRepository {
  final FirebaseFirestore firestore;
  PresenceRepositoryImpl(this.firestore);

  @override
  Future<List<PresenceModel>> getPresence(String roomId) async {
    final snapshot = await firestore.collection('rooms').doc(roomId).collection('presence').get();
    return snapshot.docs.map((doc) => PresenceModel.fromJson(doc.data())).toList();
  }

  @override
  Future<void> setPresence(String roomId, PresenceModel presence) async {
    await firestore.collection('rooms').doc(roomId).collection('presence').doc(presence.userId).set(presence.toJson());
  }
}
