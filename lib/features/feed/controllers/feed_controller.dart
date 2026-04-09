
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/room_model.dart';
import '../../../models/user_model.dart';
import '../../../services/moderation_service.dart';
import '../../../services/room_service.dart';
import '../../../core/firestore/firestore_error_utils.dart';

class FeedState {
  final bool isLoading;
  final String? error;
  final List<RoomModel> liveRooms;
  final List<RoomModel> upcomingRooms;
  final Map<String, String> roomReasons;
  final Map<String, String> roomTiers;
  final List<UserModel> trendingUsers;

  const FeedState({
    this.isLoading = false,
    this.error,
    this.liveRooms = const [],
    this.upcomingRooms = const [],
    this.roomReasons = const <String, String>{},
    this.roomTiers = const <String, String>{},
    this.trendingUsers = const [],
  });

  FeedState copyWith({
    bool? isLoading,
    String? error,
    List<RoomModel>? liveRooms,
    List<RoomModel>? upcomingRooms,
    Map<String, String>? roomReasons,
    Map<String, String>? roomTiers,
    List<UserModel>? trendingUsers,
  }) {
    return FeedState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      liveRooms: liveRooms ?? this.liveRooms,
      upcomingRooms: upcomingRooms ?? this.upcomingRooms,
      roomReasons: roomReasons ?? this.roomReasons,
      roomTiers: roomTiers ?? this.roomTiers,
      trendingUsers: trendingUsers ?? this.trendingUsers,
    );
  }
}

class FeedController extends Notifier<FeedState> {
  late final FirebaseFirestore _firestore;
  late final FirebaseAuth _auth;
  late final ModerationService _moderationService;
  late final RoomService _roomService;

  @override
  FeedState build() {
    _firestore = FirebaseFirestore.instance;
    _auth = FirebaseAuth.instance;
    _moderationService = ModerationService(firestore: _firestore, auth: _auth);
    _roomService = ref.read(roomServiceProvider);
    return const FeedState();
  }

  Future<Set<String>> _loadFriendIds(String? userId) async {
    if (userId == null || userId.trim().isEmpty) {
      return const <String>{};
    }

    final userDoc = await _firestore.collection('users').doc(userId).get();
    final data = userDoc.data();
    if (data == null) {
      return const <String>{};
    }

    return List<String>.from(data['friends'] ?? const <String>[]).toSet();
  }

  Future<void> loadFeed() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final currentUserId = _auth.currentUser?.uid;
      final blockedIds = currentUserId == null
          ? const <String>{}
          : await _moderationService.getExcludedUserIds(currentUserId);
      final friendIds = await _loadFriendIds(currentUserId);
      final liveRooms = await _roomService.getRecommendedLiveRooms(
        limit: 20,
        friendIds: friendIds,
        excludedHostIds: blockedIds,
      );
      final roomReasons = <String, String>{
        for (final room in liveRooms)
          room.id: _roomService.getRecommendationReason(
            room,
            friendIds: friendIds,
          ),
      };
      final roomTiers = <String, String>{
        for (final room in liveRooms)
          room.id: _roomService.getRecommendationTier(
            room,
            friendIds: friendIds,
          ),
      };
      final usersSnap = await _firestore
          .collection('users')
          .orderBy('balance', descending: true)
          .limit(10)
          .get();
      final trendingUsers = usersSnap.docs
          .map((doc) => UserModel.fromJson({'id': doc.id, ...doc.data()}))
          .where((user) => !blockedIds.contains(user.id))
          .toList();
      // Upcoming scheduled rooms (next 48 h)
      List<RoomModel> upcomingRooms = const [];
      try {
        upcomingRooms = await _roomService
            .watchUpcomingRooms(limit: 8)
            .first;
      } catch (_) {
        // non-critical; index may not exist yet in some environments
      }
      state = state.copyWith(
        isLoading: false,
        liveRooms: liveRooms,
        upcomingRooms: upcomingRooms,
        roomReasons: roomReasons,
        roomTiers: roomTiers,
        trendingUsers: trendingUsers,
      );
    } on FirebaseException catch (e, stackTrace) {
      logFirestoreError(
        context: 'discovery feed query',
        error: e,
        stackTrace: stackTrace,
      );
      state = state.copyWith(
        isLoading: false,
        error: friendlyFirestoreMessage(e, fallbackContext: 'the discovery feed'),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final feedControllerProvider = NotifierProvider<FeedController, FeedState>(
  () => FeedController(),
);
