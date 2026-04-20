import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import 'package:mixvy/core/providers/firebase_providers.dart';
import 'package:mixvy/models/room_model.dart';
import 'package:mixvy/models/user_model.dart';
import 'package:mixvy/services/room_service.dart';

// ── Following-live rooms ──────────────────────────────────────────────────────

/// Live rooms where the users that [userId] follows are currently hosting.
/// Emits every time the follows collection changes.
final followingLiveRoomsProvider =
    StreamProvider.family<List<RoomModel>, String>((ref, userId) {
      if (userId.isEmpty) {
        return const Stream<List<RoomModel>>.empty();
      }

      final firestore = ref.watch(firestoreProvider);
      final roomService = ref.watch(roomServiceProvider);
      final controller = StreamController<List<RoomModel>>();

      StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? followsSub;
      StreamSubscription<List<RoomModel>>? liveRoomsSub;
      var followedIds = <String>{};
      var currentRooms = const <RoomModel>[];

      void emitFilteredRooms() {
        if (controller.isClosed) {
          return;
        }
        if (followedIds.isEmpty) {
          controller.add(const <RoomModel>[]);
          return;
        }

        final filtered = currentRooms
            .where((room) => followedIds.contains(room.hostId))
            .take(12)
            .toList(growable: false);
        controller.add(filtered);
      }

      followsSub = firestore
          .collection('follows')
          .where('followerUserId', isEqualTo: userId)
          .snapshots()
          .listen((followSnap) {
            followedIds = followSnap.docs
                .map((d) => d.data()['followedUserId'] as String?)
                .whereType<String>()
                .map((id) => id.trim())
                .where((id) => id.isNotEmpty)
                .toSet();
            emitFilteredRooms();
          }, onError: controller.addError);

      liveRoomsSub = roomService.watchLiveRooms(limit: 100).listen((rooms) {
        currentRooms = rooms;
        emitFilteredRooms();
      }, onError: controller.addError);

      Future<void> disposeSubscriptions() async {
        await followsSub?.cancel();
        await liveRoomsSub?.cancel();
        if (!controller.isClosed) {
          await controller.close();
        }
      }

      ref.onDispose(() {
        unawaited(disposeSubscriptions());
      });

      controller.onCancel = disposeSubscriptions;

      return controller.stream;
    });

// ── Following users list ──────────────────────────────────────────────────────

/// User profiles of everyone that [userId] follows (max 50).
final followingUsersProvider = StreamProvider.family<List<UserModel>, String>((
  ref,
  userId,
) {
  if (userId.isEmpty) return const Stream.empty();
  final firestore = ref.watch(firestoreProvider);

  return firestore
      .collection('follows')
      .where('followerUserId', isEqualTo: userId)
      .limit(50)
      .snapshots()
      .asyncExpand((snap) async* {
        final ids = snap.docs
            .map((d) => d.data()['followedUserId'] as String?)
            .whereType<String>()
            .toList();

        if (ids.isEmpty) {
          yield const <UserModel>[];
          return;
        }

        final users = <UserModel>[];
        for (var i = 0; i < ids.length; i += 10) {
          final batch = ids.sublist(i, (i + 10).clamp(0, ids.length));
          try {
            final userSnap = await firestore
                .collection('users')
                .where(FieldPath.documentId, whereIn: batch)
                .get();
            for (final doc in userSnap.docs) {
              final data = Map<String, dynamic>.from(doc.data());
              data['id'] = doc.id;
              users.add(UserModel.fromJson(data));
            }
          } on FirebaseException {
            continue;
          }
        }

        yield users;
      });
});

// ── For-You rooms ─────────────────────────────────────────────────────────────

/// Personalised live room suggestions based on the user's [interests].
/// Falls back to most-active rooms when no interests are stored.
final forYouRoomsProvider = FutureProvider.family
    .autoDispose<List<RoomModel>, String>((ref, userId) async {
      if (userId.isEmpty) return const [];
      final firestore = ref.watch(firestoreProvider);
      final roomService = ref.watch(roomServiceProvider);

      // Load user interests.
      List<String> interests = const [];
      try {
        final doc = await firestore.collection('users').doc(userId).get();
        interests = List<String>.from(doc.data()?['interests'] ?? const []);
      } on FirebaseException {
        // Fall through to generic rooms.
      }

      const validCats = {
        'music',
        'gaming',
        'dating',
        'talk',
        'art',
        'dance',
        'study',
        'chill',
      };
      final cats = interests
          .map((i) => i.toLowerCase().trim())
          .where(validCats.contains)
          .take(3)
          .toSet();

      final liveRooms = await roomService.getLiveRooms(
        limit: 60,
        includeAdultRooms: false,
      );

      if (cats.isEmpty) {
        final sorted = liveRooms.toList(growable: false)
          ..sort((a, b) {
            final memberCompare = b.memberCount.compareTo(a.memberCount);
            if (memberCompare != 0) {
              return memberCompare;
            }
            final updatedA =
                a.updatedAt?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
            final updatedB =
                b.updatedAt?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
            return updatedB.compareTo(updatedA);
          });
        return sorted.take(12).toList(growable: false);
      }

      final matched = liveRooms
          .where((room) {
            final roomCategory = room.category?.trim().toLowerCase();
            return roomCategory != null && cats.contains(roomCategory);
          })
          .toList(growable: false);

      if (matched.isEmpty) {
        return liveRooms.take(12).toList(growable: false);
      }

      matched.sort((a, b) {
        final memberCompare = b.memberCount.compareTo(a.memberCount);
        if (memberCompare != 0) {
          return memberCompare;
        }
        final updatedA =
            a.updatedAt?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
        final updatedB =
            b.updatedAt?.toDate() ?? DateTime.fromMillisecondsSinceEpoch(0);
        return updatedB.compareTo(updatedA);
      });
      return matched.take(12).toList(growable: false);
    });

// ── New live rooms (recent) ───────────────────────────────────────────────────

/// Stream of live rooms ordered by creation time (newest first).
final newLiveRoomsProvider = StreamProvider.autoDispose<List<RoomModel>>((ref) {
  return ref.watch(roomServiceProvider).watchLiveRooms(limit: 20);
});
