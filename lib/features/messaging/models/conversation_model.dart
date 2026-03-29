import 'package:cloud_firestore/cloud_firestore.dart';

class Conversation {
  final String id;
  final String type; // 'direct' or 'group'
  final List<String> participantIds;
  final Map<String, String> participantNames; // {userId: username}
  final String? groupName;
  final String? groupAvatarUrl;
  final String? lastMessageId;
  final String? lastMessagePreview;
  final String? lastMessageSenderId;
  final DateTime? lastMessageAt;
  final DateTime createdAt;
  final Map<String, DateTime> lastReadAt; // {userId: lastReadTime}
  final bool isArchived;

  const Conversation({
    required this.id,
    required this.type,
    required this.participantIds,
    required this.participantNames,
    this.groupName,
    this.groupAvatarUrl,
    this.lastMessageId,
    this.lastMessagePreview,
    this.lastMessageSenderId,
    this.lastMessageAt,
    required this.createdAt,
    this.lastReadAt = const {},
    this.isArchived = false,
  });

  factory Conversation.fromJson(Map<String, dynamic> json, String docId) {
    return Conversation(
      id: docId,
      type: json['type'] as String? ?? 'direct',
      participantIds: List<String>.from((json['participantIds'] as List<dynamic>?) ?? []),
      participantNames: Map<String, String>.from((json['participantNames'] as Map<String, dynamic>?) ?? {}),
      groupName: json['groupName'] as String?,
      groupAvatarUrl: json['groupAvatarUrl'] as String?,
      lastMessageId: json['lastMessageId'] as String?,
      lastMessagePreview: json['lastMessagePreview'] as String?,
      lastMessageSenderId: json['lastMessageSenderId'] as String?,
      lastMessageAt: (json['lastMessageAt'] as Timestamp?)?.toDate(),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastReadAt: (json['lastReadAt'] as Map<String, dynamic>?)?.cast<String, DateTime>().map(
        (key, value) => MapEntry(key, (value as Timestamp).toDate()),
      ) ?? {},
      isArchived: json['isArchived'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'participantIds': participantIds,
      'participantNames': participantNames,
      'groupName': groupName,
      'groupAvatarUrl': groupAvatarUrl,
      'lastMessageId': lastMessageId,
      'lastMessagePreview': lastMessagePreview,
      'lastMessageSenderId': lastMessageSenderId,
      'lastMessageAt': lastMessageAt != null ? Timestamp.fromDate(lastMessageAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastReadAt': lastReadAt.map(
        (key, value) => MapEntry(key, Timestamp.fromDate(value)),
      ),
      'isArchived': isArchived,
    };
  }

  String getDisplayName(String? currentUserId) {
    if (type == 'group') return groupName ?? 'Group Chat';
    final otherUserId = participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
    return participantNames[otherUserId] ?? 'Unknown User';
  }

  bool hasUnreadMessages(String userId) {
    return lastMessageAt != null &&
        (lastReadAt[userId] == null || lastReadAt[userId]!.isBefore(lastMessageAt!));
  }
}
