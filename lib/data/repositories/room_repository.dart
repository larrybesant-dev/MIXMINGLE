import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/room_model.dart';

abstract class RoomRepository {
  Future<List<RoomModel>> getRooms();
  Future<RoomModel?> getRoom(String roomId);
  Future<void> createRoom(RoomModel room);
  Future<void> updateRoom(RoomModel room);
  Future<void> deleteRoom(String roomId);
}

class RoomRepositoryImpl implements RoomRepository {
  final FirebaseFirestore firestore;
  RoomRepositoryImpl(this.firestore);

  @override
  Future<List<RoomModel>> getRooms() async {
    final snapshot = await firestore.collection('rooms').get();
    return snapshot.docs.map((doc) => RoomModel.fromJson(doc.data())).toList();
  }

  @override
  Future<RoomModel?> getRoom(String roomId) async {
    final doc = await firestore.collection('rooms').doc(roomId).get();
    if (!doc.exists) return null;
    return RoomModel.fromJson(doc.data()!);
  }

  @override
  Future<void> createRoom(RoomModel room) async {
    await firestore.collection('rooms').add(room.toJson());
  }

  @override
  Future<void> updateRoom(RoomModel room) async {
    await firestore.collection('rooms').doc(room.id).update(room.toJson());
  }

  @override
  Future<void> deleteRoom(String roomId) async {
    await firestore.collection('rooms').doc(roomId).delete();
  }
}
