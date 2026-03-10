/// Centralized Firestore collection and document paths
///
/// Use these constants to ensure consistent path naming across the app.
class FirestorePaths {
  FirestorePaths._();

  // ========== Root Collections ==========
  static const String users = 'users';
  static const String rooms = 'rooms';
  static const String events = 'events';
  static const String messages = 'messages';
  static const String groupChats = 'group_chats';
  static const String matches = 'matches';
  static const String reports = 'reports';
  static const String blocks = 'blocks';
  static const String notifications = 'notifications';
  static const String withdrawalRequests = 'withdrawal_requests';

  // ========== User Subcollections ==========
  static String userMatches(String userId) => '$users/$userId/matches';
  static String userEventRsvps(String userId) => '$users/$userId/event_rsvps';
  static String userBlocked(String userId) => '$users/$userId/blocked';
  static String userNotifications(String userId) => '$users/$userId/notifications';
  static String userWithdrawals(String userId) => '$users/$userId/withdrawals';

  // ========== Event Subcollections ==========
  static String eventAttendees(String eventId) => '$events/$eventId/attendees';
  static String eventMessages(String eventId) => '$events/$eventId/messages';

  // ========== Room Subcollections ==========
  static String roomParticipants(String roomId) => '$rooms/$roomId/participants';
  static String roomMessages(String roomId) => '$rooms/$roomId/messages';
  static String roomBannedUsers(String roomId) => '$rooms/$roomId/banned_users';
  static String roomSpeakerQueue(String roomId) => '$rooms/$roomId/speaker_queue';

  // ========== Group Chat Subcollections ==========
  static String groupChatMessages(String groupId) => '$groupChats/$groupId/messages';
  static String groupChatMembers(String groupId) => '$groupChats/$groupId/members';

  // ========== Document References ==========
  static String userDoc(String userId) => '$users/$userId';
  static String roomDoc(String roomId) => '$rooms/$roomId';
  static String eventDoc(String eventId) => '$events/$eventId';
  static String messageDoc(String messageId) => '$messages/$messageId';
  static String groupChatDoc(String groupId) => '$groupChats/$groupId';
  static String matchDoc(String matchId) => '$matches/$matchId';
}


