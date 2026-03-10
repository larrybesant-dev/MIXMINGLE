
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Video tile state for Agora
///
/// Tracks which participants have published video and should show video tiles
/// Uses Set internally for O(1) deduplication and atomic operations
class VideoTileState {
  final int? localUid; // Local user's UID
  final Set<int> remoteVideoUids; // Remote users publishing video (using Set for dedup)

  const VideoTileState({
    this.localUid,
    this.remoteVideoUids = const {},
  });

  VideoTileState copyWith({
    int? localUid,
    Set<int>? remoteVideoUids,
  }) {
    return VideoTileState(
      localUid: localUid ?? this.localUid,
      remoteVideoUids: remoteVideoUids ?? this.remoteVideoUids,
    );
  }

  /// Check if a specific user has published video
  bool hasVideo(int uid) {
    return uid == localUid || remoteVideoUids.contains(uid);
  }

  /// Get all UIDs with video (local + remote)
  /// Returns immutable list for safety
  List<int> get allVideoUids {
    final uids = <int>[];
    if (localUid != null) uids.add(localUid!);
    uids.addAll(remoteVideoUids);
    return uids;
  }

  /// Get count of video tiles
  int get videoCount => allVideoUids.length;

  @override
  String toString() => 'VideoTileState(local=$localUid, remote=${remoteVideoUids.length})';
}

/// Notifier for managing video tile state
/// Uses atomic operations to prevent duplicates and race conditions
class VideoTileNotifier extends Notifier<VideoTileState> {
  @override
  VideoTileState build() => const VideoTileState();

  /// Set local user UID (idempotent)
  void setLocalUid(int uid) {
    if (state.localUid != uid) {
      state = state.copyWith(localUid: uid);
    }
  }

  /// Add remote video UID (idempotent - handles duplicate calls)
  void addRemoteVideo(int uid) {
    if (!state.remoteVideoUids.contains(uid)) {
      final newUids = Set<int>.from(state.remoteVideoUids)..add(uid);
      state = state.copyWith(remoteVideoUids: newUids);
    }
  }

  /// Remove remote video UID (idempotent - handles missing UIDs gracefully)
  void removeRemoteVideo(int uid) {
    if (state.remoteVideoUids.contains(uid)) {
      final newUids = Set<int>.from(state.remoteVideoUids)..remove(uid);
      state = state.copyWith(remoteVideoUids: newUids);
    }
  }

  /// Clear all video tiles (when leaving room)
  void clear() {
    state = const VideoTileState();
  }

  /// Clear local video only (when turning off camera)
  void clearLocalVideo() {
    if (state.localUid != null) {
      state = state.copyWith(localUid: null);
    }
  }

  /// Batch update remote video UIDs (atomic operation for consistency)
  /// Useful when syncing with external state
  void syncRemoteVideoUids(Set<int> uids) {
    if (state.remoteVideoUids != uids) {
      state = state.copyWith(remoteVideoUids: Set<int>.from(uids));
    }
  }
}

/// Provider for video tile state
final videoTileProvider = NotifierProvider<VideoTileNotifier, VideoTileState>(() {
  return VideoTileNotifier();
});

/// Provider to check if a specific user has video
final hasVideoProvider = Provider.family<bool, int>((ref, uid) {
  final videoState = ref.watch(videoTileProvider);
  return videoState.hasVideo(uid);
});



