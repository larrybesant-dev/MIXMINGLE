import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import '../models/room_model.dart';
import '../models/event_model.dart';

class FeedRepository {
  final FirebaseFirestore _db;

  FeedRepository(this._db);

  Stream<List<PostModel>> postsStream() {
    return _db
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => PostModel.fromDoc(d.id, d.data()))
            .toList());
  }

  Stream<List<RoomModel>> roomsStream() {
    return _db
        .collection('rooms')
        .where('active', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => RoomModel.fromDoc(d.id, d.data()))
            .toList());
  }

  Stream<List<EventModel>> eventsStream() {
    return _db
        .collection('events')
        .orderBy('date')
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => EventModel.fromDoc(d.id, d.data()))
            .toList());
  }
}
