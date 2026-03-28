import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/room_policy_model.dart';
import 'room_firestore_provider.dart';

final roomPolicyProvider = StreamProvider.autoDispose.family<RoomPolicyModel, String>((ref, roomId) {
  final firestore = ref.watch(roomFirestoreProvider);
  final roomRef = firestore.collection('rooms').doc(roomId);
  final policyRef = roomRef.collection('policies').doc('settings');

  return policyRef.snapshots().map((snapshot) {
    final data = snapshot.data() ?? <String, dynamic>{};
    if (data.isEmpty) {
      return RoomPolicyModel(roomId: roomId);
    }

    return RoomPolicyModel.fromJson({
      ...data,
      'roomId': roomId,
    });
  });
});
