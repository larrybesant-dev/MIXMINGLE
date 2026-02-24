import 'package:cloud_firestore/cloud_firestore.dart';

/// Room member presence model - represents a user's presence in a room
class RoomMember {
  final String userId;
  final String displayName;
  final String? photoURL;
  final bool online;
  final bool typing;
  final DateTime joinedAt;
  final DateTime? lastSeen;
  final String platform; // 'web', 'android', 'ios'
  final String role; // 'member', 'host', 'mod'

  RoomMember({
    required this.userId,
    required this.displayName,
    this.photoURL,
    required this.online,
    required this.typing,
    required this.joinedAt,
    this.lastSeen,
    required this.platform,
    required this.role,
  });

  /// Create from Firestore document snapshot
  factory RoomMember.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return RoomMember(
      userId: doc.id,
      displayName: data['displayName'] as String? ?? 'Unknown',
      photoURL: data['photoURL'] as String?,
      online: data['online'] as bool? ?? false,
      typing: data['typing'] as bool? ?? false,
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastSeen: (data['lastSeen'] as Timestamp?)?.toDate(),
      platform: data['platform'] as String? ?? 'unknown',
      role: data['role'] as String? ?? 'member',
    );
  }

  /// Convert to map for Firestore
  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'displayName': displayName,
        'photoURL': photoURL,
        'online': online,
        'typing': typing,
        'joinedAt': Timestamp.fromDate(joinedAt),
        'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
        'platform': platform,
        'role': role,
      };

  /// Get badge text (e.g., "Host", "Mod") or empty for regular member
  String getBadge() {
    switch (role) {
      case 'host':
        return 'ðŸ‘‘ Host';
      case 'mod':
        return 'ðŸ‘® Mod';
      default:
        return '';
    }
  }

  @override
  String toString() =>
      'RoomMember(userId: $userId, displayName: $displayName, online: $online)';
}
