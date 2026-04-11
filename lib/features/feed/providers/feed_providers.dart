import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mixvy/services/room_service.dart';
import 'package:mixvy/core/providers/firebase_providers.dart';

import '../repository/feed_repository.dart';
import '../models/post_model.dart';
import '../../../models/room_model.dart';
import '../../../models/user_model.dart';
import 'package:mixvy/models/models.dart';

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepository(ref.read(firestoreProvider));
});

final postsStreamProvider = StreamProvider<List<PostModel>>((ref) {
  return ref.read(feedRepositoryProvider).postsStream();
});

final userPostsStreamProvider =
    StreamProvider.family<List<PostModel>, String>((ref, userId) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('posts')
      .where('authorId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .limit(30)
      .snapshots()
      .map((snap) =>
          snap.docs.map((d) => PostModel.fromDoc(d.id, d.data())).toList());
});

final roomsStreamProvider = StreamProvider<List<RoomModel>>((ref) {
  return ref.read(roomServiceProvider).watchLiveRooms(limit: 50);
});

final eventsStreamProvider = StreamProvider<List<EventModel>>((ref) {
  return ref.read(feedRepositoryProvider).eventsStream();
});

/// Dashboard metrics do not need live Firestore listeners on every page load.
/// Fetch them once and refresh when the screen is re-entered or manually pulled.
final onlineUsersCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final snapshot = await ref
      .watch(firestoreProvider)
      .collection('presence')
      .where('isOnline', isEqualTo: true)
      .limit(501)
      .get();
  return snapshot.size;
});

final liveRoomsCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final rooms = await ref.read(roomServiceProvider).getLiveRooms(limit: 501);
  return rooms.length;
});

final newMembersStreamProvider = FutureProvider.autoDispose<List<UserModel>>((ref) async {
  final firestore = ref.watch(firestoreProvider);
  final snapshot = await firestore
      .collection('users')
      .orderBy('createdAt', descending: true)
      .limit(12)
      .get();
  return snapshot.docs.map((d) {
    final data = d.data();
    data['id'] = d.id;
    return UserModel.fromJson(data);
  }).toList(growable: false);
});

final trendingUsersStreamProvider =
    FutureProvider.autoDispose<List<UserModel>>((ref) async {
  final snapshot = await ref
      .watch(firestoreProvider)
      .collection('users')
      .orderBy('balance', descending: true)
      .limit(10)
      .get();
  return snapshot.docs
      .map((d) => UserModel.fromJson({'id': d.id, ...d.data()}))
      .toList(growable: false);
});
