import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mixvy/services/room_service.dart';

import '../repository/feed_repository.dart';
import '../models/post_model.dart';
import '../../../models/room_model.dart';
import 'package:mixvy/models/models.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

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
