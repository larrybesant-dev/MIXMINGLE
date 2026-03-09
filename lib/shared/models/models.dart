import 'package:flutter/foundation.dart';

class AppUser {
  final String uid;
  final String username;
  final String? email;
  final String? photoUrl;
  final DateTime createdAt;
  final bool ageVerified;
  final bool onboardingComplete;
  final String? bio;
  final String? location;

  AppUser({
    required this.uid,
    required this.username,
    this.email,
    this.photoUrl,
    required this.createdAt,
    this.ageVerified = false,
    this.onboardingComplete = false,
    this.bio,
    this.location,
  });
}

class MicQueueEntry {
  final String id;
  final String userId;
  final String username;
  final bool isMuted;

  MicQueueEntry({
    required this.id,
    required this.userId,
    required this.username,
    this.isMuted = false,
  });
}

class Room {
  final String id;
  final String name;
  final String hostId;
  final DateTime createdAt;

  Room({
    required this.id,
    required this.name,
    required this.hostId,
    required this.createdAt,
  });
}

class NotificationItem {
  final String id;
  final String type;
  final String senderId;
  final String? message;
  final DateTime timestamp;
  final bool read;

  NotificationItem({
    required this.id,
    required this.type,
    required this.senderId,
    this.message,
    required this.timestamp,
    this.read = false,
  });
}
