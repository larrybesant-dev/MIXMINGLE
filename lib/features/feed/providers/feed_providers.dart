import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../repository/feed_repository.dart';
import '../models/post_model.dart';
import '../models/room_model.dart';
import '../../models/models.dart';

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepository(ref.read(firestoreProvider));
});

final postsStreamProvider = StreamProvider<List<PostModel>>((ref) {
  return ref.read(feedRepositoryProvider).postsStream();
});

final roomsStreamProvider = StreamProvider<List<RoomModel>>((ref) {
  return ref.read(feedRepositoryProvider).roomsStream();
});

final eventsStreamProvider = StreamProvider<List<EventModel>>((ref) {
  return ref.read(feedRepositoryProvider).eventsStream();
});
