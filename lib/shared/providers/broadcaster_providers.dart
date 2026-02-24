
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/video/broadcaster_service.dart';
import '../models/broadcaster_queue.dart';

// ============================================================================
// BROADCASTER SERVICE PROVIDER
// ============================================================================

/// Broadcaster service provider for managing queue and recording
final broadcasterServiceProvider = Provider((ref) {
  return BroadcasterService();
});

// ============================================================================
// BROADCASTER QUEUE PROVIDERS
// ============================================================================

/// Stream of broadcaster queue for current room
final broadcasterQueueProvider = StreamProvider.family<List<BroadcasterQueue>, String>((ref, roomId) {
  final service = ref.watch(broadcasterServiceProvider);
  return service.streamBroadcasterQueue(roomId);
});

/// Current user's queue status
final currentUserQueueStatusProvider = FutureProvider.family<BroadcasterQueue?, String>((ref, roomId) async {
  final service = ref.watch(broadcasterServiceProvider);
  return service.getCurrentUserQueueStatus(roomId);
});

/// Active broadcaster count
final activeBroadcasterCountProvider = FutureProvider.family<int, String>((ref, roomId) async {
  final service = ref.watch(broadcasterServiceProvider);
  return service.getActiveBroadcasterCount(roomId);
});

/// Pending broadcast count
final pendingBroadcastCountProvider = FutureProvider.family<int, String>((ref, roomId) async {
  final service = ref.watch(broadcasterServiceProvider);
  return service.getPendingBroadcastCount(roomId);
});


