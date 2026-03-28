import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'room_firestore_provider.dart';

class Host {
  final String userId;

  Host(this.userId);
}

final hostProvider = StreamProvider.autoDispose.family<Host?, String>((ref, roomId) {
  final firestore = ref.watch(roomFirestoreProvider);
  return firestore.collection('rooms').doc(roomId).snapshots().map((doc) {
    final data = doc.data();
    final hostId = data?['hostId'] as String?;
    if (hostId == null || hostId.isEmpty) {
      return null;
    }
    return Host(hostId);
  });
});
