import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firestore/firestore_debug_tracing.dart';
import '../../../models/room_participant_model.dart';
import '../../../services/presence_repository.dart';
import 'room_firestore_provider.dart';

class RoomPresenceModel {
  const RoomPresenceModel({
    required this.userId,
    required this.isOnline,
    required this.lastHeartbeatAt,
    required this.lastSeenAt,
    this.customStatus,
    this.userStatus,
  });

  final String userId;
  final bool isOnline;
  final DateTime? lastHeartbeatAt;
  final DateTime? lastSeenAt;

  /// Optional free-text status/away message set by the user.
  final String? customStatus;

  /// Enum status: 'online' | 'away' | 'dnd' | 'offline'
  final String? userStatus;

  factory RoomPresenceModel.fromMap(String userId, Map<String, dynamic> data) {
    DateTime? toDate(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      }
      if (value is String) {
        return DateTime.tryParse(value);
      }
      return null;
    }

    bool toBool(dynamic value) {
      if (value is bool) {
        return value;
      }
      if (value is num) {
        return value != 0;
      }
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        if (normalized == 'true' || normalized == '1') {
          return true;
        }
      }
      return false;
    }

    return RoomPresenceModel(
      userId: userId,
      isOnline: toBool(data['isOnline']),
      lastHeartbeatAt: toDate(data['lastHeartbeatAt']),
      lastSeenAt: toDate(data['lastSeenAt']),
      customStatus: data['customStatus'] as String?,
      userStatus: data['userStatus'] as String?,
    );
  }
}

const Duration _kRoomPresenceFreshnessWindow = Duration(seconds: 90);

bool _isRoomParticipantActive(
  RoomParticipantModel participant, {
  DateTime? now,
}) {
  final normalizedRole = participant.role.trim().toLowerCase();
  final hasActiveSeat =
      normalizedRole == 'host' ||
      normalizedRole == 'owner' ||
      normalizedRole == 'cohost' ||
      normalizedRole == 'stage' ||
      participant.camOn ||
      participant.micOn;
  if (hasActiveSeat) {
    return true;
  }

  final normalizedStatus = participant.userStatus?.trim().toLowerCase() ?? '';
  if (normalizedStatus == 'offline') {
    return false;
  }

  final currentTime = now ?? DateTime.now();
  return currentTime.difference(participant.lastActiveAt) <=
      _kRoomPresenceFreshnessWindow;
}

final roomPresenceStreamProvider = StreamProvider.autoDispose
    .family<List<RoomPresenceModel>, String>((ref, roomId) {
      final firestore = ref.watch(roomFirestoreProvider);
      final presenceRepo = ref.watch(presenceRepositoryProvider);

      return traceFirestoreStream<List<RoomPresenceModel>>(
        key: 'room_presence/$roomId',
        query: 'rooms/$roomId/participants + global presence',
        roomId: roomId,
        itemCount: (value) => value.length,
        stream: firestore
            .collection('rooms')
            .doc(roomId)
            .collection('participants')
            .snapshots()
            .asyncExpand((snapshot) {
              final participants = snapshot.docs
                  .map((doc) {
                    final participant = RoomParticipantModel.fromMap(
                      doc.data(),
                    );
                    final userId = participant.userId.isEmpty
                        ? doc.id
                        : participant.userId;
                    return (participant: participant, userId: userId);
                  })
                  .toList(growable: false);

              final userIds = participants
                  .map((entry) => entry.userId)
                  .where((id) => id.trim().isNotEmpty)
                  .toSet()
                  .toList(growable: false);

              if (userIds.isEmpty) {
                return Stream.value(const <RoomPresenceModel>[]);
              }

              return presenceRepo.watchUsersPresence(userIds).map((
                presenceById,
              ) {
                final now = DateTime.now();
                return participants
                    .map((entry) {
                      final participant = entry.participant;
                      final userId = entry.userId;
                      final globalPresence = presenceById[userId];
                      final globalInRoom =
                          (globalPresence?.roomId ?? globalPresence?.inRoom)
                              ?.trim();
                      final globalRoomMatch =
                          globalPresence != null &&
                          globalPresence.isOnline == true &&
                          globalInRoom == roomId;
                      final participantRoomMatch = _isRoomParticipantActive(
                        participant,
                        now: now,
                      );

                      return RoomPresenceModel(
                        userId: userId,
                        isOnline: globalRoomMatch || participantRoomMatch,
                        lastHeartbeatAt:
                            globalPresence?.lastSeen ??
                            participant.lastActiveAt,
                        lastSeenAt:
                            globalPresence?.lastSeen ??
                            participant.lastActiveAt,
                        customStatus: participant.customStatus,
                        userStatus:
                            participant.userStatus ??
                            globalPresence?.status.name,
                      );
                    })
                    .toList(growable: false);
              });
            }),
      );
    });
