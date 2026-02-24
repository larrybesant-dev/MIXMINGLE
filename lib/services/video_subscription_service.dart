import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../shared/models/room_video_state_model.dart';
import '../shared/models/participant.dart';
import '../shared/models/user_presence.dart';
import '../shared/models/publisher_state_model.dart';

typedef ParticipantsCallback = void Function(List<Participant>);
typedef VideoStateCallback = void Function(RoomVideoStateModel);
typedef PresenceCallback = void Function(List<UserPresence>);
typedef PublishersCallback = void Function(List<PublisherStateModel>);

class VideoSubscriptionService {
  final String roomId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<QuerySnapshot>? _participantsSubscription;
  StreamSubscription<DocumentSnapshot>? _videoStateSubscription;
  StreamSubscription<QuerySnapshot>? _presenceSubscription;
  StreamSubscription<QuerySnapshot>? _publishersSubscription;

  VideoSubscriptionService(this.roomId);

  // Subscribe to participants
  void subscribeToParticipants(ParticipantsCallback callback) {
    _participantsSubscription = _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('participants')
        .snapshots()
        .listen((snapshot) {
      final participants = snapshot.docs
          .map((doc) => Participant.fromJson(doc.data()))
          .toList();
      callback(participants);
    });
  }

  // Subscribe to video state
  void subscribeToVideoState(VideoStateCallback callback) {
    _videoStateSubscription = _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('videoState')
        .doc('current')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final state = RoomVideoStateModel.fromJson(snapshot.data()!);
        callback(state);
      }
    });
  }

  // Subscribe to presence
  void subscribeToPresence(PresenceCallback callback) {
    _presenceSubscription = _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('presence')
        .snapshots()
        .listen((snapshot) {
      final presence = snapshot.docs
          .map((doc) => UserPresence.fromJson(doc.data()))
          .toList();
      callback(presence);
    });
  }

  // Subscribe to publishers
  void subscribeToPublishers(PublishersCallback callback) {
    _publishersSubscription = _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('publishers')
        .snapshots()
        .listen((snapshot) {
      final publishers = snapshot.docs
          .map((doc) => PublisherStateModel.fromJson(doc.data()))
          .toList();
      callback(publishers);
    });
  }

  // Subscribe to all at once
  void subscribeToAll({
    ParticipantsCallback? onParticipants,
    VideoStateCallback? onVideoState,
    PresenceCallback? onPresence,
    PublishersCallback? onPublishers,
  }) {
    if (onParticipants != null) subscribeToParticipants(onParticipants);
    if (onVideoState != null) subscribeToVideoState(onVideoState);
    if (onPresence != null) subscribeToPresence(onPresence);
    if (onPublishers != null) subscribeToPublishers(onPublishers);
  }

  // Unsubscribe from all
  void unsubscribe() {
    _participantsSubscription?.cancel();
    _videoStateSubscription?.cancel();
    _presenceSubscription?.cancel();
    _publishersSubscription?.cancel();
  }

  // Dispose
  void dispose() {
    unsubscribe();
  }
}


