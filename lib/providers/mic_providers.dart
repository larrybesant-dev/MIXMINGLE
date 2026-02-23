
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../shared/models/mic_state.dart';
import '../services/mic_service.dart';

final micServiceProvider = Provider((ref) => MicService());

final micQueueProvider = StreamProvider.family<List<MicState>, String>(
  (ref, roomId) {
    final service = ref.watch(micServiceProvider);
    return service.streamMicQueue(roomId);
  },
);

final activeMicCountProvider = FutureProvider.family<int, String>(
  (ref, roomId) async {
    final service = ref.watch(micServiceProvider);
    return service.getActiveMicCount(roomId);
  },
);

final pendingMicCountProvider = FutureProvider.family<int, String>(
  (ref, roomId) async {
    final service = ref.watch(micServiceProvider);
    return service.getPendingMicCount(roomId);
  },
);


