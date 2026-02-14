/// Share Service
///
/// Handles sharing functionality for spotlight clips, room invites,
/// and multi-cam screenshots using native share APIs.
library;

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/analytics/analytics_service.dart';

/// Service for sharing content from Mix & Mingle
class ShareService {
  static ShareService? _instance;
  static ShareService get instance => _instance ??= ShareService._();

  ShareService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AnalyticsService _analytics = AnalyticsService.instance;

  // Base URLs
  static const String _baseUrl = 'https://mixmingle.app';
  // ignore: unused_field
  static const String _dynamicLinkDomain = 'mixmingle.page.link'; // Reserved for Firebase Dynamic Links

  // ============================================================
  // ROOM SHARING
  // ============================================================

  /// Share a room invite link
  Future<ShareResult> shareRoomInviteLink(
    String roomId,
    String roomTitle, {
    String? hostName,
    String? shareText,
  }) async {
    try {
      // Generate room link
      final roomLink = '$_baseUrl/r/$roomId';

      // Create share text
      final text = shareText ??
          (hostName != null
              ? 'Join me in "$roomTitle" hosted by $hostName! $roomLink'
              : 'Join me in "$roomTitle"! $roomLink');

      // Track analytics
      await _analytics.logEvent(
        name: 'room_invite_shared',
        parameters: {
          'room_id': roomId,
          'room_title': roomTitle,
        },
      );

      // Increment share count
      await _firestore.collection('rooms').doc(roomId).update({
        'shareCount': FieldValue.increment(1),
        'lastSharedAt': FieldValue.serverTimestamp(),
      });

      // Share using share_plus
      final result = await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: 'Join me on Mix & Mingle!',
        ),
      );

      return ShareResult(
        success: true,
        link: roomLink,
        shareStatus: result.status,
      );
    } catch (e) {
      debugPrint('❌ [Share] Failed to share room: $e');
      return ShareResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Get a room invite link without sharing
  String getRoomInviteLink(String roomId) {
    return '$_baseUrl/r/$roomId';
  }

  // ============================================================
  // SPOTLIGHT CLIP SHARING
  // ============================================================

  /// Share a spotlight clip
  Future<ShareResult> shareSpotlightClip(
    String clipId,
    String clipTitle, {
    String? creatorName,
    String? thumbnailUrl,
  }) async {
    try {
      // Generate clip link
      final clipLink = '$_baseUrl/clip/$clipId';

      // Create share text
      String text;
      if (creatorName != null) {
        text = 'Check out this spotlight from $creatorName: "$clipTitle" $clipLink';
      } else {
        text = 'Check out this spotlight: "$clipTitle" $clipLink';
      }

      // Track analytics
      await _analytics.logEvent(
        name: 'spotlight_clip_shared',
        parameters: {
          'clip_id': clipId,
          'clip_title': clipTitle,
        },
      );

      // Increment share count
      await _firestore.collection('spotlight_clips').doc(clipId).update({
        'shareCount': FieldValue.increment(1),
        'lastSharedAt': FieldValue.serverTimestamp(),
      });

      // Share
      final result = await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: 'Check this out on Mix & Mingle!',
        ),
      );

      return ShareResult(
        success: true,
        link: clipLink,
        shareStatus: result.status,
      );
    } catch (e) {
      debugPrint('❌ [Share] Failed to share clip: $e');
      return ShareResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Share spotlight clip with file (if available)
  Future<ShareResult> shareSpotlightClipWithMedia(
    String clipId,
    String clipTitle,
    String mediaPath, {
    String? creatorName,
  }) async {
    try {
      final clipLink = '$_baseUrl/clip/$clipId';

      String text;
      if (creatorName != null) {
        text = 'Check out this spotlight from $creatorName! $clipLink';
      } else {
        text = 'Check out this spotlight! $clipLink';
      }

      // Track analytics
      await _analytics.logEvent(
        name: 'spotlight_clip_shared_with_media',
        parameters: {
          'clip_id': clipId,
          'clip_title': clipTitle,
        },
      );

      // Share with file
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [XFile(mediaPath)],
          text: text,
          subject: 'Check this out on Mix & Mingle!',
        ),
      );

      return ShareResult(
        success: true,
        link: clipLink,
        shareStatus: result.status,
      );
    } catch (e) {
      debugPrint('❌ [Share] Failed to share clip with media: $e');
      return ShareResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  // ============================================================
  // MULTI-CAM SCREENSHOT SHARING
  // ============================================================

  /// Share a multi-cam screenshot
  Future<ShareResult> shareMultiCamScreenshot(
    String screenshotPath, {
    String? roomId,
    String? roomTitle,
    List<String>? participantNames,
  }) async {
    try {
      String text = 'Having a great time on Mix & Mingle!';

      if (roomTitle != null) {
        text = 'Live in "$roomTitle" on Mix & Mingle!';
      }

      if (participantNames != null && participantNames.isNotEmpty) {
        final names = participantNames.take(3).join(', ');
        if (participantNames.length > 3) {
          text += ' with $names and ${participantNames.length - 3} others';
        } else {
          text += ' with $names';
        }
      }

      // Add app link
      text += '\n\nJoin us: $_baseUrl';

      // Track analytics
      await _analytics.logEvent(
        name: 'multicam_screenshot_shared',
        parameters: {
          'room_id': roomId ?? 'unknown',
          'participant_count': participantNames?.length ?? 0,
        },
      );

      // Share with file
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [XFile(screenshotPath)],
          text: text,
          subject: 'Mix & Mingle Moment',
        ),
      );

      return ShareResult(
        success: true,
        shareStatus: result.status,
      );
    } catch (e) {
      debugPrint('❌ [Share] Failed to share screenshot: $e');
      return ShareResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  // ============================================================
  // PROFILE SHARING
  // ============================================================

  /// Share a user profile
  Future<ShareResult> shareProfile(
    String userId,
    String displayName, {
    String? bio,
  }) async {
    try {
      final profileLink = '$_baseUrl/u/$userId';

      final text = bio != null
          ? 'Check out $displayName on Mix & Mingle: "$bio" $profileLink'
          : 'Connect with $displayName on Mix & Mingle! $profileLink';

      await _analytics.logEvent(
        name: 'profile_shared',
        parameters: {'user_id': userId},
      );

      final result = await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: 'Meet $displayName on Mix & Mingle',
        ),
      );

      return ShareResult(
        success: true,
        link: profileLink,
        shareStatus: result.status,
      );
    } catch (e) {
      debugPrint('❌ [Share] Failed to share profile: $e');
      return ShareResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  // ============================================================
  // EVENT SHARING
  // ============================================================

  /// Share an event
  Future<ShareResult> shareEvent(
    String eventId,
    String eventTitle, {
    DateTime? eventTime,
    String? hostName,
  }) async {
    try {
      final eventLink = '$_baseUrl/e/$eventId';

      String text = 'Join me at "$eventTitle" on Mix & Mingle!';

      if (eventTime != null) {
        final timeStr = _formatEventTime(eventTime);
        text = 'Join me at "$eventTitle" on $timeStr!';
      }

      if (hostName != null) {
        text += ' Hosted by $hostName.';
      }

      text += ' $eventLink';

      await _analytics.logEvent(
        name: 'event_shared',
        parameters: {
          'event_id': eventId,
          'event_title': eventTitle,
        },
      );

      final result = await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: 'Join this Mix & Mingle event!',
        ),
      );

      return ShareResult(
        success: true,
        link: eventLink,
        shareStatus: result.status,
      );
    } catch (e) {
      debugPrint('❌ [Share] Failed to share event: $e');
      return ShareResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  // ============================================================
  // REFERRAL SHARING
  // ============================================================

  /// Share referral code
  Future<ShareResult> shareReferralCode(
    String referralCode, {
    String? userName,
  }) async {
    try {
      final referralLink = '$_baseUrl/ref/$referralCode';

      String text;
      if (userName != null) {
        text = '$userName invites you to Mix & Mingle! '
            'Use code $referralCode for bonus coins. '
            '$referralLink';
      } else {
        text = 'Join me on Mix & Mingle! '
            'Use code $referralCode for bonus coins. '
            '$referralLink';
      }

      await _analytics.logEvent(
        name: 'referral_code_shared',
        parameters: {'code': referralCode},
      );

      final result = await SharePlus.instance.share(
        ShareParams(
          text: text,
          subject: 'Join Mix & Mingle - Get bonus coins!',
        ),
      );

      return ShareResult(
        success: true,
        link: referralLink,
        shareStatus: result.status,
      );
    } catch (e) {
      debugPrint('❌ [Share] Failed to share referral: $e');
      return ShareResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================

  String _formatEventTime(DateTime time) {
    final now = DateTime.now();
    final isToday = time.year == now.year &&
        time.month == now.month &&
        time.day == now.day;
    final isTomorrow = time.year == now.year &&
        time.month == now.month &&
        time.day == now.day + 1;

    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final amPm = time.hour >= 12 ? 'PM' : 'AM';
    final timeStr = '$hour:${time.minute.toString().padLeft(2, '0')} $amPm';

    if (isToday) {
      return 'Today at $timeStr';
    } else if (isTomorrow) {
      return 'Tomorrow at $timeStr';
    } else {
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${months[time.month - 1]} ${time.day} at $timeStr';
    }
  }

  /// Get share statistics for a room
  Future<ShareStats> getRoomShareStats(String roomId) async {
    try {
      final doc = await _firestore.collection('rooms').doc(roomId).get();
      final data = doc.data();

      return ShareStats(
        totalShares: data?['shareCount'] ?? 0,
        lastSharedAt: (data?['lastSharedAt'] as Timestamp?)?.toDate(),
      );
    } catch (e) {
      debugPrint('❌ [Share] Failed to get stats: $e');
      return const ShareStats();
    }
  }
}

// ============================================================
// DATA CLASSES
// ============================================================

class ShareResult {
  final bool success;
  final String? link;
  final ShareResultStatus? shareStatus;
  final String? error;

  const ShareResult({
    required this.success,
    this.link,
    this.shareStatus,
    this.error,
  });

  bool get wasShared =>
      shareStatus == ShareResultStatus.success ||
      shareStatus == ShareResultStatus.dismissed;
}

class ShareStats {
  final int totalShares;
  final DateTime? lastSharedAt;

  const ShareStats({
    this.totalShares = 0,
    this.lastSharedAt,
  });
}
