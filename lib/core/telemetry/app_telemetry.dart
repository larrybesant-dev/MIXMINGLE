import 'package:flutter/foundation.dart';

import '../logger.dart';

class TelemetryEvent {
  const TelemetryEvent({
    required this.timestamp,
    required this.level,
    required this.domain,
    required this.action,
    required this.message,
    this.userId,
    this.roomId,
    this.result,
    this.metadata = const <String, Object?>{},
  });

  final DateTime timestamp;
  final String level;
  final String domain;
  final String action;
  final String message;
  final String? userId;
  final String? roomId;
  final String? result;
  final Map<String, Object?> metadata;
}

class AppTelemetryState {
  const AppTelemetryState({
    this.authUserId,
    this.authLoading = false,
    this.authError,
    this.roomId,
    this.joinedUserId,
    this.roomPhase,
    this.roomError,
    this.participantCount = 0,
    this.micMuted = true,
    this.videoEnabled = false,
    this.presenceStatus,
    this.roomPresenceStatus,
    this.globalPresenceOnline,
    this.inRoom,
    this.cameraStatus,
    this.callError,
    this.currentRtcUid,
    this.cameraMismatch = false,
    this.presenceMismatch = false,
    this.staleParticipantIds = const <String>{},
    this.activeListenersByKey = const <String, int>{},
    this.firestoreReadCount = 0,
    this.firestoreWriteCount = 0,
    this.firestoreSnapshotCount = 0,
    this.recentEvents = const <TelemetryEvent>[],
  });

  final String? authUserId;
  final bool authLoading;
  final String? authError;
  final String? roomId;
  final String? joinedUserId;
  final String? roomPhase;
  final String? roomError;
  final int participantCount;
  final bool micMuted;
  final bool videoEnabled;
  final String? presenceStatus;
  final String? roomPresenceStatus;
  final bool? globalPresenceOnline;
  final String? inRoom;
  final String? cameraStatus;
  final String? callError;
  final int? currentRtcUid;
  final bool cameraMismatch;
  final bool presenceMismatch;
  final Set<String> staleParticipantIds;
  final Map<String, int> activeListenersByKey;
  final int firestoreReadCount;
  final int firestoreWriteCount;
  final int firestoreSnapshotCount;
  final List<TelemetryEvent> recentEvents;

  int get activeListenerCount => activeListenersByKey.values.fold<int>(
        0,
        (sum, count) => sum + count,
      );

  List<String> get duplicateListenerKeys => activeListenersByKey.entries
      .where((entry) => entry.value > 1)
      .map((entry) => entry.key)
      .toList(growable: false);

  AppTelemetryState copyWith({
    Object? authUserId = _unset,
    bool? authLoading,
    Object? authError = _unset,
    Object? roomId = _unset,
    Object? joinedUserId = _unset,
    Object? roomPhase = _unset,
    Object? roomError = _unset,
    int? participantCount,
    bool? micMuted,
    bool? videoEnabled,
    Object? presenceStatus = _unset,
    Object? roomPresenceStatus = _unset,
    Object? globalPresenceOnline = _unset,
    Object? inRoom = _unset,
    Object? cameraStatus = _unset,
    Object? callError = _unset,
    Object? currentRtcUid = _unset,
    bool? cameraMismatch,
    bool? presenceMismatch,
    Set<String>? staleParticipantIds,
    Map<String, int>? activeListenersByKey,
    int? firestoreReadCount,
    int? firestoreWriteCount,
    int? firestoreSnapshotCount,
    List<TelemetryEvent>? recentEvents,
  }) {
    return AppTelemetryState(
      authUserId:
          identical(authUserId, _unset) ? this.authUserId : authUserId as String?,
      authLoading: authLoading ?? this.authLoading,
      authError: identical(authError, _unset) ? this.authError : authError as String?,
      roomId: identical(roomId, _unset) ? this.roomId : roomId as String?,
      joinedUserId: identical(joinedUserId, _unset)
          ? this.joinedUserId
          : joinedUserId as String?,
      roomPhase: identical(roomPhase, _unset) ? this.roomPhase : roomPhase as String?,
      roomError: identical(roomError, _unset) ? this.roomError : roomError as String?,
      participantCount: participantCount ?? this.participantCount,
      micMuted: micMuted ?? this.micMuted,
      videoEnabled: videoEnabled ?? this.videoEnabled,
      presenceStatus: identical(presenceStatus, _unset)
          ? this.presenceStatus
          : presenceStatus as String?,
      roomPresenceStatus: identical(roomPresenceStatus, _unset)
          ? this.roomPresenceStatus
          : roomPresenceStatus as String?,
      globalPresenceOnline: identical(globalPresenceOnline, _unset)
          ? this.globalPresenceOnline
          : globalPresenceOnline as bool?,
      inRoom: identical(inRoom, _unset) ? this.inRoom : inRoom as String?,
      cameraStatus: identical(cameraStatus, _unset)
          ? this.cameraStatus
          : cameraStatus as String?,
      callError: identical(callError, _unset) ? this.callError : callError as String?,
      currentRtcUid: identical(currentRtcUid, _unset)
          ? this.currentRtcUid
          : currentRtcUid as int?,
      cameraMismatch: cameraMismatch ?? this.cameraMismatch,
      presenceMismatch: presenceMismatch ?? this.presenceMismatch,
      staleParticipantIds: staleParticipantIds ?? this.staleParticipantIds,
      activeListenersByKey: activeListenersByKey ?? this.activeListenersByKey,
      firestoreReadCount: firestoreReadCount ?? this.firestoreReadCount,
      firestoreWriteCount: firestoreWriteCount ?? this.firestoreWriteCount,
      firestoreSnapshotCount: firestoreSnapshotCount ?? this.firestoreSnapshotCount,
      recentEvents: recentEvents ?? this.recentEvents,
    );
  }
}

const Object _unset = Object();

class AppTelemetry {
  AppTelemetry._();

  static const int _maxEvents = 40;

  static final ValueNotifier<AppTelemetryState> notifier =
      ValueNotifier<AppTelemetryState>(const AppTelemetryState());

  static AppTelemetryState get state => notifier.value;

  static void reset() {
    notifier.value = const AppTelemetryState();
  }

  static void updateAuthState({
    String? userId,
    bool? isLoading,
    String? error,
  }) {
    final current = notifier.value;
    final next = current.copyWith(
      authUserId: userId,
      authLoading: isLoading,
      authError: error,
    );
    _emitIfChanged(current, next);
  }

  static void updateRoomState({
    String? roomId,
    String? joinedUserId,
    String? roomPhase,
    String? roomError,
    int? participantCount,
    bool? micMuted,
    bool? videoEnabled,
    String? presenceStatus,
    String? roomPresenceStatus,
    bool? globalPresenceOnline,
    String? inRoom,
    String? cameraStatus,
    String? callError,
    int? currentRtcUid,
    bool? cameraMismatch,
    bool? presenceMismatch,
    Iterable<String>? staleParticipantIds,
  }) {
    final current = notifier.value;
    final nextStaleIds = staleParticipantIds == null
        ? current.staleParticipantIds
        : Set<String>.from(staleParticipantIds);
    final next = current.copyWith(
      roomId: roomId,
      joinedUserId: joinedUserId,
      roomPhase: roomPhase,
      roomError: roomError,
      participantCount: participantCount,
      micMuted: micMuted,
      videoEnabled: videoEnabled,
      presenceStatus: presenceStatus,
      roomPresenceStatus: roomPresenceStatus,
      globalPresenceOnline: globalPresenceOnline,
      inRoom: inRoom,
      cameraStatus: cameraStatus,
      callError: callError,
      currentRtcUid: currentRtcUid,
      cameraMismatch: cameraMismatch,
      presenceMismatch: presenceMismatch,
      staleParticipantIds: nextStaleIds,
    );
    _emitIfChanged(current, next);

    if (!current.cameraMismatch && next.cameraMismatch) {
      logAction(
        level: 'warning',
        domain: 'room',
        action: 'camera_mismatch',
        message: 'UI reports camera on while Firestore participant state is off.',
        userId: next.joinedUserId,
        roomId: next.roomId,
        result: 'mismatch',
      );
    }

    if (!current.presenceMismatch && next.presenceMismatch) {
      logAction(
        level: 'error',
        domain: 'presence',
        action: 'presence_mismatch',
        message: 'Joined room state conflicts with presence document.',
        userId: next.joinedUserId,
        roomId: next.roomId,
        result: 'critical',
        metadata: <String, Object?>{
          'presenceStatus': next.presenceStatus,
          'inRoom': next.inRoom,
        },
      );
    }

    if (!setEquals(current.staleParticipantIds, next.staleParticipantIds) &&
        next.staleParticipantIds.isNotEmpty) {
      logAction(
        level: 'warning',
        domain: 'presence',
        action: 'stale_participants_detected',
        message: 'One or more room participants missed heartbeat threshold.',
        userId: next.joinedUserId,
        roomId: next.roomId,
        result: 'stale',
        metadata: <String, Object?>{
          'staleParticipantIds': next.staleParticipantIds.toList(growable: false),
        },
      );
    }
  }

  static void clearRoomState() {
    final current = notifier.value;
    final next = current.copyWith(
      roomId: null,
      joinedUserId: null,
      roomPhase: null,
      roomError: null,
      participantCount: 0,
      micMuted: true,
      videoEnabled: false,
      presenceStatus: null,
      roomPresenceStatus: null,
      globalPresenceOnline: null,
      inRoom: null,
      cameraStatus: null,
      callError: null,
      currentRtcUid: null,
      cameraMismatch: false,
      presenceMismatch: false,
      staleParticipantIds: const <String>{},
    );
    _emitIfChanged(current, next);
  }

  static void listenerStarted({
    required String key,
    required String query,
    String? roomId,
    String? userId,
  }) {
    final current = notifier.value;
    final listeners = Map<String, int>.from(current.activeListenersByKey);
    listeners[key] = (listeners[key] ?? 0) + 1;
    final next = current.copyWith(activeListenersByKey: listeners);
    _emitIfChanged(current, next);

    logAction(
      domain: 'firestore',
      action: 'listener_start',
      message: 'Firestore listener attached.',
      roomId: roomId,
      userId: userId,
      result: listeners[key].toString(),
      metadata: <String, Object?>{'key': key, 'query': query},
    );
  }

  static void listenerStopped({
    required String key,
    required String query,
    String? roomId,
    String? userId,
  }) {
    final current = notifier.value;
    final listeners = Map<String, int>.from(current.activeListenersByKey);
    final nextCount = (listeners[key] ?? 0) - 1;
    if (nextCount > 0) {
      listeners[key] = nextCount;
    } else {
      listeners.remove(key);
    }
    final next = current.copyWith(activeListenersByKey: listeners);
    _emitIfChanged(current, next);

    logAction(
      domain: 'firestore',
      action: 'listener_stop',
      message: 'Firestore listener detached.',
      roomId: roomId,
      userId: userId,
      result: nextCount > 0 ? nextCount.toString() : '0',
      metadata: <String, Object?>{'key': key, 'query': query},
    );
  }

  static void recordFirestoreRead({
    required String path,
    required String operation,
    String? roomId,
    String? userId,
  }) {
    final current = notifier.value;
    final next = current.copyWith(
      firestoreReadCount: current.firestoreReadCount + 1,
    );
    _emitIfChanged(current, next);
    logAction(
      domain: 'firestore',
      action: operation,
      message: 'Firestore read issued.',
      roomId: roomId,
      userId: userId,
      result: 'read',
      metadata: <String, Object?>{'path': path},
    );
  }

  static void recordFirestoreWrite({
    required String path,
    required String operation,
    String? roomId,
    String? userId,
    Map<String, Object?> metadata = const <String, Object?>{},
  }) {
    final current = notifier.value;
    final next = current.copyWith(
      firestoreWriteCount: current.firestoreWriteCount + 1,
    );
    _emitIfChanged(current, next);
    logAction(
      domain: 'firestore',
      action: operation,
      message: 'Firestore write issued.',
      roomId: roomId,
      userId: userId,
      result: 'write',
      metadata: <String, Object?>{'path': path, ...metadata},
    );
  }

  static void recordFirestoreSnapshot({
    required String key,
    required String query,
    required int count,
    String? roomId,
    String? userId,
  }) {
    final current = notifier.value;
    final next = current.copyWith(
      firestoreSnapshotCount: current.firestoreSnapshotCount + 1,
    );
    _emitIfChanged(current, next);
    logAction(
      domain: 'firestore',
      action: 'snapshot',
      message: 'Firestore snapshot triggered.',
      roomId: roomId,
      userId: userId,
      result: count.toString(),
      metadata: <String, Object?>{'key': key, 'query': query},
    );
  }

  static void recordFirestoreError({
    required String key,
    required String query,
    required Object error,
    StackTrace? stackTrace,
    String? roomId,
    String? userId,
  }) {
    logAction(
      level: 'error',
      domain: 'firestore',
      action: 'listener_error',
      message: 'Firestore listener failed.',
      roomId: roomId,
      userId: userId,
      result: 'error',
      metadata: <String, Object?>{'key': key, 'query': query},
      error: error,
      stackTrace: stackTrace,
    );
  }

  static void logAction({
    String level = 'info',
    required String domain,
    required String action,
    required String message,
    String? userId,
    String? roomId,
    String? result,
    Map<String, Object?> metadata = const <String, Object?>{},
    Object? error,
    StackTrace? stackTrace,
  }) {
    final event = TelemetryEvent(
      timestamp: DateTime.now(),
      level: level,
      domain: domain,
      action: action,
      message: message,
      userId: userId,
      roomId: roomId,
      result: result,
      metadata: Map<String, Object?>.from(metadata),
    );

    final current = notifier.value;
    final events = <TelemetryEvent>[event, ...current.recentEvents];
    if (events.length > _maxEvents) {
      events.removeRange(_maxEvents, events.length);
    }
    notifier.value = current.copyWith(recentEvents: events);

    final buffer = StringBuffer()
      ..write('[')
      ..write(event.timestamp.toIso8601String())
      ..write('] ')
      ..write('[')
      ..write(event.domain.toUpperCase())
      ..write(' ')
      ..write(event.action.toUpperCase())
      ..write('] ')
      ..write(message);
    if (userId != null && userId.isNotEmpty) {
      buffer.write(' userId=');
      buffer.write(userId);
    }
    if (roomId != null && roomId.isNotEmpty) {
      buffer.write(' roomId=');
      buffer.write(roomId);
    }
    if (result != null && result.isNotEmpty) {
      buffer.write(' result=');
      buffer.write(result);
    }
    if (metadata.isNotEmpty) {
      metadata.forEach((key, value) {
        buffer.write(' ');
        buffer.write(key);
        buffer.write('=');
        buffer.write(value);
      });
    }
    final formatted = buffer.toString();

    switch (level) {
      case 'error':
        Logger.error(
          formatted,
          error: error,
          stackTrace: stackTrace,
        );
        break;
      case 'warning':
        Logger.warning(
          formatted,
          error: error,
          stackTrace: stackTrace,
        );
        break;
      default:
        Logger.info(
          formatted,
          error: error,
          stackTrace: stackTrace,
        );
        break;
    }
  }

  static void _emitIfChanged(
    AppTelemetryState current,
    AppTelemetryState next,
  ) {
    if (_sameState(current, next)) {
      return;
    }
    notifier.value = next;
  }

  static bool _sameState(AppTelemetryState left, AppTelemetryState right) {
    return left.authUserId == right.authUserId &&
        left.authLoading == right.authLoading &&
        left.authError == right.authError &&
        left.roomId == right.roomId &&
        left.joinedUserId == right.joinedUserId &&
        left.roomPhase == right.roomPhase &&
        left.roomError == right.roomError &&
        left.participantCount == right.participantCount &&
        left.micMuted == right.micMuted &&
        left.videoEnabled == right.videoEnabled &&
        left.presenceStatus == right.presenceStatus &&
        left.roomPresenceStatus == right.roomPresenceStatus &&
        left.globalPresenceOnline == right.globalPresenceOnline &&
        left.inRoom == right.inRoom &&
        left.cameraStatus == right.cameraStatus &&
        left.callError == right.callError &&
        left.currentRtcUid == right.currentRtcUid &&
        left.cameraMismatch == right.cameraMismatch &&
        left.presenceMismatch == right.presenceMismatch &&
        setEquals(left.staleParticipantIds, right.staleParticipantIds) &&
        mapEquals(left.activeListenersByKey, right.activeListenersByKey) &&
        left.firestoreReadCount == right.firestoreReadCount &&
        left.firestoreWriteCount == right.firestoreWriteCount &&
        left.firestoreSnapshotCount == right.firestoreSnapshotCount &&
        listEquals(left.recentEvents, right.recentEvents);
  }
}