import 'package:cloud_firestore/cloud_firestore.dart';

class MicQueueEntry {
  final String userId;
  final DateTime requestedAt;
  final bool granted;

  MicQueueEntry({
    required this.userId,
    required this.requestedAt,
    required this.granted,
  });

  factory MicQueueEntry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MicQueueEntry(
      userId: data['userId'] ?? '',
      requestedAt: (data['requestedAt'] as Timestamp).toDate(),
      granted: data['granted'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
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

  Future<void> requestMic(String userId) async {
    await micQueueRef.doc(userId).set({
      'userId': userId,
      'requestedAt': Timestamp.now(),
      'granted': false,
    });
  }

  Future<void> grantMic(String userId) async {
    await micQueueRef.doc(userId).update({'granted': true});
    await speakersRef.doc(userId).set({'userId': userId, 'active': true});
  }

  Future<void> revokeMic(String userId) async {
    await micQueueRef.doc(userId).update({'granted': false});
    await speakersRef.doc(userId).delete();
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
