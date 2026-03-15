import 'package:cloud_firestore/cloud_firestore.dart';

class Room {
  final String id;
  final String title;
  final String hostId;
  final String category;
  final String mood;
  final String musicType;
  final List<String> vibeTags;
  final bool isPrivate;
  final Timestamp createdAt;
  final int activeUserCount;

  Room({
    required this.id,
    required this.title,
    required this.hostId,
    required this.category,
    required this.mood,
    required this.musicType,
    required this.vibeTags,
    required this.isPrivate,
    required this.createdAt,
    required this.activeUserCount,
  });

  factory Room.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Room(
      id: doc.id,
      title: data['title'] ?? '',
      hostId: data['hostId'] ?? '',
      category: data['category'] ?? '',
      mood: data['mood'] ?? 'Chill',
      musicType: data['musicType'] ?? 'R&B',
      vibeTags: List<String>.from(data['vibeTags'] ?? []),
      isPrivate: data['isPrivate'] ?? false,
      createdAt: data['createdAt'] ?? Timestamp.now(),
      activeUserCount: data['activeUserCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'hostId': hostId,
      'category': category,
      'mood': mood,
      'musicType': musicType,
      'vibeTags': vibeTags,
      'isPrivate': isPrivate,
      'createdAt': createdAt,
      'activeUserCount': activeUserCount,
    };
  }
}
