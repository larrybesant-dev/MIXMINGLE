import 'package:cloud_firestore/cloud_firestore.dart';

class GroupChatParticipant {
  final String uid;
  final String username;
  final String? avatarUrl;
  final bool isMuted;
  final bool isCameraOn;
  final DateTime? joinedAt;

  const GroupChatParticipant({
    required this.uid,
    required this.username,
    this.avatarUrl,
    required this.isMuted,
    required this.isCameraOn,
    this.joinedAt,
  });

  factory GroupChatParticipant.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return GroupChatParticipant(
      uid: doc.id,
      username: data['username'] as String? ?? 'User',
      avatarUrl: data['avatarUrl'] as String?,
      isMuted: data['isMuted'] as bool? ?? false,
      isCameraOn: data['isCameraOn'] as bool? ?? true,
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'avatarUrl': avatarUrl,
      'isMuted': isMuted,
      'isCameraOn': isCameraOn,
      'joinedAt': joinedAt != null ? Timestamp.fromDate(joinedAt!) : FieldValue.serverTimestamp(),
    };
  }
}


