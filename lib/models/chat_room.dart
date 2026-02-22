import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoom {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final DateTime lastMessageTime;
  final Map<String, int> unreadCounts;
  final bool isTyping;

  ChatRoom({
    required this.id,
    required this.participants,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCounts,
    this.isTyping = false,
  });

  factory ChatRoom.fromMap(Map<String, dynamic> map) {
    return ChatRoom(
      id: map['id'] as String,
      participants: (map['participants'] as List<dynamic>).cast<String>(),
      lastMessage: map['lastMessage'] as String,
      lastMessageTime: (map['lastMessageTime'] as Timestamp).toDate(),
      unreadCounts:
          (map['unreadCounts'] as Map<String, dynamic>).cast<String, int>(),
      isTyping: map['isTyping'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': Timestamp.fromDate(lastMessageTime),
      'unreadCounts': unreadCounts,
      'isTyping': isTyping,
    };
  }
}


