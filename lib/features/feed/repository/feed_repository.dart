import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import '../../../models/room_model.dart';
import 'package:mixvy/models/models.dart';
import 'package:mixvy/core/firestore/firestore_error_utils.dart';

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
            .toList())
        .handleError((error, stackTrace) {
          logFirestoreError(
            context: 'dashboard.posts listener',
            error: error,
            stackTrace: stackTrace,
          );
        });
  }

  Stream<List<RoomModel>> roomsStream() {
    return _db
      .collection('rooms')
      .where('active', isEqualTo: true)
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((snap) => snap.docs
        .map((d) => RoomModel.fromJson(d.data(), d.id))
        .toList())
      .handleError((error, stackTrace) {
        logFirestoreError(
          context: 'dashboard.rooms listener',
          error: error,
          stackTrace: stackTrace,
        );
      });
  }

  Stream<List<EventModel>> eventsStream() {
    return _db
        .collection('events')
        .orderBy('date')
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => EventModel.fromDoc(d.id, d.data()))
            .toList())
        .handleError((error, stackTrace) {
          logFirestoreError(
            context: 'dashboard.events listener',
            error: error,
            stackTrace: stackTrace,
          );
        });
  }
}
