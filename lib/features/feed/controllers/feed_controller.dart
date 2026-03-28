
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/room_model.dart';
import '../../../models/user.dart' as feed_user;
import '../../../services/moderation_service.dart';

class FeedState {
  final bool isLoading;
  final String? error;
  final List<RoomModel> liveRooms;
  final List<feed_user.User> trendingUsers;

  const FeedState({
    this.isLoading = false,
    this.error,
    this.liveRooms = const [],
    this.trendingUsers = const [],
  });

  FeedState copyWith({
    bool? isLoading,
    String? error,
    List<RoomModel>? liveRooms,
    List<feed_user.User>? trendingUsers,
  }) {
    return FeedState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      liveRooms: liveRooms ?? this.liveRooms,
      trendingUsers: trendingUsers ?? this.trendingUsers,
    );
  }
}

class FeedController extends Notifier<FeedState> {
  late final FirebaseFirestore _firestore;
  late final FirebaseAuth _auth;
  late final ModerationService _moderationService;

  @override
  FeedState build() {
    _firestore = FirebaseFirestore.instance;
    _auth = FirebaseAuth.instance;
    _moderationService = ModerationService(firestore: _firestore, auth: _auth);
    return const FeedState();
  }

  Future<void> loadFeed() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final currentUserId = _auth.currentUser?.uid;
      final blockedIds = currentUserId == null
          ? const <String>{}
          : await _moderationService.getExcludedUserIds(currentUserId);
      final roomsSnap = await _firestore
          .collection('rooms')
          .where('isLive', isEqualTo: true)
          .orderBy('liveSince', descending: true)
          .limit(20)
          .get();
      final liveRooms = roomsSnap.docs
          .map((doc) => RoomModel.fromJson(doc.data(), doc.id))
          .where((room) => !blockedIds.contains(room.hostId))
          .toList();
      final usersSnap = await _firestore
          .collection('users')
          .orderBy('balance', descending: true)
          .limit(10)
          .get();
      final trendingUsers = usersSnap.docs
          .map((doc) => feed_user.User.fromJson({'id': doc.id, ...doc.data()}))
          .where((user) => !blockedIds.contains(user.id))
          .toList();
      state = state.copyWith(
        isLoading: false,
        liveRooms: liveRooms,
        trendingUsers: trendingUsers,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final feedControllerProvider = NotifierProvider<FeedController, FeedState>(
  () => FeedController(),
);
