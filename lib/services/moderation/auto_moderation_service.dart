import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../shared/models/moderation_action.dart';
import '../../shared/models/chat_message.dart';

class AutoModerationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Auto-moderation rules
  static const int _maxMessagesPerMinute = 10;
  static const int _spamThreshold = 3; // Same message repeated
  static const List<String> _bannedWords = [
    // Add your banned words here
    'spam',
    'scam',
  ];

  final Map<String, List<DateTime>> _userMessageTimes = {};
  final Map<String, List<String>> _recentMessages = {};

  /// Check if a message should be auto-moderated
  Future<AutoModerationResult> checkMessage(
      ChatMessage message, String roomId) async {
    try {
      // 1. Check for spam (too many messages)
      if (_isSpamming(message.senderId)) {
        return AutoModerationResult(
          shouldBlock: true,
          action: ModerationType.timeout,
          reason: 'Spam detected: Too many messages',
          duration: BanDuration.fiveMinutes,
        );
      }

      // 2. Check for repeated messages
      if (_isRepeating(message.senderId, message.content)) {
        return AutoModerationResult(
          shouldBlock: true,
          action: ModerationType.timeout,
          reason: 'Repeated messages detected',
          duration: BanDuration.fiveMinutes,
        );
      }

      // 3. Check for banned words
      final bannedWord = _containsBannedWords(message.content);
      if (bannedWord != null) {
        return AutoModerationResult(
          shouldBlock: true,
          action: ModerationType.warn,
          reason: 'Inappropriate content: $bannedWord',
        );
      }

      // 4. Check for ALL CAPS (shouting)
      if (_isAllCaps(message.content)) {
        return AutoModerationResult(
          shouldBlock: false,
          action: ModerationType.warn,
          reason: 'Please avoid using all caps',
        );
      }

      return AutoModerationResult(shouldBlock: false);
    } catch (e) {
      debugPrint('Auto-moderation check failed: $e');
      return AutoModerationResult(shouldBlock: false);
    }
  }

  /// Apply auto-moderation action
  Future<void> applyAutoModeration({
    required String roomId,
    required String userId,
    required String userName,
    required ModerationType action,
    required String reason,
    BanDuration? duration,
  }) async {
    try {
      final moderationAction = ModerationAction(
        id: '',
        roomId: roomId,
        type: action,
        targetUserId: userId,
        targetUserName: userName,
        moderatorId: 'system',
        moderatorName: 'Auto-Moderator',
        reason: reason,
        timestamp: DateTime.now(),
        expiresAt:
            duration != null ? ModerationAction.getExpiryTime(duration) : null,
        isAutoModerated: true,
      );

      await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('moderation_logs')
          .add(moderationAction.toFirestore());

      // Apply the action
      switch (action) {
        case ModerationType.timeout:
          // âœ… SAFETY FIX: Check duration before applying timeout
          if (duration != null) {
            await _applyTimeout(roomId, userId, duration);
          } else {
            debugPrint(
                'âš ï¸ Timeout action requires duration, but duration is null');
          }
          break;
        case ModerationType.ban:
        case ModerationType.tempBan:
          await _applyBan(roomId, userId, duration);
          break;
        case ModerationType.shadowBan:
          await _applyShadowBan(userId);
          break;
        default:
          break;
      }
    } catch (e) {
      debugPrint('Failed to apply auto-moderation: $e');
    }
  }

  bool _isSpamming(String userId) {
    final now = DateTime.now();
    _userMessageTimes[userId] ??= [];

    // Remove old timestamps (older than 1 minute)
    _userMessageTimes[userId]!.removeWhere(
      (time) => now.difference(time).inMinutes >= 1,
    );

    // Add current timestamp
    _userMessageTimes[userId]!.add(now);

    return _userMessageTimes[userId]!.length > _maxMessagesPerMinute;
  }

  bool _isRepeating(String userId, String content) {
    _recentMessages[userId] ??= [];

    // Keep only last 10 messages
    if (_recentMessages[userId]!.length >= 10) {
      _recentMessages[userId]!.removeAt(0);
    }

    // Check for repeated content
    final repeats =
        _recentMessages[userId]!.where((msg) => msg == content).length;
    _recentMessages[userId]!.add(content);

    return repeats >= _spamThreshold;
  }

  String? _containsBannedWords(String content) {
    final lowerContent = content.toLowerCase();
    for (final word in _bannedWords) {
      if (lowerContent.contains(word)) {
        return word;
      }
    }
    return null;
  }

  bool _isAllCaps(String content) {
    if (content.length < 10) return false; // Ignore short messages
    final letters = content.replaceAll(RegExp(r'[^a-zA-Z]'), '');
    if (letters.isEmpty) return false;
    return letters == letters.toUpperCase();
  }

  Future<void> _applyTimeout(
      String roomId, String userId, BanDuration duration) async {
    final expiresAt = ModerationAction.getExpiryTime(duration);
    await _firestore.collection('rooms').doc(roomId).update({
      'timedOutUsers.$userId': Timestamp.fromDate(expiresAt),
    });
  }

  Future<void> _applyBan(
      String roomId, String userId, BanDuration? duration) async {
    final roomRef = _firestore.collection('rooms').doc(roomId);
    await roomRef.update({
      'bannedUsers': FieldValue.arrayUnion([userId]),
    });

    if (duration != null && duration != BanDuration.permanent) {
      final expiresAt = ModerationAction.getExpiryTime(duration);
      await roomRef.update({
        'tempBans.$userId': Timestamp.fromDate(expiresAt),
      });
    }
  }

  Future<void> _applyShadowBan(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'isShadowBanned': true,
      'shadowBannedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Clean up expired bans and timeouts
  Future<void> cleanupExpiredActions(String roomId) async {
    try {
      final roomDoc = await _firestore.collection('rooms').doc(roomId).get();
      final data = roomDoc.data();
      if (data == null) return;

      final now = DateTime.now();
      final updates = <String, dynamic>{};

      // Clean up timed out users
      final timedOutUsers = data['timedOutUsers'] as Map<String, dynamic>?;
      if (timedOutUsers != null) {
        for (final entry in timedOutUsers.entries) {
          final expiresAt = (entry.value as Timestamp).toDate();
          if (now.isAfter(expiresAt)) {
            updates['timedOutUsers.${entry.key}'] = FieldValue.delete();
          }
        }
      }

      // Clean up temp bans
      final tempBans = data['tempBans'] as Map<String, dynamic>?;
      if (tempBans != null) {
        for (final entry in tempBans.entries) {
          final expiresAt = (entry.value as Timestamp).toDate();
          if (now.isAfter(expiresAt)) {
            updates['tempBans.${entry.key}'] = FieldValue.delete();
            updates['bannedUsers'] = FieldValue.arrayRemove([entry.key]);
          }
        }
      }

      if (updates.isNotEmpty) {
        await _firestore.collection('rooms').doc(roomId).update(updates);
      }
    } catch (e) {
      debugPrint('Failed to cleanup expired actions: $e');
    }
  }
}

class AutoModerationResult {
  final bool shouldBlock;
  final ModerationType? action;
  final String? reason;
  final BanDuration? duration;

  AutoModerationResult({
    required this.shouldBlock,
    this.action,
    this.reason,
    this.duration,
  });
}
