
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/room_model.dart';
import '../../../models/user.dart';

class FeedState {
  final bool isLoading;
  final String? error;
  final List<RoomModel> liveRooms;
  final List<User> trendingUsers;

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
    List<User>? trendingUsers,
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

  @override
  FeedState build() {
    _firestore = FirebaseFirestore.instance;
    return const FeedState();
  }

  Future<void> loadFeed() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final roomsSnap = await _firestore
          .collection('rooms')
          .where('isLive', isEqualTo: true)
          .orderBy('liveSince', descending: true)
          .limit(20)
          .get();
      final liveRooms = roomsSnap.docs
        .map((doc) => RoomModel.fromJson(doc.data(), doc.id))
        .toList();
      final usersSnap = await _firestore
          .collection('users')
          .orderBy('balance', descending: true)
          .limit(10)
          .get();
      final trendingUsers = usersSnap.docs
          .map((doc) => User.fromJson({'id': doc.id, ...doc.data()}))
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
