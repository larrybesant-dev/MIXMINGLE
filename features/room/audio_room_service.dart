import 'package:cloud_firestore/cloud_firestore.dart';

class MicQueueEntry {
  final String uid;
  final DateTime requestedAt;
  final bool granted;

  MicQueueEntry({
    required this.uid,
    required this.requestedAt,
    required this.granted,
  });

  factory MicQueueEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MicQueueEntry(
      uid: data['uid'] ?? '',
      requestedAt: (data['requestedAt'] as Timestamp).toDate(),
      granted: data['granted'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'uid': uid,
    'requestedAt': Timestamp.fromDate(requestedAt),
    'granted': granted,
  };
}

class AudioRoomService {
  final CollectionReference micQueueRef;
  final CollectionReference speakersRef;

  AudioRoomService(String roomId)
      : micQueueRef = FirebaseFirestore.instance.collection('rooms').doc(roomId).collection('micQueue'),
        speakersRef = FirebaseFirestore.instance.collection('rooms').doc(roomId).collection('speakers');

  Future<void> requestMic(String uid) async {
    await micQueueRef.doc(uid).set({
      'uid': uid,
      'requestedAt': Timestamp.now(),
      'granted': false,
    });
  }

  Future<void> grantMic(String uid) async {
    await micQueueRef.doc(uid).update({'granted': true});
    await speakersRef.doc(uid).set({'uid': uid, 'active': true});
  }

  Future<void> revokeMic(String uid) async {
    await micQueueRef.doc(uid).update({'granted': false});
    await speakersRef.doc(uid).delete();
  }

  Future<List<MicQueueEntry>> getMicQueue() async {
    final snapshot = await micQueueRef.orderBy('requestedAt').get();
    return snapshot.docs.map((doc) => MicQueueEntry.fromFirestore(doc)).toList();
  }

  Future<List<String>> getActiveSpeakers() async {
    final snapshot = await speakersRef.where('active', isEqualTo: true).get();
    return snapshot.docs.map((doc) => doc['userId'] as String).toList();
  }
}
