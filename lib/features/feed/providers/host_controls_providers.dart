import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../repository/host_controls_repository.dart';
import '../../../models/room_model.dart';

final hostControlsRepositoryProvider = Provider<HostControlsRepository>((ref) {
  return HostControlsRepository(FirebaseFirestore.instance);
});

final roomStreamProvider = StreamProvider.family<RoomModel, String>((ref, roomId) {
  return FirebaseFirestore.instance
      .collection('rooms')
      .doc(roomId)
      .snapshots()
      .map((doc) => RoomModel.fromJson(doc.data()!, doc.id));
});
