import 'controllers/room_state.dart';

class RoomPermissions {
  static const String host = roomRoleHost;
  static const String cohost = roomRoleCohost;
  static const String moderator = roomRoleModerator;
  static const String stage = roomRoleStage;
  static const String audience = roomRoleAudience;

  static bool isHost(String role) => isHostLikeRole(role);
  static bool isModerator(String role) =>
      normalizeRoomRole(role, fallbackRole: '') == moderator;
  static bool isStaff(String role) => canModerateRole(role);

  static bool canUseMic(String role) {
    return canUseMicRole(role);
  }

  static bool canUseCamera(String role) {
    return canUseCameraRole(role);
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
    return isHost(actorRole) &&
        actorUserId == hostUserId &&
        actorUserId != targetUserId;
  }
}
