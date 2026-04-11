import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/moderation_service.dart';
import '../../../services/presence_service.dart';
import '../providers/room_firestore_provider.dart';

class RoomJoinResult {
  const RoomJoinResult._({
    required this.isSuccess,
    this.errorMessage,
    this.joinedAt,
    this.excludedUserIds = const <String>{},
  });

  const RoomJoinResult.success({
    required DateTime joinedAt,
    Set<String> excludedUserIds = const <String>{},
  }) : this._(
          isSuccess: true,
          joinedAt: joinedAt,
          excludedUserIds: excludedUserIds,
        );

  const RoomJoinResult.failure(
    String errorMessage, {
    Set<String> excludedUserIds = const <String>{},
  }) : this._(
          isSuccess: false,
          errorMessage: errorMessage,
          excludedUserIds: excludedUserIds,
        );

  final bool isSuccess;
  final String? errorMessage;
  final DateTime? joinedAt;
  final Set<String> excludedUserIds;
}

final roomSessionServiceProvider = Provider<RoomSessionService>((ref) {
  return RoomSessionService(
    firestore: ref.watch(roomFirestoreProvider),
    presenceService: PresenceService(firestore: ref.watch(roomFirestoreProvider)),
  );
});

class RoomSessionService {
  RoomSessionService({
    required FirebaseFirestore firestore,
    required PresenceService presenceService,
  })  : _firestore = firestore,
        _presenceService = presenceService;

  static const Duration presenceHeartbeatInterval = Duration(seconds: 30);
  static const Duration participantSyncInterval = Duration(seconds: 60);

  final FirebaseFirestore _firestore;
  final PresenceService _presenceService;

  String _asString(dynamic value, {String fallback = ''}) {
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }
    return fallback;
  }

  bool _asBool(dynamic value, {bool fallback = false}) {
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
        return true;
      }
      if (normalized == 'false' || normalized == '0' || normalized == 'no') {
        return false;
      }
    }
    return fallback;
  }

  Future<RoomJoinResult> joinRoom({
    required String roomId,
    required String userId,
  }) async {
    final normalizedRoomId = roomId.trim();
    final normalizedUserId = userId.trim();
    if (normalizedRoomId.isEmpty || normalizedUserId.isEmpty) {
      return const RoomJoinResult.failure('Could not join room. Please try again.');
    }

    final now = DateTime.now();
    final roomDoc = await _firestore.collection('rooms').doc(normalizedRoomId).get();
    if (!roomDoc.exists) {
      return const RoomJoinResult.failure('This room no longer exists.');
    }

    final ownerId = _asString(
      roomDoc.data()?['ownerId'],
      fallback: _asString(roomDoc.data()?['hostId']),
    );
    final moderationService = ModerationService(firestore: _firestore);
    final excludedUserIds = await moderationService.getExcludedUserIds(normalizedUserId);

    if (ownerId.isNotEmpty) {
      final hasBlockingRelationship =
          await moderationService.hasBlockingRelationship(normalizedUserId, ownerId);
      if (hasBlockingRelationship) {
        return RoomJoinResult.failure(
          'You cannot join this room.',
          excludedUserIds: excludedUserIds,
        );
      }
    }

    if (excludedUserIds.isNotEmpty) {
      final participantsSnapshot = await _firestore
          .collection('rooms')
          .doc(normalizedRoomId)
          .collection('participants')
          .get();
      final hasBlockedParticipant = participantsSnapshot.docs.any((doc) {
        final participantData = doc.data();
        final participantId = _asString(
          participantData['userId'],
          fallback: doc.id,
        );
        return participantId.isNotEmpty &&
            participantId != normalizedUserId &&
            excludedUserIds.contains(participantId);
      });
      if (hasBlockedParticipant) {
        return RoomJoinResult.failure(
          'You cannot join while a blocked user is in this room.',
          excludedUserIds: excludedUserIds,
        );
      }
    }

    final isLocked = _asBool(roomDoc.data()?['isLocked']);
    if (isLocked) {
      return RoomJoinResult.failure(
        'Room is locked by host.',
        excludedUserIds: excludedUserIds,
      );
    }

    final participantRef = _firestore
        .collection('rooms')
        .doc(normalizedRoomId)
        .collection('participants')
        .doc(normalizedUserId);
    final memberRef = _firestore
        .collection('rooms')
        .doc(normalizedRoomId)
        .collection('members')
        .doc(normalizedUserId);
    final participantDoc = await participantRef.get();
    if (participantDoc.exists) {
      final data = participantDoc.data() ?? <String, dynamic>{};
      if (data['isBanned'] == true) {
        return RoomJoinResult.failure(
          'You are banned from this room.',
          excludedUserIds: excludedUserIds,
        );
      }
      final correctedRole = ownerId == normalizedUserId
          ? 'host'
          : (data['role'] as String? ?? 'audience');
      await participantRef.update({
        'lastActiveAt': now,
        'role': correctedRole,
        'camOn': false,
        'userStatus': 'online',
      });
      await memberRef.set({
        'userId': normalizedUserId,
        'role': ownerId == normalizedUserId ? 'owner' : 'member',
        'joinedAt': data['joinedAt'] ?? now,
        'lastActiveAt': now,
      }, SetOptions(merge: true));
    } else {
      final participantRole = ownerId == normalizedUserId ? 'host' : 'audience';
      await participantRef.set({
        'userId': normalizedUserId,
        'role': participantRole,
        'isMuted': false,
        'isBanned': false,
        'camOn': false,
        'joinedAt': now,
        'lastActiveAt': now,
        'userStatus': 'online',
      });
      await memberRef.set({
        'userId': normalizedUserId,
        'role': ownerId == normalizedUserId ? 'owner' : 'member',
        'joinedAt': now,
        'lastActiveAt': now,
      });
    }

    await _presenceService.setInRoom(normalizedUserId, normalizedRoomId);
    return RoomJoinResult.success(
      joinedAt: now,
      excludedUserIds: excludedUserIds,
    );
  }

  Future<void> leaveRoom({
    required String roomId,
    required String userId,
  }) async {
    final normalizedRoomId = roomId.trim();
    final normalizedUserId = userId.trim();
    if (normalizedRoomId.isEmpty || normalizedUserId.isEmpty) {
      return;
    }

    final participantRef = _firestore
        .collection('rooms')
        .doc(normalizedRoomId)
        .collection('participants')
        .doc(normalizedUserId);
    final memberRef = _firestore
        .collection('rooms')
        .doc(normalizedRoomId)
        .collection('members')
        .doc(normalizedUserId);

    try {
      await participantRef.delete();
      await memberRef.delete();
    } finally {
      await _presenceService.clearRoom(normalizedUserId);
    }
  }

  Future<DateTime> heartbeat({
    required String roomId,
    required String userId,
    DateTime? lastParticipantSyncAt,
    bool forceParticipantSync = false,
  }) async {
    final now = DateTime.now();
    await _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('participants')
        .doc(userId)
        .set({
      'userId': userId,
      'lastActiveAt': FieldValue.serverTimestamp(),
      'userStatus': 'online',
    }, SetOptions(merge: true));
    await _presenceService.setInRoom(userId, roomId);
    if (forceParticipantSync ||
        lastParticipantSyncAt == null ||
        now.difference(lastParticipantSyncAt) >= participantSyncInterval) {
      return now;
    }
    return lastParticipantSyncAt;
  }

  Future<void> setCustomStatus({
    required String roomId,
    required String userId,
    required String? status,
    String userStatus = 'online',
  }) {
    return _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('participants')
        .doc(userId)
        .set({
      'userId': userId,
      'customStatus': status,
      'userStatus': userStatus,
      'lastActiveAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> postSystemEvent({
    required String roomId,
    required String content,
  }) {
    return _firestore.collection('rooms').doc(roomId).collection('messages').add({
      'senderId': 'system',
      'roomId': roomId,
      'content': content,
      'type': 'system',
      'richText': '',
      'sentAt': FieldValue.serverTimestamp(),
      'clientSentAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> setTyping({
    required String roomId,
    required String userId,
    required bool isTyping,
  }) async {
    final typingRef = _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('typing')
        .doc(userId);
    if (isTyping) {
      await typingRef.set({
        'isTyping': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return;
    }
    await typingRef.delete();
  }

  Future<void> setSpotlightUser({
    required String roomId,
    required String? userId,
  }) async {
    await _firestore.collection('rooms').doc(roomId).update({
      'spotlightUserId': userId == null || userId.trim().isEmpty
          ? FieldValue.delete()
          : userId.trim(),
    });
  }
}