import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import '../../../models/room_participant_model.dart';


/// Watches the current user's participant document in a room (real-time).
final currentParticipantProvider = StreamProvider.family<RoomParticipantModel?, Map<String, String>>((ref, args) {
  final roomId = args['roomId']!;
  final userId = args['userId']!;
  final docStream = FirebaseFirestore.instance.collection('rooms').doc(roomId).collection('participants').doc(userId).snapshots();
  return docStream.map((doc) => doc.exists ? RoomParticipantModel.fromMap(doc.data()!) : null);
});

/// Watches all participants in a room (real-time).
final participantsStreamProvider = StreamProvider.family<List<RoomParticipantModel>, String>((ref, roomId) {
  return FirebaseFirestore.instance
      .collection('rooms')
      .doc(roomId)
      .collection('participants')
      .snapshots()
      .map((snap) => snap.docs
          .map((d) => RoomParticipantModel.fromMap(d.data()))
          .where((p) => p.isBanned != true)
          .toList());
});

/// Real-time count of non-banned participants in the room
final participantCountProvider = StreamProvider.family<int, String>((ref, roomId) {
  return ref.watch(participantsStreamProvider(roomId)).when(
    data: (list) => Stream.value(list.length),
    loading: () => const Stream.empty(),
    error: (e, _) => const Stream.empty(),
  );
});

/// Real-time list of cohosts in the room
final coHostsProvider = StreamProvider.family<List<RoomParticipantModel>, String>((ref, roomId) {
  return ref.watch(participantsStreamProvider(roomId)).when(
    data: (list) => Stream.value(list.where((p) => p.role == 'cohost').toList()),
    loading: () => const Stream.empty(),
    error: (e, _) => const Stream.empty(),
  );
});

/// Real-time host in the room (should be only one)
final hostProvider = StreamProvider.family<RoomParticipantModel?, String>((ref, roomId) {
  return ref.watch(participantsStreamProvider(roomId)).when(
    data: (list) => Stream.value(list.firstWhereOrNull((p) => p.role == 'host')),
    loading: () => const Stream.empty(),
    error: (e, _) => const Stream.empty(),
  );
});

/// Returns true if the current user is host in the room.
final isHostProvider = Provider.family<bool, RoomParticipantModel?>((ref, participant) {
  return participant?.role == 'host' ? true : false;
});

/// Returns true if the current user is cohost in the room.
final isCohostProvider = Provider.family<bool, RoomParticipantModel?>((ref, participant) {
  return participant?.role == 'cohost' ? true : false;
});

final roleProvider = Provider.family<String, RoomParticipantModel?>((ref, participant) {
  if (participant == null) return 'audience';
  return participant.role;
});
