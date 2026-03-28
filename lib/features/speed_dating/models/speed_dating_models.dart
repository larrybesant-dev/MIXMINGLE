import 'package:cloud_firestore/cloud_firestore.dart';

class SpeedDateCandidate {
  final String id;
  final String username;
  final String? avatarUrl;
  final String? bio;
  final List<String> interests;

  const SpeedDateCandidate({
    required this.id,
    required this.username,
    this.avatarUrl,
    this.bio,
    this.interests = const [],
  });

  factory SpeedDateCandidate.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    final username = (data['username'] as String?)?.trim();
    return SpeedDateCandidate(
      id: doc.id,
      username: (username == null || username.isEmpty) ? 'MixVy User' : username,
      avatarUrl: data['avatarUrl'] as String?,
      bio: data['bio'] as String?,
      interests: List<String>.from(data['interests'] ?? const []),
    );
  }
}

class SpeedDatingMatch {
  final String id;
  final List<String> participantIds;
  final Timestamp? createdAt;
  final String? latestRoomId;

  const SpeedDatingMatch({
    required this.id,
    required this.participantIds,
    this.createdAt,
    this.latestRoomId,
  });

  String otherUserId(String selfId) {
    return participantIds.firstWhere((id) => id != selfId, orElse: () => selfId);
  }

  factory SpeedDatingMatch.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return SpeedDatingMatch(
      id: doc.id,
      participantIds: List<String>.from(data['participantIds'] ?? const []),
      createdAt: data['createdAt'] as Timestamp?,
      latestRoomId: data['latestRoomId'] as String?,
    );
  }
}

class SpeedDateDecisionResult {
  final bool isMatch;
  final String? matchId;

  const SpeedDateDecisionResult({required this.isMatch, this.matchId});
}
