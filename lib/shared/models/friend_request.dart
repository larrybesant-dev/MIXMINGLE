// lib/shared/models/friend_request.dart
//
// Firestore schema:
//   /users/{uid}/friendRequests/{requestId}
//     requestId, senderId, receiverId, status, timestamp,
//     senderName, senderAvatarUrl, receiverName
//
//   /users/{uid}/friends/{friendUid}
//     since: Timestamp
//     displayName, avatarUrl (denormalised snapshot)
//
//   Top-level convenience collection:
//   /friendRequests/{requestId}   (same fields — enables cross-user queries)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';

// ── Status ────────────────────────────────────────────────────────────────────
enum FriendRequestStatus { pending, accepted, declined, cancelled }

// ── FriendRequest model ───────────────────────────────────────────────────────
class FriendRequest {
  final String requestId;
  final String senderId;
  final String receiverId;
  final FriendRequestStatus status;
  final DateTime timestamp;

  // Denormalised sender snapshot (convenience for list UIs)
  final String? senderName;
  final String? senderAvatarUrl;
  final String? receiverName;
  final String? receiverAvatarUrl;

  const FriendRequest({
    required this.requestId,
    required this.senderId,
    required this.receiverId,
    required this.status,
    required this.timestamp,
    this.senderName,
    this.senderAvatarUrl,
    this.receiverName,
    this.receiverAvatarUrl,
  });

  // ── Factories ─────────────────────────────────────────────────────────────
  factory FriendRequest.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return FriendRequest.fromMap(data, doc.id);
  }

  factory FriendRequest.fromMap(Map<String, dynamic> data, String id) {
    return FriendRequest(
      requestId: id,
      senderId: data['senderId'] as String? ?? '',
      receiverId: data['receiverId'] as String? ?? '',
      status: FriendRequestStatus.values.firstWhere(
        (e) => e.name == (data['status'] as String? ?? 'pending'),
        orElse: () => FriendRequestStatus.pending,
      ),
      timestamp: data['timestamp'] is Timestamp
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      senderName: data['senderName'] as String?,
      senderAvatarUrl: data['senderAvatarUrl'] as String?,
      receiverName: data['receiverName'] as String?,
      receiverAvatarUrl: data['receiverAvatarUrl'] as String?,
    );
  }

  // ── Serialisation ─────────────────────────────────────────────────────────
  Map<String, dynamic> toMap() => {
        'requestId': requestId,
        'senderId': senderId,
        'receiverId': receiverId,
        'status': status.name,
        'timestamp': Timestamp.fromDate(timestamp),
        if (senderName != null) 'senderName': senderName,
        if (senderAvatarUrl != null) 'senderAvatarUrl': senderAvatarUrl,
        if (receiverName != null) 'receiverName': receiverName,
        if (receiverAvatarUrl != null) 'receiverAvatarUrl': receiverAvatarUrl,
      };

  FriendRequest copyWith({FriendRequestStatus? status}) => FriendRequest(
        requestId: requestId,
        senderId: senderId,
        receiverId: receiverId,
        status: status ?? this.status,
        timestamp: timestamp,
        senderName: senderName,
        senderAvatarUrl: senderAvatarUrl,
        receiverName: receiverName,
        receiverAvatarUrl: receiverAvatarUrl,
      );
}

// ── Friend model (entry in /users/{uid}/friends) ──────────────────────────────
class FriendEntry {
  final String uid;
  final DateTime since;
  final String? displayName;
  final String? avatarUrl;

  const FriendEntry({
    required this.uid,
    required this.since,
    this.displayName,
    this.avatarUrl,
  });

  factory FriendEntry.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return FriendEntry(
      uid: doc.id,
      since: data['since'] is Timestamp
          ? (data['since'] as Timestamp).toDate()
          : DateTime.now(),
      displayName: data['displayName'] as String?,
      avatarUrl: data['avatarUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'since': Timestamp.fromDate(since),
        if (displayName != null) 'displayName': displayName,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
      };
}
