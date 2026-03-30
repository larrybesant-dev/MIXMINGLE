class RoomPermissions {
  static const String host = 'host';
  static const String cohost = 'cohost';
  static const String moderator = 'moderator';
  static const String stage = 'stage';
  static const String audience = 'audience';

  static bool isHost(String role) => role == host;
  static bool isModerator(String role) => role == moderator;
  static bool isStaff(String role) => role == host || role == moderator;

  static bool canUseMic(String role) {
    // Mic is open to all participants without host approval.
    return role.isNotEmpty;
  }

  static bool canUseCamera(String role) {
    // Anyone in the room can publish their own camera.
    return role.isNotEmpty;
  }

  static bool canManageParticipant({
    required String actorRole,
    required String actorUserId,
    required String targetRole,
    required String targetUserId,
    required String hostUserId,
  }) {
    if (actorUserId == targetUserId) {
      return false;
    }

    final targetIsHost = targetUserId == hostUserId || targetRole == host;
    if (targetIsHost) {
      return false;
    }

    if (isHost(actorRole)) {
      return true;
    }

    // Moderators can only manage audience/stage participants.
    if (isModerator(actorRole)) {
      return targetRole == audience || targetRole == stage;
    }

    return false;
  }

  static bool canTransferOwnership({
    required String actorRole,
    required String actorUserId,
    required String targetUserId,
    required String hostUserId,
  }) {
    return isHost(actorRole) && actorUserId == hostUserId && actorUserId != targetUserId;
  }
}
