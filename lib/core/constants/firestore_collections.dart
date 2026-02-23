/// Centralized Firestore collection and field names
/// Single source of truth for database schema
///
/// Usage:
/// ```dart
/// await _firestore
///   .collection(FirestoreCollections.users)
///   .doc(userId)
///   .set({FirestoreCollections.displayName: 'John'});
/// ```
library;

abstract class FirestoreCollections {
  // ========================================
  // COLLECTION NAMES
  // ========================================

  /// Users collection: stores user profile data
  static const String users = 'users';

  /// Rooms collection: stores video chat rooms
  static const String rooms = 'rooms';

  /// Messages collection: global message log (optional)
  static const String messages = 'messages';

  /// Notifications queue: system notifications
  static const String notificationsQueue = 'notifications_queue';

  /// Config collection: app-wide configuration
  static const String config = 'config';

  // ========================================
  // USER DOCUMENT FIELDS
  // ========================================

  /// User's display name (string, required, indexed)
  static const String displayName = 'displayName';

  /// User's email address (string, required, indexed)
  static const String email = 'email';

  /// User's profile photo URL (string, optional)
  static const String photoURL = 'photoURL';

  /// User's bio/description (string, optional, max 500 chars)
  static const String bio = 'bio';

  /// Account creation timestamp (Timestamp, required)
  static const String createdAt = 'createdAt';

  /// Last profile update timestamp (Timestamp, required)
  static const String updatedAt = 'updatedAt';

  /// Whether user is currently online (boolean, computed)
  static const String isOnline = 'isOnline';

  /// User's blocked list sub-collection
  static const String blocked = 'blocked';

  // ========================================
  // ROOM DOCUMENT FIELDS
  // ========================================

  /// Room host's user ID (string, required, indexed)
  static const String hostId = 'hostId';

  /// Room title/name (string, required)
  static const String title = 'title';

  /// Room description (string, optional)
  static const String description = 'description';

  /// Room creation timestamp (Timestamp, required)
  static const String roomCreatedAt = 'createdAt';

  /// Whether room is currently active (boolean, required, indexed)
  static const String isActive = 'isActive';

  /// Current participant count (int, computed)
  static const String participantCount = 'participantCount';

  /// Max allowed participants (int, default 100)
  static const String maxParticipants = 'maxParticipants';

  /// Room tags/categories (array, optional)
  static const String tags = 'tags';

  /// Participants sub-collection
  static const String participants = 'participants';

  /// Room messages sub-collection
  static const String roomMessages = 'messages';

  // ========================================
  // PARTICIPANT DOCUMENT FIELDS
  // ========================================

  /// Participant join time (Timestamp, required)
  static const String joinedAt = 'joinedAt';

  /// Participant's display name cached at join time (string)
  static const String participantDisplayName = 'displayName';

  /// Participant's photo URL cached at join time (string)
  static const String participantPhotoUrl = 'photoUrl';

  /// Agora UID assigned to this participant (int)
  static const String agoraUid = 'agoraUid';

  /// Whether participant is muted (boolean)
  static const String isMuted = 'isMuted';

  /// Whether participant video is off (boolean)
  static const String isVideoMuted = 'isVideoMuted';

  /// Whether participant is a speaker/broadcaster (boolean)
  static const String isBroadcaster = 'isBroadcaster';

  // ========================================
  // MESSAGE DOCUMENT FIELDS
  // ========================================

  /// Message sender's user ID (string, required)
  static const String senderId = 'senderId';

  /// Message content text (string, required)
  static const String content = 'content';

  /// Message creation timestamp (Timestamp, required)
  static const String messageCreatedAt = 'createdAt';

  /// Message reactions map: {emoji: count}
  static const String reactions = 'reactions';

  /// Whether message is deleted (boolean)
  static const String isDeleted = 'isDeleted';

  // ========================================
  // NOTIFICATION FIELDS
  // ========================================

  /// Recipient user ID (string, required)
  static const String recipientId = 'recipientId';

  /// Notification type: 'user_joined', 'user_left', etc.
  static const String notificationType = 'type';

  /// Notification payload/data
  static const String payload = 'payload';

  /// Whether notification is read (boolean)
  static const String isRead = 'isRead';

  // ========================================
  // CONFIG FIELDS
  // ========================================

  /// Agora app ID (stored in config/agora)
  static const String appId = 'appId';

  /// Feature flags (stored in config/features)
  static const String featureFlags = 'featureFlags';

  // ========================================
  // HELPER METHODS
  // ========================================

  /// Get full path to a user's blocked list sub-collection
  static String blockedListPath(String userId) {
    return '$users/$userId/$blocked';
  }

  /// Get full path to a room's participants sub-collection
  static String roomParticipantsPath(String roomId) {
    return '$rooms/$roomId/$participants';
  }

  /// Get full path to a room's messages sub-collection
  static String roomMessagesPath(String roomId) {
    return '$rooms/$roomId/$roomMessages';
  }

  /// Get full path to a specific participant document
  static String participantDocPath(String roomId, String userId) {
    return '$rooms/$roomId/$participants/$userId';
  }

  /// Get full path to a specific message document
  static String messageDocPath(String roomId, String messageId) {
    return '$rooms/$roomId/$roomMessages/$messageId';
  }
}


