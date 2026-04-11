import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';

import '../features/friends/models/friend_roster_entry.dart';
import '../features/friends/models/friendship_model.dart';
import '../models/friend_request_model.dart';
import '../models/presence_model.dart';
import '../models/user_model.dart';
import 'analytics_service.dart';
import 'moderation_service.dart';
import 'presence_repository.dart';

class FriendService {
  FriendService({
    FirebaseFirestore? firestore,
    AnalyticsService? analyticsService,
    ModerationService? moderationService,
    PresenceRepository? presenceRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _analyticsService = analyticsService ?? AnalyticsService(),
        _moderationService = moderationService ??
            ModerationService(firestore: firestore ?? FirebaseFirestore.instance),
        _presenceRepository = presenceRepository ??
            FirestorePresenceRepository(firestore ?? FirebaseFirestore.instance);

  static const int _firestoreWhereInLimit = 30;

  final FirebaseFirestore _firestore;
  final AnalyticsService _analyticsService;
  final ModerationService _moderationService;
  final PresenceRepository _presenceRepository;

  bool _isPermissionDenied(Object error) {
    if (error is FirebaseException) {
      final code = error.code.trim().toLowerCase();
      return code == 'permission-denied' ||
          code == 'unauthenticated' ||
          code == 'unauthorized';
    }
    final normalized = error.toString().toLowerCase();
    return normalized.contains('permission-denied') ||
        normalized.contains('insufficient permissions') ||
        normalized.contains('unauthenticated') ||
        normalized.contains('unauthorized');
  }

  CollectionReference<Map<String, dynamic>> get _friendshipsCollection =>
      _firestore.collection('friendships');

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  List<String> _asStringList(dynamic value) {
    if (value is! List) {
      return const <String>[];
    }
    return value
        .map((entry) => entry is String ? entry.trim() : '')
        .where((entry) => entry.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  List<List<String>> _chunksOf(List<String> values, int size) {
    if (values.isEmpty) {
      return const <List<String>>[];
    }

    final chunks = <List<String>>[];
    for (var index = 0; index < values.length; index += size) {
      final end = (index + size) > values.length ? values.length : index + size;
      chunks.add(values.sublist(index, end));
    }
    return chunks;
  }

  String friendshipIdFor(String firstUserId, String secondUserId) {
    return FriendshipModel.canonicalIdFor(firstUserId, secondUserId);
  }

  Stream<List<FriendshipModel>> watchFriendships(
    String userId, {
    Set<String> statuses = const <String>{},
  }) {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      return Stream.value(const <FriendshipModel>[]);
    }

    final normalizedStatuses = statuses
        .map((status) => status.trim().toLowerCase())
        .where((status) => status.isNotEmpty)
        .toSet();

    return Stream.multi((controller) {
      List<FriendshipModel> userAFriendships = const <FriendshipModel>[];
      List<FriendshipModel> userBFriendships = const <FriendshipModel>[];

      void emit() {
        final merged = <String, FriendshipModel>{
          for (final friendship in userAFriendships) friendship.id: friendship,
          for (final friendship in userBFriendships) friendship.id: friendship,
        };

        final friendships = merged.values.toList(growable: false)
          ..sort((left, right) {
            final createdCompare = right.createdAt.compareTo(left.createdAt);
            if (createdCompare != 0) return createdCompare;
            return left.id.compareTo(right.id);
          });
        controller.add(friendships);
      }

      Query<Map<String, dynamic>> buildQuery(String field) {
        var query = _friendshipsCollection.where(field, isEqualTo: normalizedUserId);
        if (normalizedStatuses.length == 1) {
          query = query.where('status', isEqualTo: normalizedStatuses.first);
        } else if (normalizedStatuses.length > 1) {
          query = query.where('status', whereIn: normalizedStatuses.toList(growable: false));
        }
        return query;
      }

      final subA = buildQuery('userA').snapshots().listen((snapshot) {
        userAFriendships = snapshot.docs
            .map((doc) => FriendshipModel.fromJson(doc.id, doc.data()))
            .toList(growable: false);
        emit();
      }, onError: (error, stackTrace) {
        if (_isPermissionDenied(error)) {
          userAFriendships = const <FriendshipModel>[];
          emit();
          return;
        }
        controller.addError(error, stackTrace);
      });

      final subB = buildQuery('userB').snapshots().listen((snapshot) {
        userBFriendships = snapshot.docs
            .map((doc) => FriendshipModel.fromJson(doc.id, doc.data()))
            .toList(growable: false);
        emit();
      }, onError: (error, stackTrace) {
        if (_isPermissionDenied(error)) {
          userBFriendships = const <FriendshipModel>[];
          emit();
          return;
        }
        controller.addError(error, stackTrace);
      });

      controller.onCancel = () async {
        await subA.cancel();
        await subB.cancel();
      };
    });
  }

  Stream<List<FriendshipModel>> watchAcceptedFriendships(String userId) {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      return Stream.value(const <FriendshipModel>[]);
    }

    return Stream.multi((controller) {
      StreamSubscription<List<FriendshipModel>>? primarySub;
      StreamSubscription<List<FriendshipModel>>? fallbackSub;

      void startFallback() {
        if (fallbackSub != null) return;
        fallbackSub = _watchAcceptedFriendshipsFromUserDoc(normalizedUserId).listen(
          controller.add,
          onError: controller.addError,
        );
      }

      primarySub = watchFriendships(
        normalizedUserId,
        statuses: const <String>{'accepted'},
      ).listen(
        controller.add,
        onError: (error, stackTrace) {
          if (_isPermissionDenied(error)) {
            startFallback();
            return;
          }
          controller.addError(error, stackTrace);
        },
      );

      controller.onCancel = () async {
        await primarySub?.cancel();
        await fallbackSub?.cancel();
      };
    });
  }

  Stream<List<FriendshipModel>> _watchAcceptedFriendshipsFromUserDoc(
      String userId,
      ) {
    return _usersCollection.doc(userId).snapshots().map((doc) {
      final data = doc.data();
      if (!doc.exists || data == null) {
        return const <FriendshipModel>[];
      }

      final friendIds = _asStringList(data['friends']);
      final fallbackCreatedAt = DateTime.fromMillisecondsSinceEpoch(0);
      return friendIds.map((friendId) {
        final sorted = FriendshipModel.sortedPair(userId, friendId);
        return FriendshipModel(
          id: FriendshipModel.canonicalIdFor(userId, friendId),
          userA: sorted.userA,
          userB: sorted.userB,
          status: 'accepted',
          createdAt: fallbackCreatedAt,
        );
      }).toList(growable: false);
    });
  }

  Stream<List<UserModel>> watchFriends(String userId) {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      return Stream.value(const <UserModel>[]);
    }

    return Stream.multi((controller) {
      StreamSubscription<List<FriendshipModel>>? friendshipsSub;
      StreamSubscription<List<UserModel>>? usersSub;

      Future<void> bindUsers(List<FriendshipModel> friendships) async {
        final excludedIds = await _moderationService.getExcludedUserIds(normalizedUserId);
        final friendIds = friendships
            .map((friendship) => friendship.otherUserId(normalizedUserId))
            .where((friendId) => friendId.isNotEmpty && !excludedIds.contains(friendId))
            .toList(growable: false);

        await usersSub?.cancel();
        if (friendIds.isEmpty) {
          controller.add(const <UserModel>[]);
          return;
        }

        usersSub = _watchUsersByIds(friendIds).listen((users) {
          final usersById = <String, UserModel>{for (final user in users) user.id: user};
          final ordered = friendIds
              .map((friendId) => usersById[friendId])
              .whereType<UserModel>()
              .toList(growable: false);
          controller.add(ordered);
        }, onError: controller.addError);
      }

      friendshipsSub = watchAcceptedFriendships(normalizedUserId).listen(
        (friendships) => bindUsers(friendships),
        onError: (error, stackTrace) {
          if (_isPermissionDenied(error)) {
            controller.add(const <UserModel>[]);
            return;
          }
          controller.addError(error, stackTrace);
        },
      );

      controller.onCancel = () async {
        await friendshipsSub?.cancel();
        await usersSub?.cancel();
      };
    });
  }

  Stream<List<FriendRosterEntry>> watchFriendRoster(String userId) {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      return Stream.value(const <FriendRosterEntry>[]);
    }

    return Stream.multi((controller) {
      StreamSubscription<List<FriendshipModel>>? friendshipsSub;
      StreamSubscription<List<UserModel>>? usersSub;
      StreamSubscription<Map<String, PresenceModel>>? presenceSub;

      List<FriendshipModel> latestFriendships = const <FriendshipModel>[];
      Map<String, UserModel> usersById = const <String, UserModel>{};
      Map<String, PresenceModel> presenceById = const <String, PresenceModel>{};
      var usersReady = false;
      var presenceReady = false;

      void emit() {
        if (latestFriendships.isNotEmpty && (!usersReady || !presenceReady)) {
          return;
        }
        final entries = latestFriendships
            .map((friendship) {
              final friendId = friendship.otherUserId(normalizedUserId);
              final user = usersById[friendId];
              if (friendId.isEmpty || user == null) {
                return null;
              }
              final presence = presenceById[friendId] ??
                  PresenceModel(
                    userId: friendId,
                    isOnline: false,
                    status: UserStatus.offline,
                  );
              return FriendRosterEntry(
                friendship: friendship,
                user: user,
                presence: presence,
              );
            })
            .whereType<FriendRosterEntry>()
            .toList(growable: false)
          ..sort((left, right) =>
              left.user.username.toLowerCase().compareTo(right.user.username.toLowerCase()));
        controller.add(entries);
      }

      void logPresenceTransitions(Map<String, PresenceModel> nextPresenceById) {
        for (final entry in nextPresenceById.entries) {
          final previous = presenceById[entry.key];
          final previousOnline = previous?.isOnline == true;
          final nextOnline = entry.value.isOnline == true;
          if (previous != null && previousOnline != nextOnline) {
            developer.log(
              'friend_presence_changed userId=${entry.key} online=$nextOnline roomId=${entry.value.inRoom ?? '-'}',
              name: 'FriendService',
            );
          }
        }
      }

      Future<void> rebindFriendData(List<FriendshipModel> friendships) async {
        final excludedIds = await _moderationService.getExcludedUserIds(normalizedUserId);
        final filteredFriendships = friendships
            .where((friendship) =>
                !excludedIds.contains(friendship.otherUserId(normalizedUserId)))
            .toList(growable: false);
        final friendIds = filteredFriendships
            .map((friendship) => friendship.otherUserId(normalizedUserId))
            .where((friendId) => friendId.isNotEmpty)
            .toList(growable: false);

        latestFriendships = filteredFriendships;

        await usersSub?.cancel();
        await presenceSub?.cancel();
        usersReady = false;
        presenceReady = false;

        if (friendIds.isEmpty) {
          usersById = const <String, UserModel>{};
          presenceById = const <String, PresenceModel>{};
          usersReady = true;
          presenceReady = true;
          emit();
          return;
        }

        usersSub = _watchUsersByIds(friendIds).listen((users) {
          usersById = {for (final user in users) user.id: user};
          usersReady = true;
          emit();
        }, onError: (error, stackTrace) {
          if (_isPermissionDenied(error)) {
            usersById = const <String, UserModel>{};
            usersReady = true;
            emit();
            return;
          }
          controller.addError(error, stackTrace);
        });

        presenceSub = _watchPresenceByUserIds(friendIds).listen((presenceMap) {
          logPresenceTransitions(presenceMap);
          presenceById = presenceMap;
          presenceReady = true;
          emit();
        }, onError: (error, stackTrace) {
          if (_isPermissionDenied(error)) {
            presenceById = const <String, PresenceModel>{};
            presenceReady = true;
            emit();
            return;
          }
          controller.addError(error, stackTrace);
        });
      }

      friendshipsSub = watchAcceptedFriendships(normalizedUserId).listen(
        (friendships) => rebindFriendData(friendships),
        onError: (error, stackTrace) {
          if (_isPermissionDenied(error)) {
            latestFriendships = const <FriendshipModel>[];
            usersById = const <String, UserModel>{};
            presenceById = const <String, PresenceModel>{};
            usersReady = true;
            presenceReady = true;
            emit();
            return;
          }
          controller.addError(error, stackTrace);
        },
      );

      controller.onCancel = () async {
        await friendshipsSub?.cancel();
        await usersSub?.cancel();
        await presenceSub?.cancel();
      };
    });
  }

  Stream<List<FriendRequestModel>> incomingRequests(String userId) {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      return Stream.value(const <FriendRequestModel>[]);
    }

    return watchFriendships(normalizedUserId, statuses: const <String>{'pending'}).map((friendships) {
      final requests = friendships
          .where((friendship) => friendship.requestedBy != normalizedUserId)
          .map(
            (friendship) => FriendRequestModel(
              id: friendship.id,
              fromUserId: friendship.requestedBy ?? friendship.userA,
              toUserId: normalizedUserId,
              status: friendship.status,
              createdAt: friendship.createdAt,
            ),
          )
          .toList(growable: false)
        ..sort((left, right) => right.createdAt.compareTo(left.createdAt));
      return requests;
    });
  }

  Stream<List<String>> outgoingPendingRequestIds(String userId) {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      return Stream.value(const <String>[]);
    }

    return watchFriendships(normalizedUserId, statuses: const <String>{'pending'}).map((friendships) {
      return friendships
          .where((friendship) => friendship.requestedBy == normalizedUserId)
          .map((friendship) => friendship.otherUserId(normalizedUserId))
          .where((friendId) => friendId.isNotEmpty)
          .toList(growable: false);
    });
  }

  Future<void> sendFriendRequest(String fromUserId, String toUserId) async {
    final normalizedFromUserId = fromUserId.trim();
    final normalizedToUserId = toUserId.trim();
    if (normalizedFromUserId.isEmpty ||
        normalizedToUserId.isEmpty ||
        normalizedFromUserId == normalizedToUserId) {
      return;
    }

    if (await _moderationService.hasBlockingRelationship(normalizedFromUserId, normalizedToUserId)) {
      return;
    }

    final fromUserDoc = await _usersCollection.doc(normalizedFromUserId).get();
    final toUserDoc = await _usersCollection.doc(normalizedToUserId).get();
    if (!fromUserDoc.exists || !toUserDoc.exists) {
      return;
    }

    final friendshipId = friendshipIdFor(normalizedFromUserId, normalizedToUserId);
    final friendshipRef = _friendshipsCollection.doc(friendshipId);
    final friendshipSnap = await friendshipRef.get();
    final sortedPair = FriendshipModel.sortedPair(normalizedFromUserId, normalizedToUserId);

    if (friendshipSnap.exists) {
      final friendship = FriendshipModel.fromJson(
        friendshipSnap.id,
        friendshipSnap.data() ?? <String, dynamic>{},
      );

      if (friendship.status == 'accepted' || friendship.status == 'blocked') {
        return;
      }

      if (friendship.status == 'pending') {
        if (friendship.requestedBy == normalizedFromUserId) {
          return;
        }
        await acceptFriendRequest(friendship.id);
        return;
      }
    }

    await friendshipRef.set({
      'userA': sortedPair.userA,
      'userB': sortedPair.userB,
      'status': 'pending',
      'requestedBy': normalizedFromUserId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final fromUser = await getUserById(normalizedFromUserId);
    await _createNotification(
      normalizedToUserId,
      type: 'friend_request',
      content: '${fromUser?.username ?? 'Someone'} sent you a friend request.',
      actorId: normalizedFromUserId,
    );

    developer.log(
      'friend_request_sent from=$normalizedFromUserId to=$normalizedToUserId friendshipId=$friendshipId',
      name: 'FriendService',
    );

    try {
      await _analyticsService.logEvent('friend_request_sent', params: {
        'from_user_id': normalizedFromUserId,
        'to_user_id': normalizedToUserId,
        'friendship_id': friendshipId,
      });
    } catch (_) {
      // Keep the friendship flow resilient when analytics is unavailable.
    }
  }

  Future<void> acceptFriendRequest(String requestId) async {
    final normalizedRequestId = requestId.trim();
    if (normalizedRequestId.isEmpty) return;

    final friendshipRef = _friendshipsCollection.doc(normalizedRequestId);
    final friendshipSnap = await friendshipRef.get();
    if (!friendshipSnap.exists) return;

    final friendship = FriendshipModel.fromJson(
      friendshipSnap.id,
      friendshipSnap.data() ?? <String, dynamic>{},
    );
    if (friendship.status != 'pending') {
      return;
    }

    await friendshipRef.set({
      'status': 'accepted',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final accepterId =
        friendship.requestedBy == friendship.userA ? friendship.userB : friendship.userA;
    final accepter = await getUserById(accepterId);
    final requesterId = friendship.requestedBy ?? friendship.userA;

    await _createNotification(
      requesterId,
      type: 'friend_accept',
      content: '${accepter?.username ?? 'Someone'} accepted your friend request.',
      actorId: accepterId,
    );

    developer.log(
      'friend_request_accepted friendshipId=$normalizedRequestId requester=$requesterId accepter=$accepterId',
      name: 'FriendService',
    );

    try {
      await _analyticsService.logEvent('friend_request_accepted', params: {
        'friendship_id': normalizedRequestId,
        'requester_id': requesterId,
        'accepter_id': accepterId,
      });
    } catch (_) {
      // Keep the friendship flow resilient when analytics is unavailable.
    }
  }

  Future<void> declineFriendRequest(String requestId) async {
    final normalizedRequestId = requestId.trim();
    if (normalizedRequestId.isEmpty) return;

    final friendshipRef = _friendshipsCollection.doc(normalizedRequestId);
    final friendshipSnap = await friendshipRef.get();
    if (!friendshipSnap.exists) {
      return;
    }

    final friendship = FriendshipModel.fromJson(
      friendshipSnap.id,
      friendshipSnap.data() ?? <String, dynamic>{},
    );
    if (friendship.status != 'pending') {
      return;
    }

    await friendshipRef.delete();
  }

  Future<List<UserModel>> getFriends(String userId) async {
    final friendIds = await getFriendIds(userId);
    if (friendIds.isEmpty) return const <UserModel>[];

    final excludedIds = await _moderationService.getExcludedUserIds(userId);
    final visibleFriendIds = friendIds
        .where((id) => !excludedIds.contains(id))
        .toList(growable: false);
    if (visibleFriendIds.isEmpty) {
      return const <UserModel>[];
    }

    final favoriteIds = await getFavoriteFriendIds(userId);
    final friends = await getUsersByIds(visibleFriendIds);

    friends.sort((a, b) {
      final aFav = favoriteIds.contains(a.id) ? 0 : 1;
      final bFav = favoriteIds.contains(b.id) ? 0 : 1;
      if (aFav != bFav) return aFav.compareTo(bFav);
      return a.username.toLowerCase().compareTo(b.username.toLowerCase());
    });
    return friends;
  }

  Future<UserModel?> getUserById(String userId) async {
    final snapshot = await _usersCollection.doc(userId).get();
    if (!snapshot.exists) {
      return null;
    }

    return UserModel.fromJson({'id': snapshot.id, ...?snapshot.data()});
  }

  Future<List<UserModel>> getUsersByIds(List<String> userIds) async {
    if (userIds.isEmpty) {
      return const <UserModel>[];
    }

    final uniqueIds = userIds.toSet().toList(growable: false);
    final usersById = <String, UserModel>{};
    for (final chunk in _chunksOf(uniqueIds, _firestoreWhereInLimit)) {
      final query = await _usersCollection
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in query.docs) {
        usersById[doc.id] = UserModel.fromJson({'id': doc.id, ...doc.data()});
      }
    }

    return uniqueIds
        .map((userId) => usersById[userId])
        .whereType<UserModel>()
        .toList(growable: false);
  }

  Future<List<String>> getFriendIds(String userId) async {
    final friendships = await _getFriendships(userId, statuses: const <String>{'accepted'});
    return friendships
        .map((friendship) => friendship.otherUserId(userId))
        .where((friendId) => friendId.isNotEmpty)
        .toList(growable: false);
  }

  Future<Set<String>> getFavoriteFriendIds(String userId) async {
    final userDoc = await _usersCollection.doc(userId).get();
    if (!userDoc.exists) return const <String>{};
    final data = userDoc.data() ?? <String, dynamic>{};
    return _asStringList(data['favoriteFriendIds']).toSet();
  }

  Future<void> setFavorite(String userId, String friendId, {required bool isFavorite}) async {
    if (userId.trim().isEmpty || friendId.trim().isEmpty) return;
    await _usersCollection.doc(userId).set({
      'favoriteFriendIds': isFavorite
          ? FieldValue.arrayUnion([friendId])
          : FieldValue.arrayRemove([friendId]),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    if (isFavorite) {
      await _createNotification(
        friendId,
        type: 'friend_favorite',
        content: 'Someone added you as a favorite friend.',
        actorId: userId,
      );
    }
  }

  Future<List<String>> getIncomingRequesterIds(String userId) async {
    final friendships = await _getFriendships(userId, statuses: const <String>{'pending'});
    return friendships
        .where((friendship) => friendship.requestedBy != userId.trim())
        .map((friendship) => friendship.requestedBy ?? '')
        .where((requesterId) => requesterId.isNotEmpty)
        .toList(growable: false);
  }

  Future<List<String>> getOutgoingPendingRequestIds(String userId) async {
    final normalizedUserId = userId.trim();
    final friendships = await _getFriendships(normalizedUserId, statuses: const <String>{'pending'});
    return friendships
        .where((friendship) => friendship.requestedBy == normalizedUserId)
        .map((friendship) => friendship.otherUserId(normalizedUserId))
        .where((friendId) => friendId.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> removeFriend(String userId, String friendId) async {
    final friendshipId = friendshipIdFor(userId, friendId);
    await _friendshipsCollection.doc(friendshipId).delete();
  }

  Future<List<UserModel>> searchUsers(
    String query, {
    String? currentUserId,
    List<String> excludeUserIds = const <String>[],
  }) async {
    final normalizedQuery = query.trim().toLowerCase();
    final blockedIds = currentUserId == null
        ? const <String>{}
        : await _moderationService.getExcludedUserIds(currentUserId);

    QuerySnapshot<Map<String, dynamic>> snapshot;
    if (normalizedQuery.isEmpty) {
      snapshot = await _usersCollection
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
    } else {
      snapshot = await _usersCollection
          .where('usernameLower', isGreaterThanOrEqualTo: normalizedQuery)
          .where('usernameLower', isLessThan: '$normalizedQuery\uf8ff')
          .limit(20)
          .get();
    }

    return snapshot.docs
        .map((doc) => UserModel.fromJson({'id': doc.id, ...doc.data()}))
        .where((user) => user.id.isNotEmpty)
        .where((user) => user.id != currentUserId)
        .where((user) => !excludeUserIds.contains(user.id))
        .where((user) => !blockedIds.contains(user.id))
        .where((user) {
          if (normalizedQuery.isEmpty) return true;
          return user.username.toLowerCase().contains(normalizedQuery);
        })
        .toList(growable: false);
  }

  Future<List<UserModel>> getFriendSuggestions(
    String userId, {
    int limit = 20,
  }) async {
    if (userId.trim().isEmpty) return const <UserModel>[];

    final myFriendIds = (await getFriendIds(userId)).toSet();
    if (myFriendIds.isEmpty) return const <UserModel>[];

    final excludedIds = await _moderationService.getExcludedUserIds(userId);
    final excluded = {...excludedIds, userId, ...myFriendIds};

    final mutualCount = <String, int>{};
    for (final friendId in myFriendIds) {
      final theirFriendIds = await getFriendIds(friendId);
      for (final candidate in theirFriendIds) {
        if (excluded.contains(candidate)) continue;
        mutualCount[candidate] = (mutualCount[candidate] ?? 0) + 1;
      }
    }
    if (mutualCount.isEmpty) return const <UserModel>[];

    final sorted = mutualCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topIds = sorted.take(limit).map((entry) => entry.key).toList(growable: false);
    if (topIds.isEmpty) return const <UserModel>[];

    return getUsersByIds(topIds);
  }

  Stream<List<UserModel>> _watchUsersByIds(List<String> userIds) {
    final normalizedIds = userIds.toSet().toList(growable: false);
    if (normalizedIds.isEmpty) {
      return Stream.value(const <UserModel>[]);
    }

    return Stream.multi((controller) {
      final chunks = _chunksOf(normalizedIds, _firestoreWhereInLimit);
      final chunkMaps = List<Map<String, UserModel>>.generate(
        chunks.length,
        (_) => <String, UserModel>{},
      );
      final subscriptions = <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[];

      void emit() {
        final merged = <String, UserModel>{};
        for (final chunkMap in chunkMaps) {
          merged.addAll(chunkMap);
        }
        controller.add(
          normalizedIds
              .map((userId) => merged[userId])
              .whereType<UserModel>()
              .toList(growable: false),
        );
      }

      for (var index = 0; index < chunks.length; index += 1) {
        final chunk = chunks[index];
        final sub = _usersCollection
            .where(FieldPath.documentId, whereIn: chunk)
            .snapshots()
            .listen((snapshot) {
          chunkMaps[index] = {
            for (final doc in snapshot.docs)
              doc.id: UserModel.fromJson({'id': doc.id, ...doc.data()}),
          };
          emit();
        }, onError: (error, stackTrace) {
          if (_isPermissionDenied(error)) {
            chunkMaps[index] = <String, UserModel>{};
            emit();
            return;
          }
          controller.addError(error, stackTrace);
        });
        subscriptions.add(sub);
      }

      controller.onCancel = () async {
        for (final sub in subscriptions) {
          await sub.cancel();
        }
      };
    });
  }

  Stream<Map<String, PresenceModel>> _watchPresenceByUserIds(List<String> userIds) {
    return _presenceRepository.watchUsersPresence(userIds);
  }

  Future<List<FriendshipModel>> _getFriendships(
    String userId, {
    Set<String> statuses = const <String>{},
  }) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      return const <FriendshipModel>[];
    }

    Query<Map<String, dynamic>> buildQuery(String field) {
      var query = _friendshipsCollection.where(field, isEqualTo: normalizedUserId);
      if (statuses.length == 1) {
        query = query.where('status', isEqualTo: statuses.first);
      } else if (statuses.length > 1) {
        query = query.where('status', whereIn: statuses.toList(growable: false));
      }
      return query;
    }

    final results = await Future.wait([
      buildQuery('userA').get(),
      buildQuery('userB').get(),
    ]);

    final merged = <String, FriendshipModel>{};
    for (final snapshot in results) {
      for (final doc in snapshot.docs) {
        merged[doc.id] = FriendshipModel.fromJson(doc.id, doc.data());
      }
    }

    final friendships = merged.values.toList(growable: false)
      ..sort((left, right) {
        final createdCompare = right.createdAt.compareTo(left.createdAt);
        if (createdCompare != 0) return createdCompare;
        return left.id.compareTo(right.id);
      });
    return friendships;
  }

  Future<void> _createNotification(
    String userId, {
    required String type,
    required String content,
    required String actorId,
  }) async {
    await _firestore.collection('notifications').add({
      'userId': userId,
      'actorId': actorId,
      'type': type,
      'content': content,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
