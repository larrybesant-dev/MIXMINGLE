
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../shared/models/camera_state.dart';
import '../services/camera_service.dart';

final cameraServiceProvider = Provider((ref) => CameraService());

final activeCamerasProvider = StreamProvider.family<List<CameraState>, String>(
  (ref, roomId) {
    final service = ref.watch(cameraServiceProvider);
    return service.streamActiveCameras(roomId);
  },
);

final activeCameraCountProvider = FutureProvider.family<int, String>(
  (ref, roomId) async {
    final service = ref.watch(cameraServiceProvider);
    return service.getActiveCameraCount(roomId);
  },
);

// Note: State management for spotlight can be done in widgets or via service callbacks
// For now, these are placeholders - actual state will be managed locally in widgets


