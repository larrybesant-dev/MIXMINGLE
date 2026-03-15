import '../models/room_model.dart';
import '../models/room_member_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoomService {
  final _roomsRef = FirebaseFirestore.instance.collection('rooms');

  Future<void> createRoom(Room room) async {
    await _roomsRef.doc(room.id).set(room.toMap());
  }

  Future<void> joinRoom(String roomId, RoomMember member) async {
    await _roomsRef.doc(roomId).collection('members').doc(member.userId).set(member.toMap());
  }

  Future<void> leaveRoom(String roomId, String userId) async {
    await _roomsRef.doc(roomId).collection('members').doc(userId).delete();
  }

  Stream<List<Room>> streamRooms() {
    return _roomsRef.snapshots().map((snapshot) =>
      snapshot.docs.map((doc) => Room.fromFirestore(doc)).toList());
  }

  Stream<List<RoomMember>> streamRoomMembers(String roomId) {
    return _roomsRef.doc(roomId).collection('members').snapshots().map((snapshot) =>
      snapshot.docs.map((doc) => RoomMember.fromFirestore(doc)).toList());
  }

  Future<void> updateActiveCount(String roomId, int count) async {
    await _roomsRef.doc(roomId).update({'activeUserCount': count});
  }
}
