/// Notification Templates
///
/// Predefined notification templates for various app events including
/// daily return, favorite host live, room activity, referral rewards,
/// and VIP offers.
library;

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for managing notification templates
class NotificationTemplates {
  static NotificationTemplates? _instance;
  static NotificationTemplates get instance =>
      _instance ??= NotificationTemplates._();

  NotificationTemplates._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================================
  // DAILY RETURN NOTIFICATION
  // ============================================================

  /// Create daily return notification
  NotificationTemplate dailyReturn({
    required int currentStreak,
    int coinsAvailable = 10,
  }) {
    String title;
    String body;

    if (currentStreak == 0) {
      title = 'Your daily reward is waiting! ðŸŽ';
      body = 'Claim your free $coinsAvailable coins and spotlight minutes!';
    } else if (currentStreak < 7) {
      title = 'Keep your streak alive! ðŸ”¥';
      body =
          '$currentStreak-day streak! Claim today for $coinsAvailable coins.';
    } else {
      title = 'You\'re on fire! ðŸ”¥ðŸ”¥';
      body = '$currentStreak-day streak! Double coins waiting for you!';
    }

    return NotificationTemplate(
      type: NotificationType.dailyReturn,
      title: title,
      body: body,
      data: {
        'route': '/rewards',
        'streak': currentStreak,
        'coins': coinsAvailable,
      },
      priority: NotificationPriority.normal,
      icon: 'gift',
      color: '#FFC107', // Amber
    );
  }

  // ============================================================
  // FAVORITE HOST LIVE
  // ============================================================

  /// Create notification when a favorite host goes live
  NotificationTemplate favoriteHostLive({
    required String hostId,
    required String hostName,
    required String roomId,
    required String roomTitle,
    String? hostPhotoUrl,
  }) {
    return NotificationTemplate(
      type: NotificationType.favoriteHostLive,
      title: '$hostName is live! ðŸŽ¤',
      body: 'Join "$roomTitle" now!',
      data: {
        'route': '/room/$roomId',
        'hostId': hostId,
        'roomId': roomId,
        'action': 'join_room',
      },
      priority: NotificationPriority.high,
      icon: 'mic',
      color: '#E91E63', // Pink
      imageUrl: hostPhotoUrl,
    );
  }

  // ============================================================
  // ROOM ACTIVITY
  // ============================================================

  /// Create notification for room activity
  NotificationTemplate roomActivity({
    required RoomActivityType activityType,
    required String roomId,
    required String roomTitle,
    String? userName,
    int? participantCount,
  }) {
    String title;
    String body;
    String icon;

    switch (activityType) {
      case RoomActivityType.mentioned:
        title = 'You were mentioned! ðŸ’¬';
        body = userName != null
            ? '$userName mentioned you in "$roomTitle"'
            : 'Someone mentioned you in "$roomTitle"';
        icon = 'at';
        break;

      case RoomActivityType.invited:
        title = 'You\'re invited! ðŸŽ‰';
        body = userName != null
            ? '$userName invited you to "$roomTitle"'
            : 'You\'ve been invited to "$roomTitle"';
        icon = 'mail';
        break;

      case RoomActivityType.promoted:
        title = 'You\'ve been promoted! â­';
        body = 'You\'re now a speaker in "$roomTitle"';
        icon = 'star';
        break;

      case RoomActivityType.trending:
        title = 'Room is trending! ðŸ“ˆ';
        body = '"$roomTitle" has ${participantCount ?? 'many'} people!';
        icon = 'trending_up';
        break;

      case RoomActivityType.ending:
        title = 'Room ending soon â°';
        body = '"$roomTitle" will end in 5 minutes';
        icon = 'timer';
        break;

      case RoomActivityType.newHost:
        title = 'New host! ðŸŽ¤';
        body = '${userName ?? 'Someone'} is hosting "$roomTitle"';
        icon = 'person';
        break;
    }

    return NotificationTemplate(
      type: NotificationType.roomActivity,
      title: title,
      body: body,
      data: {
        'route': '/room/$roomId',
        'roomId': roomId,
        'activityType': activityType.name,
      },
      priority: activityType == RoomActivityType.mentioned ||
              activityType == RoomActivityType.invited
          ? NotificationPriority.high
          : NotificationPriority.normal,
      icon: icon,
      color: '#2196F3', // Blue
    );
  }

  // ============================================================
  // REFERRAL REWARD
  // ============================================================

  /// Create notification for referral reward
  NotificationTemplate referralReward({
    required int coinsEarned,
    required String referredUserName,
    int totalReferrals = 1,
  }) {
    String title;
    String body;

    if (totalReferrals == 1) {
      title = 'Your first referral! ðŸŽ‰';
      body = '$referredUserName joined using your code! +$coinsEarned coins!';
    } else if (totalReferrals == 5) {
      title = 'Super Referrer! â­';
      body =
          '5 friends joined! $referredUserName earned you +$coinsEarned coins!';
    } else if (totalReferrals == 10) {
      title = 'Referral Champion! ðŸ†';
      body =
          '10 friends and counting! +$coinsEarned coins from $referredUserName!';
    } else {
      title = 'Referral Reward! ðŸ’°';
      body = '$referredUserName joined! +$coinsEarned coins for you!';
    }

    return NotificationTemplate(
      type: NotificationType.referralReward,
      title: title,
      body: body,
      data: {
        'route': '/referrals',
        'coinsEarned': coinsEarned,
        'totalReferrals': totalReferrals,
      },
      priority: NotificationPriority.normal,
      icon: 'people',
      color: '#4CAF50', // Green
    );
  }

  // ============================================================
  // VIP OFFER
  // ============================================================

  /// Create notification for VIP offer
  NotificationTemplate vipOffer({
    required VipOfferType offerType,
    int? discountPercent,
    String? expiresIn,
  }) {
    String title;
    String body;
    String color;

    switch (offerType) {
      case VipOfferType.firstTimeOffer:
        title = 'Special Offer Just for You! ðŸŒŸ';
        body = discountPercent != null
            ? '$discountPercent% off VIP - Limited time!'
            : 'Unlock VIP features at a special price!';
        color = '#9C27B0'; // Purple
        break;

      case VipOfferType.limitedTime:
        title = 'Flash Sale! âš¡';
        body = expiresIn != null
            ? '$discountPercent% off VIP for $expiresIn!'
            : 'Don\'t miss this VIP deal!';
        color = '#FF5722'; // Deep Orange
        break;

      case VipOfferType.weekendSpecial:
        title = 'Weekend VIP Special! ðŸŽŠ';
        body = 'Celebrate with $discountPercent% off VIP membership!';
        color = '#E91E63'; // Pink
        break;

      case VipOfferType.loyaltyReward:
        title = 'You\'ve Earned This! â¤ï¸';
        body = 'Exclusive VIP offer for loyal members like you!';
        color = '#F44336'; // Red
        break;

      case VipOfferType.upgradeReminder:
        title = 'Ready to Upgrade? ðŸ‘‘';
        body = 'Unlock unlimited rooms, weekly coins & more!';
        color = '#FFC107'; // Amber
        break;

      case VipOfferType.expiringSoon:
        title = 'Your Offer Expires Soon! â°';
        body = expiresIn != null
            ? 'Only $expiresIn left to get $discountPercent% off VIP!'
            : 'Last chance to grab this VIP deal!';
        color = '#FF9800'; // Orange
        break;
    }

    return NotificationTemplate(
      type: NotificationType.vipOffer,
      title: title,
      body: body,
      data: {
        'route': '/membership',
        'offerType': offerType.name,
        'discountPercent': discountPercent,
        'action': 'view_offer',
      },
      priority: NotificationPriority.high,
      icon: 'crown',
      color: color,
    );
  }

  // ============================================================
  // ADDITIONAL TEMPLATES
  // ============================================================

  /// New message notification
  NotificationTemplate newMessage({
    required String senderId,
    required String senderName,
    required String preview,
    String? senderPhotoUrl,
  }) {
    return NotificationTemplate(
      type: NotificationType.newMessage,
      title: senderName,
      body: preview,
      data: {
        'route': '/messages/$senderId',
        'senderId': senderId,
      },
      priority: NotificationPriority.high,
      icon: 'chat',
      color: '#2196F3',
      imageUrl: senderPhotoUrl,
    );
  }

  /// New follower notification
  NotificationTemplate newFollower({
    required String userId,
    required String userName,
    String? userPhotoUrl,
  }) {
    return NotificationTemplate(
      type: NotificationType.newFollower,
      title: 'New Follower! ðŸ‘‹',
      body: '$userName started following you',
      data: {
        'route': '/profile/$userId',
        'userId': userId,
      },
      priority: NotificationPriority.normal,
      icon: 'person_add',
      color: '#00BCD4',
      imageUrl: userPhotoUrl,
    );
  }

  /// Achievement unlocked notification
  NotificationTemplate achievementUnlocked({
    required String achievementName,
    required String description,
    int? coinsReward,
  }) {
    return NotificationTemplate(
      type: NotificationType.achievement,
      title: 'Achievement Unlocked! ðŸ†',
      body: coinsReward != null
          ? '$achievementName - +$coinsReward coins!'
          : achievementName,
      data: {
        'route': '/achievements',
        'achievement': achievementName,
        'coinsReward': coinsReward,
      },
      priority: NotificationPriority.normal,
      icon: 'emoji_events',
      color: '#FFD700',
    );
  }

  /// Event reminder notification
  NotificationTemplate eventReminder({
    required String eventId,
    required String eventTitle,
    required String startsIn,
  }) {
    return NotificationTemplate(
      type: NotificationType.eventReminder,
      title: 'Event Starting Soon! ðŸ“…',
      body: '"$eventTitle" starts in $startsIn',
      data: {
        'route': '/event/$eventId',
        'eventId': eventId,
      },
      priority: NotificationPriority.high,
      icon: 'event',
      color: '#673AB7',
    );
  }

  // ============================================================
  // SEND NOTIFICATION
  // ============================================================

  /// Send a notification using a template
  Future<void> sendNotification(
    String userId,
    NotificationTemplate template,
  ) async {
    try {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'type': template.type.name,
        'title': template.title,
        'body': template.body,
        'data': template.data,
        'priority': template.priority.name,
        'icon': template.icon,
        'color': template.color,
        'imageUrl': template.imageUrl,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint('âœ… [Notification] Sent ${template.type.name} to $userId');
    } catch (e) {
      debugPrint('âŒ [Notification] Failed to send: $e');
    }
  }

  /// Send batch notifications
  Future<void> sendBatchNotifications(
    List<String> userIds,
    NotificationTemplate template,
  ) async {
    try {
      final batch = _firestore.batch();

      for (final userId in userIds) {
        final ref = _firestore.collection('notifications').doc();
        batch.set(ref, {
          'userId': userId,
          'type': template.type.name,
          'title': template.title,
          'body': template.body,
          'data': template.data,
          'priority': template.priority.name,
          'icon': template.icon,
          'color': template.color,
          'imageUrl': template.imageUrl,
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      debugPrint('âœ… [Notification] Batch sent to ${userIds.length} users');
    } catch (e) {
      debugPrint('âŒ [Notification] Failed to send batch: $e');
    }
  }
}

// ============================================================
// ENUMS
// ============================================================

enum NotificationType {
  dailyReturn,
  favoriteHostLive,
  roomActivity,
  referralReward,
  vipOffer,
  newMessage,
  newFollower,
  achievement,
  eventReminder,
  system,
}

enum NotificationPriority {
  low,
  normal,
  high,
}

enum RoomActivityType {
  mentioned,
  invited,
  promoted,
  trending,
  ending,
  newHost,
}

enum VipOfferType {
  firstTimeOffer,
  limitedTime,
  weekendSpecial,
  loyaltyReward,
  upgradeReminder,
  expiringSoon,
}

// ============================================================
// DATA CLASSES
// ============================================================

class NotificationTemplate {
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final NotificationPriority priority;
  final String icon;
  final String color;
  final String? imageUrl;

  const NotificationTemplate({
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.priority,
    required this.icon,
    required this.color,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'title': title,
      'body': body,
      'data': data,
      'priority': priority.name,
      'icon': icon,
      'color': color,
      'imageUrl': imageUrl,
    };
  }
}
