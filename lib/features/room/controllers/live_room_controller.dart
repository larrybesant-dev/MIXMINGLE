import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/room_session_service.dart';

enum LiveRoomPhase {
  idle,
  joining,
  joined,
  leaving,
  error,
}

class LiveRoomState {
  const LiveRoomState({
    this.phase = LiveRoomPhase.idle,
    this.userId,
    this.errorMessage,
    this.joinedAt,
    this.excludedUserIds = const <String>{},
  });

  final LiveRoomPhase phase;
  final String? userId;
  final String? errorMessage;
  final DateTime? joinedAt;
  final Set<String> excludedUserIds;

  bool get isJoined => phase == LiveRoomPhase.joined && userId != null;

  LiveRoomState copyWith({
    LiveRoomPhase? phase,
    Object? userId = _unset,
    Object? errorMessage = _unset,
    Object? joinedAt = _unset,
    Set<String>? excludedUserIds,
  }) {
    return LiveRoomState(
      phase: phase ?? this.phase,
      userId: identical(userId, _unset) ? this.userId : userId as String?,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
      joinedAt: identical(joinedAt, _unset)
          ? this.joinedAt
          : joinedAt as DateTime?,
      excludedUserIds: excludedUserIds ?? this.excludedUserIds,
    );
  }
}

const Object _unset = Object();

final liveRoomControllerProvider = NotifierProvider.family
    .autoDispose<LiveRoomController, LiveRoomState, String>(
  LiveRoomController.new,
);

class LiveRoomController extends AutoDisposeFamilyNotifier<LiveRoomState, String> {
  RoomSessionService get _service => ref.read(roomSessionServiceProvider);

  @override
  LiveRoomState build(String roomId) {
    return const LiveRoomState();
  }

  Future<RoomJoinResult> joinRoom(String userId) async {
    if (state.phase == LiveRoomPhase.joining ||
        (state.isJoined && state.userId == userId)) {
      return RoomJoinResult.success(
        joinedAt: state.joinedAt ?? DateTime.now(),
        excludedUserIds: state.excludedUserIds,
      );
    }

    state = state.copyWith(
      phase: LiveRoomPhase.joining,
      userId: userId,
      errorMessage: null,
    );

    final result = await _service.joinRoom(roomId: arg, userId: userId);
    if (!result.isSuccess) {
      state = state.copyWith(
        phase: LiveRoomPhase.error,
        userId: null,
        errorMessage: result.errorMessage,
        joinedAt: null,
        excludedUserIds: result.excludedUserIds,
      );
      return result;
    }

    state = state.copyWith(
      phase: LiveRoomPhase.joined,
      userId: userId,
      errorMessage: null,
      joinedAt: result.joinedAt,
      excludedUserIds: result.excludedUserIds,
    );
    return result;
  }

  Future<void> leaveRoom() async {
    final userId = state.userId;
    if (userId == null) {
      state = const LiveRoomState();
      return;
    }

    state = state.copyWith(phase: LiveRoomPhase.leaving, errorMessage: null);
    await _service.leaveRoom(roomId: arg, userId: userId);
    state = const LiveRoomState();
  }

  Future<void> pausePresence() async {
    final userId = state.userId;
    if (userId == null) {
      return;
    }
    await _service.setCustomStatus(
      roomId: arg,
      userId: userId,
      status: null,
    );
  }

  Future<void> resumePresence() async {
    final userId = state.userId;
    if (userId == null) {
      return;
    }
    state = state.copyWith(phase: LiveRoomPhase.joined, errorMessage: null);
  }

  Future<void> postSystemEvent(String content) {
    return _service.postSystemEvent(roomId: arg, content: content);
  }

  Future<void> setCustomStatus({
    required String userId,
    required String? status,
  }) {
    return _service.setCustomStatus(
      roomId: arg,
      userId: userId,
      status: status,
    );
  }

  Future<void> setTyping({
    required String userId,
    required bool isTyping,
  }) {
    return _service.setTyping(
      roomId: arg,
      userId: userId,
      isTyping: isTyping,
    );
  }

  Future<void> setSpotlightUser(String? userId) {
    return _service.setSpotlightUser(roomId: arg, userId: userId);
  }
}