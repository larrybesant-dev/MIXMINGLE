import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/group_chat_message.dart';
import '../models/group_chat_participant.dart';
import '../models/group_chat_room.dart';

class GroupChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> get _rooms => _firestore.collection('rooms');

  Stream<GroupChatRoom?> watchRoom(String roomId) {
    return _rooms.doc(roomId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return GroupChatRoom.fromDocument(doc);
    });
  }

  Stream<List<GroupChatParticipant>> watchParticipants(String roomId) {
    return _rooms
        .doc(roomId)
        .collection('participants')
        .orderBy('joinedAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(GroupChatParticipant.fromDocument).toList());
  }

  Stream<List<GroupChatMessage>> watchMessages(String roomId) {
    return _rooms
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(GroupChatMessage.fromDocument).toList());
  }

  Future<GroupChatRoom> createRoom({
    required String roomId,
    required String name,
    required String hostId,
  }) async {
    final room = GroupChatRoom(
      id: roomId,
      name: name,
      hostId: hostId,
      isLive: true,
      agoraChannelId: roomId,
      activeCount: 1,
      createdAt: DateTime.now(),
    );

    await _rooms.doc(roomId).set(room.toMap(), SetOptions(merge: true));
    return room;
  }

  Future<void> joinRoom(String roomId, {required String username, String? avatarUrl}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('User must be signed in');
    }

    final participant = GroupChatParticipant(
      uid: user.uid,
      username: username,
      avatarUrl: avatarUrl,
      isMuted: false,
      isCameraOn: true,
      joinedAt: DateTime.now(),
    );

    await _firestore.runTransaction((txn) async {
      final roomRef = _rooms.doc(roomId);
      final roomSnap = await txn.get(roomRef);

      if (!roomSnap.exists) {
        txn.set(
            roomRef,
            {
              'name': roomId,
              'hostId': user.uid,
              'isLive': true,
              'agoraChannelId': roomId,
              'activeCount': 0,
              'createdAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true));
      }

      txn.set(
        roomRef.collection('participants').doc(user.uid),
        participant.toMap(),
        SetOptions(merge: true),
      );

      txn.update(roomRef, {
        'activeCount': FieldValue.increment(1),
        'isLive': true,
      });
    });
  }

  Future<void> leaveRoom(String roomId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('User must be signed in');
    }

    await _firestore.runTransaction((txn) async {
      final roomRef = _rooms.doc(roomId);
      final participantRef = roomRef.collection('participants').doc(user.uid);

      txn.delete(participantRef);

      final roomSnap = await txn.get(roomRef);
      final activeCount = (roomSnap.data()?['activeCount'] as num?)?.toInt() ?? 1;
      final nextCount = activeCount - 1;

      txn.set(
          roomRef,
          {
            'activeCount': nextCount.clamp(0, 1000000),
            'isLive': nextCount > 0,
          },
          SetOptions(merge: true));
    });
  }

  Future<void> sendTextMessage(String roomId, String text) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('User must be signed in');
    }

    // Get sender name from participant data
    final participantDoc = await _rooms.doc(roomId).collection('participants').doc(user.uid).get();
    final senderName =
        participantDoc.data()?['username'] as String? ?? user.displayName ?? user.email ?? 'Unknown User';

    final message = GroupChatMessage(
      id: _firestore.collection('noop').doc().id,
      senderId: user.uid,
      senderName: senderName,
      text: text,
      type: GroupChatMessageType.text,
      timestamp: DateTime.now(),
    );

    await _rooms.doc(roomId).collection('messages').doc(message.id).set(message.toMap());
  }

  Future<void> updateMediaState(String roomId, {bool? isMuted, bool? isCameraOn}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final updates = <String, dynamic>{};
    if (isMuted != null) updates['isMuted'] = isMuted;
    if (isCameraOn != null) updates['isCameraOn'] = isCameraOn;
    if (updates.isEmpty) return;

    await _rooms.doc(roomId).collection('participants').doc(user.uid).set(updates, SetOptions(merge: true));
  }
}


