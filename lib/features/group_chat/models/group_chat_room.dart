import 'package:cloud_firestore/cloud_firestore.dart';

class GroupChatRoom {
  final String id;
  final String name;
  final String hostId;
  final bool isLive;
  final String agoraChannelId;
  final int activeCount;
  final DateTime? createdAt;

  const GroupChatRoom({
    required this.id,
    required this.name,
    required this.hostId,
    required this.isLive,
    required this.agoraChannelId,
    required this.activeCount,
    this.createdAt,
  });

  factory GroupChatRoom.fromDocument(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return GroupChatRoom(
      id: doc.id,
      name: data['name'] as String? ?? 'Room',
      hostId: data['hostId'] as String? ?? '',
      isLive: data['isLive'] as bool? ?? false,
      agoraChannelId: data['agoraChannelId'] as String? ?? doc.id,
      activeCount: (data['activeCount'] as num?)?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'hostId': hostId,
      'isLive': isLive,
      'agoraChannelId': agoraChannelId,
      'activeCount': activeCount,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}
