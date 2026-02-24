import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/crashlytics/crashlytics_service.dart';

class HostModerationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AnalyticsService _analytics = AnalyticsService.instance;
  final CrashlyticsService _crashlytics = CrashlyticsService.instance;

  /// Kicks a user from a room
  ///
  /// [moderatorId] - The ID of the moderator performing the action
  /// [targetUserId] - The ID of the user being kicked
  /// [roomId] - The ID of the room
  Future<void> kickUser({
    required String moderatorId,
    required String targetUserId,
    required String roomId,
  }) async {
    try {
      // Remove user from room participants
      await _firestore.collection('rooms').doc(roomId).update({
        'participants': FieldValue.arrayRemove([targetUserId]),
        'kickedUsers': FieldValue.arrayUnion([targetUserId]),
      });

      await logAction(
        moderatorId: moderatorId,
        action: 'kick',
        targetUserId: targetUserId,
        roomId: roomId,
      );

      await _analytics.logHostActionTaken(
        action: 'kick',
        targetUserId: targetUserId,
        roomId: roomId,
      );
    } catch (e, stackTrace) {
      await _crashlytics.logModerationFailure(
        action: 'kick_user',
        error: e.toString(),
      );
      _crashlytics.recordError(e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Mutes a user in a room
  ///
  /// [moderatorId] - The ID of the moderator performing the action
  /// [targetUserId] - The ID of the user being muted
  /// [roomId] - The ID of the room
  Future<void> muteUser({
    required String moderatorId,
    required String targetUserId,
    required String roomId,
  }) async {
    try {
      // Add user to muted list in room
      await _firestore.collection('rooms').doc(roomId).update({
        'mutedUsers': FieldValue.arrayUnion([targetUserId]),
      });

      await logAction(
        moderatorId: moderatorId,
        action: 'mute',
        targetUserId: targetUserId,
        roomId: roomId,
      );

      await _analytics.logHostActionTaken(
        action: 'mute',
        targetUserId: targetUserId,
        roomId: roomId,
      );
    } catch (e, stackTrace) {
      await _crashlytics.logModerationFailure(
        action: 'mute_user',
        error: e.toString(),
      );
      _crashlytics.recordError(e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Unmutes a user in a room
  ///
  /// [moderatorId] - The ID of the moderator performing the action
  /// [targetUserId] - The ID of the user being unmuted
  /// [roomId] - The ID of the room
  Future<void> unmuteUser({
    required String moderatorId,
    required String targetUserId,
    required String roomId,
  }) async {
    try {
      await _firestore.collection('rooms').doc(roomId).update({
        'mutedUsers': FieldValue.arrayRemove([targetUserId]),
      });

      await logAction(
        moderatorId: moderatorId,
        action: 'unmute',
        targetUserId: targetUserId,
        roomId: roomId,
      );

      await _analytics.logHostActionTaken(
        action: 'unmute',
        targetUserId: targetUserId,
        roomId: roomId,
      );
    } catch (e, stackTrace) {
      await _crashlytics.logModerationFailure(
        action: 'unmute_user',
        error: e.toString(),
      );
      _crashlytics.recordError(e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Overrides spotlight to a specific user
  ///
  /// [moderatorId] - The ID of the moderator performing the action
  /// [targetUserId] - The ID of the user to spotlight
  /// [roomId] - The ID of the room
  Future<void> spotlightOverride({
    required String moderatorId,
    required String targetUserId,
    required String roomId,
  }) async {
    try {
      await _firestore.collection('rooms').doc(roomId).update({
        'spotlightUserId': targetUserId,
      });

      await logAction(
        moderatorId: moderatorId,
        action: 'spotlight_override',
        targetUserId: targetUserId,
        roomId: roomId,
      );

      await _analytics.logHostActionTaken(
        action: 'spotlight_override',
        targetUserId: targetUserId,
        roomId: roomId,
      );
    } catch (e, stackTrace) {
      await _crashlytics.logModerationFailure(
        action: 'spotlight_override',
        error: e.toString(),
      );
      _crashlytics.recordError(e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Removes spotlight from a user
  ///
  /// [moderatorId] - The ID of the moderator performing the action
  /// [targetUserId] - The ID of the user to remove from spotlight
  /// [roomId] - The ID of the room
  Future<void> removeSpotlight({
    required String moderatorId,
    required String targetUserId,
    required String roomId,
  }) async {
    try {
      await _firestore.collection('rooms').doc(roomId).update({
        'spotlightUserId': FieldValue.delete(),
      });

      await logAction(
        moderatorId: moderatorId,
        action: 'remove_spotlight',
        targetUserId: targetUserId,
        roomId: roomId,
      );

      await _analytics.logHostActionTaken(
        action: 'remove_spotlight',
        targetUserId: targetUserId,
        roomId: roomId,
      );
    } catch (e, stackTrace) {
      await _crashlytics.logModerationFailure(
        action: 'remove_spotlight',
        error: e.toString(),
      );
      _crashlytics.recordError(e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Warns a user in a room
  ///
  /// [moderatorId] - The ID of the moderator performing the action
  /// [targetUserId] - The ID of the user being warned
  /// [roomId] - The ID of the room
  /// [message] - Optional warning message
  Future<void> warnUser({
    required String moderatorId,
    required String targetUserId,
    required String roomId,
    String? message,
  }) async {
    try {
      await _firestore.collection('warnings').add({
        'moderatorId': moderatorId,
        'targetUserId': targetUserId,
        'roomId': roomId,
        'message': message ?? 'You have been warned by the host.',
        'timestamp': FieldValue.serverTimestamp(),
      });

      await logAction(
        moderatorId: moderatorId,
        action: 'warn',
        targetUserId: targetUserId,
        roomId: roomId,
      );

      await _analytics.logHostActionTaken(
        action: 'warn',
        targetUserId: targetUserId,
        roomId: roomId,
      );
    } catch (e, stackTrace) {
      await _crashlytics.logModerationFailure(
        action: 'warn_user',
        error: e.toString(),
      );
      _crashlytics.recordError(e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Logs a moderation action to Firestore
  ///
  /// [moderatorId] - The ID of the moderator performing the action
  /// [action] - The action performed (kick, mute, unmute, etc.)
  /// [targetUserId] - The ID of the user the action was performed on
  /// [roomId] - The ID of the room where the action occurred
  Future<void> logAction({
    required String moderatorId,
    required String action,
    required String targetUserId,
    required String roomId,
  }) async {
    await _firestore.collection('moderation_logs').add({
      'moderatorId': moderatorId,
      'action': action,
      'targetUserId': targetUserId,
      'roomId': roomId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
