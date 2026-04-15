import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firestore/firestore_debug_tracing.dart';
import '../../../models/room_participant_model.dart';
import 'room_firestore_provider.dart';

/// Streams the raw room document map. Used outside of `currentParticipantAsync`
/// so the host check resolves even before the participant document is written.
final roomDocStreamProvider = StreamProvider.autoDispose
    .family<Map<String, dynamic>?, String>((ref, roomId) {
      final firestore = ref.watch(roomFirestoreProvider);
      return traceFirestoreStream<Map<String, dynamic>?>(
        key: 'room_doc/$roomId',
        query: 'rooms/$roomId',
        roomId: roomId,
        itemCount: (value) => value == null ? 0 : 1,
        stream: firestore
            .collection('rooms')
            .doc(roomId)
            .snapshots()
            .map((snap) => snap.data()),
      );
    });

class CurrentParticipantParams {
  final String roomId;
  final String userId;

  const CurrentParticipantParams({required this.roomId, required this.userId});

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is CurrentParticipantParams &&
            other.roomId == roomId &&
            other.userId == userId);
  }

  @override
  int get hashCode => Object.hash(roomId, userId);
}

class Cohost {
  final String id;

  const Cohost(this.id);
}

final coHostsProvider = StreamProvider.autoDispose.family<List<Cohost>, String>(
  (ref, roomId) {
    final firestore = ref.watch(roomFirestoreProvider);
    return firestore
        .collection('rooms')
        .doc(roomId)
        .collection('participants')
        .where('role', isEqualTo: 'cohost')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Cohost(doc.id))
              .toList(growable: false),
        );
  },
);

final currentParticipantProvider = StreamProvider.autoDispose
    .family<RoomParticipantModel?, CurrentParticipantParams>((ref, params) {
      final firestore = ref.watch(roomFirestoreProvider);
      return traceFirestoreStream<RoomParticipantModel?>(
        key: 'current_participant/${params.roomId}/${params.userId}',
        query: 'rooms/${params.roomId}/participants/${params.userId}',
        roomId: params.roomId,
        userId: params.userId,
        itemCount: (value) => value == null ? 0 : 1,
        stream: firestore
            .collection('rooms')
            .doc(params.roomId)
            .collection('participants')
            .doc(params.userId)
            .snapshots()
            .map((doc) {
              if (!doc.exists) {
                return null;
              }
              return RoomParticipantModel.fromMap(
                doc.data() ?? <String, dynamic>{},
              );
            }),
      );
    });

const Duration _kParticipantFreshnessWindow = Duration(seconds: 90);

bool _isParticipantFresh(RoomParticipantModel participant, {DateTime? now}) {
  final normalizedRole = participant.role.trim().toLowerCase();
  final shouldKeepActiveSeatVisible =
      normalizedRole == 'host' ||
      normalizedRole == 'owner' ||
      normalizedRole == 'cohost' ||
      normalizedRole == 'stage' ||
      participant.camOn ||
      participant.micOn;
  if (shouldKeepActiveSeatVisible) {
    return true;
  }

  final currentTime = now ?? DateTime.now();
  return currentTime.difference(participant.lastActiveAt) <=
      _kParticipantFreshnessWindow;
}

List<RoomParticipantModel> _mapParticipants(
  QuerySnapshot<Map<String, dynamic>> snapshot,
) {
  final now = DateTime.now();
  return snapshot.docs
      .map((doc) => RoomParticipantModel.fromMap(doc.data()))
      .where((participant) => _isParticipantFresh(participant, now: now))
      .toList(growable: false);
}

final participantsStreamProvider = StreamProvider.autoDispose
    .family<List<RoomParticipantModel>, String>((ref, roomId) {
      final firestore = ref.watch(roomFirestoreProvider);
      return traceFirestoreStream<List<RoomParticipantModel>>(
        key: 'participants/$roomId',
        query: 'rooms/$roomId/participants orderBy joinedAt',
        roomId: roomId,
        itemCount: (value) => value.length,
        stream: firestore
            .collection('rooms')
            .doc(roomId)
            .collection('participants')
            .orderBy('joinedAt')
            .snapshots()
            .map(_mapParticipants),
      );
    });

final participantCountProvider = StreamProvider.autoDispose.family<int, String>(
  (ref, roomId) {
    final firestore = ref.watch(roomFirestoreProvider);
    return traceFirestoreStream<int>(
      key: 'participant_count/$roomId',
      query: 'rooms/$roomId/participants count',
      roomId: roomId,
      itemCount: (_) => 1,
      stream: firestore
          .collection('rooms')
          .doc(roomId)
          .collection('participants')
          .snapshots()
          .map((snapshot) => _mapParticipants(snapshot).length),
    );
  },
);

final isHostProvider = Provider.autoDispose.family<bool, RoomParticipantModel?>(
  (ref, participant) {
    final role = participant?.role;
    return role == 'host' || role == 'owner';
  },
);

final isCohostProvider = Provider.autoDispose
    .family<bool, RoomParticipantModel?>((ref, participant) {
      return participant?.role == 'cohost';
    });

/// Streams participants who are currently active on the mic:
/// host, cohost, and stage roles, using the same fresh-only room roster.
final onMicParticipantsProvider = StreamProvider.autoDispose
    .family<List<RoomParticipantModel>, String>((ref, roomId) {
      final controller = StreamController<List<RoomParticipantModel>>();
      ref.listen<AsyncValue<List<RoomParticipantModel>>>(
        participantsStreamProvider(roomId),
        (_, next) {
          next.whenData((participants) {
            controller.add(
              participants
                  .where(
                    (p) =>
                        p.role == 'host' ||
                        p.role == 'cohost' ||
                        p.role == 'stage',
                  )
                  .toList(growable: false),
            );
          });
        },
        fireImmediately: true,
      );
      ref.onDispose(controller.close);
      return controller.stream;
    });
