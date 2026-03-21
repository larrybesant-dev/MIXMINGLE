import 'package:cloud_firestore/cloud_firestore.dart';
export 'event_model.dart';

class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;
  final String? bio;
  final List<String> interests;
  final GeoPoint? location;
  final DateTime createdAt;

  UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
    this.bio,
    this.interests = const [],
    this.location,
    required this.createdAt,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      photoUrl: data['photoUrl'],
      bio: data['bio'],
      interests: List<String>.from(data['interests'] ?? []),
      location: data['location'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'bio': bio,
      'interests': interests,
      'location': location,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class MixEvent {
  final String id;
  final String title;
  final String creatorId;
  final DateTime startTime;
  final List<String> participants;

  MixEvent({
    required this.id,
    required this.title,
    required this.creatorId,
    required this.startTime,
    this.participants = const [],
  });

  factory MixEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MixEvent(
      id: doc.id,
      title: data['title'] ?? '',
      creatorId: data['creatorId'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      participants: List<String>.from(data['participants'] ?? []),
    );
  }
}
