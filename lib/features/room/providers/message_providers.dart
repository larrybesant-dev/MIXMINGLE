import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/message_model.dart';

import '../../../features/room/providers/participant_providers.dart';
import '../../../presentation/providers/user_provider.dart';

final messageStreamProvider = StreamProvider.family<List<MessageModel>, String>(
  (ref, roomId) {
    return FirebaseFirestore.instance
        .collection('rooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snap) => snap.docs.map((d) {
            final data = d.data();
            return MessageModel(
              id: d.id,
              senderId: data['userId'] ?? '',
              roomId: data['roomId'] ?? '',
              content: data['text'] ?? '',
              sentAt: (data['createdAt'] is Timestamp)
                  ? (data['createdAt'] as Timestamp).toDate()
                  : DateTime.tryParse(data['createdAt']?.toString() ?? '') ??
                        DateTime.now(),
            );
          }).toList(),
        );
  },
);

final sendMessageProvider =
    Provider.family<Future<void> Function(String text), String>((ref, roomId) {
      return (String text) async {
        final user = ref.read(userProvider);
        if (user == null) throw Exception('Not logged in');
        final participantAsync = await ref.read(
          currentParticipantProvider({
            'roomId': roomId,
            'userId': user.id,
          }).future,
        );
        if (participantAsync == null) throw Exception('Not a participant');
        if (participantAsync.isMuted) throw Exception('You are muted');
        if (participantAsync.isBanned) throw Exception('You are banned');
        await FirebaseFirestore.instance
            .collection('rooms')
            .doc(roomId)
            .collection('messages')
            .add({
              'text': text,
              'userId': user.id,
              'username': user.username,
              'avatarUrl': user.avatarUrl,
              'roomId': roomId,
              'createdAt': FieldValue.serverTimestamp(),
            });
      };
    });
