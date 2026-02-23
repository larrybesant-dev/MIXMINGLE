/// Retention Service
///
/// Manages retention loops including daily rewards, weekly perks,
/// room streaks, and creator badges to keep users engaged.
library;

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/analytics/analytics_service.dart';

/// Service for managing user retention mechanics
class RetentionService {
  static RetentionService? _instance;
  static RetentionService get instance => _instance ??= RetentionService._();

  RetentionService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AnalyticsService _analytics = AnalyticsService.instance;

  // Reward amounts
  static const int dailyCoinReward = 10;
  static const int dailySpotlightMinutes = 5;
  static const int weeklyVipBonusCoins = 50;
  static const int streakBonusMultiplier = 2;

  // ============================================================
  // DAILY REWARDS
  // ============================================================

  /// Grant daily login coins
  /// Returns the number of coins granted (0 if already claimed today)
  Future<DailyRewardResult> grantDailyCoins(String userId) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final rewardsRef = userRef.collection('rewards').doc('daily');

      return await _firestore.runTransaction((transaction) async {
        final rewardsDoc = await transaction.get(rewardsRef);
        final userData = await transaction.get(userRef);

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        DateTime? lastClaimDate;
        int currentStreak = 0;

        if (rewardsDoc.exists) {
          final data = rewardsDoc.data()!;
          final lastClaim = data['lastCoinClaim'] as Timestamp?;
          if (lastClaim != null) {
            lastClaimDate = DateTime(
              lastClaim.toDate().year,
              lastClaim.toDate().month,
              lastClaim.toDate().day,
            );
          }
          currentStreak = data['loginStreak'] ?? 0;
        }

        // Check if already claimed today
        if (lastClaimDate != null && lastClaimDate.isAtSameMomentAs(today)) {
          return DailyRewardResult(
            success: false,
            coinsGranted: 0,
            currentStreak: currentStreak,
            message: 'You already claimed your daily coins today!',
            nextClaimTime: today.add(const Duration(days: 1)),
          );
        }

        // Calculate streak
        final yesterday = today.subtract(const Duration(days: 1));
        if (lastClaimDate != null && lastClaimDate.isAtSameMomentAs(yesterday)) {
          currentStreak++;
        } else {
          currentStreak = 1; // Reset streak
        }

        // Calculate bonus coins based on streak
        int coinsToGrant = dailyCoinReward;
        if (currentStreak >= 7) {
          coinsToGrant *= streakBonusMultiplier;
        }

        // Update rewards document
        transaction.set(rewardsRef, {
          'lastCoinClaim': FieldValue.serverTimestamp(),
          'loginStreak': currentStreak,
          'totalDailyClaimsCount': FieldValue.increment(1),
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        // Update user coin balance
        final currentBalance = userData.data()?['coinBalance'] ?? 0;
        transaction.update(userRef, {
          'coinBalance': currentBalance + coinsToGrant,
        });

        // Log transaction
        final transactionRef = userRef.collection('coin_transactions').doc();
        transaction.set(transactionRef, {
          'type': 'earn',
          'source': 'daily_login',
          'amount': coinsToGrant,
          'balanceAfter': currentBalance + coinsToGrant,
          'streak': currentStreak,
          'timestamp': FieldValue.serverTimestamp(),
        });

        return DailyRewardResult(
          success: true,
          coinsGranted: coinsToGrant,
          currentStreak: currentStreak,
          message: currentStreak >= 7
              ? 'ðŸ”¥ $currentStreak-day streak! Double coins!'
              : 'âœ¨ +$coinsToGrant coins! Day $currentStreak streak',
          nextClaimTime: today.add(const Duration(days: 1)),
        );
      });
    } catch (e) {
      debugPrint('âŒ [Retention] Failed to grant daily coins: $e');
      return DailyRewardResult(
        success: false,
        coinsGranted: 0,
        currentStreak: 0,
        message: 'Failed to claim daily reward',
      );
    }
  }

  /// Grant daily spotlight minutes
  Future<SpotlightRewardResult> grantDailySpotlight(String userId) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final rewardsRef = userRef.collection('rewards').doc('daily');

      return await _firestore.runTransaction((transaction) async {
        final rewardsDoc = await transaction.get(rewardsRef);

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        if (rewardsDoc.exists) {
          final lastClaim = rewardsDoc.data()!['lastSpotlightClaim'] as Timestamp?;
          if (lastClaim != null) {
            final lastClaimDate = DateTime(
              lastClaim.toDate().year,
              lastClaim.toDate().month,
              lastClaim.toDate().day,
            );
            if (lastClaimDate.isAtSameMomentAs(today)) {
              return SpotlightRewardResult(
                success: false,
                minutesGranted: 0,
                message: 'Already claimed spotlight today',
              );
            }
          }
        }

        // Update rewards document
        transaction.set(rewardsRef, {
          'lastSpotlightClaim': FieldValue.serverTimestamp(),
          'totalSpotlightClaims': FieldValue.increment(1),
        }, SetOptions(merge: true));

        // Update user spotlight minutes
        transaction.update(userRef, {
          'spotlightMinutes': FieldValue.increment(dailySpotlightMinutes),
        });

        return SpotlightRewardResult(
          success: true,
          minutesGranted: dailySpotlightMinutes,
          message: 'âœ¨ +$dailySpotlightMinutes spotlight minutes!',
        );
      });
    } catch (e) {
      debugPrint('âŒ [Retention] Failed to grant spotlight: $e');
      return SpotlightRewardResult(
        success: false,
        minutesGranted: 0,
        message: 'Failed to claim spotlight',
      );
    }
  }

  /// Send daily return notification
  /// Should be called by a scheduled function
  Future<void> sendDailyReturnNotification(String userId) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final userData = await userRef.get();

      if (!userData.exists) return;

      final lastActive = userData.data()?['lastActive'] as Timestamp?;
      if (lastActive == null) return;

      final hoursSinceActive =
          DateTime.now().difference(lastActive.toDate()).inHours;

      // Only send if user hasn't been active in 20-28 hours
      if (hoursSinceActive < 20 || hoursSinceActive > 28) return;

      final streak = await _getCurrentStreak(userId);

      // Create notification
      await _firestore.collection('notifications').add({
        'userId': userId,
        'type': 'daily_return',
        'title': 'Your daily reward is waiting! ðŸŽ',
        'body': streak > 1
            ? 'Keep your $streak-day streak alive! Claim your bonus coins now.'
            : 'Claim your free coins and spotlight minutes!',
        'data': {
          'route': '/rewards',
          'streak': streak,
        },
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _analytics.logEvent(
        name: 'daily_return_notification_sent',
        parameters: {'user_id': userId, 'streak': streak},
      );
    } catch (e) {
      debugPrint('âŒ [Retention] Failed to send daily notification: $e');
    }
  }

  // ============================================================
  // WEEKLY REWARDS
  // ============================================================

  /// Grant weekly VIP perks (for VIP members)
  Future<WeeklyRewardResult> grantWeeklyVipPerks(
    String userId,
    String membershipTier,
  ) async {
    try {
      if (membershipTier != 'vip' && membershipTier != 'vip_plus') {
        return WeeklyRewardResult(
          success: false,
          perksGranted: [],
          message: 'VIP membership required',
        );
      }

      final userRef = _firestore.collection('users').doc(userId);
      final rewardsRef = userRef.collection('rewards').doc('weekly');

      return await _firestore.runTransaction((transaction) async {
        final rewardsDoc = await transaction.get(rewardsRef);

        final now = DateTime.now();
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final thisWeek = DateTime(weekStart.year, weekStart.month, weekStart.day);

        if (rewardsDoc.exists) {
          final lastClaim = rewardsDoc.data()!['lastVipPerksClaim'] as Timestamp?;
          if (lastClaim != null) {
            final lastClaimWeek = lastClaim.toDate();
            final lastWeekStart = lastClaimWeek
                .subtract(Duration(days: lastClaimWeek.weekday - 1));
            if (DateTime(lastWeekStart.year, lastWeekStart.month, lastWeekStart.day)
                .isAtSameMomentAs(thisWeek)) {
              return WeeklyRewardResult(
                success: false,
                perksGranted: [],
                message: 'Already claimed this week',
              );
            }
          }
        }

        final perks = <String>[];
        int bonusCoins = weeklyVipBonusCoins;

        // VIP+ gets extra perks
        if (membershipTier == 'vip_plus') {
          bonusCoins = (bonusCoins * 1.5).round();
          perks.add('priority_matching');
        }

        perks.add('bonus_coins');
        perks.add('exclusive_badge');

        // Update rewards
        transaction.set(rewardsRef, {
          'lastVipPerksClaim': FieldValue.serverTimestamp(),
          'totalVipWeeklyClaims': FieldValue.increment(1),
        }, SetOptions(merge: true));

        // Grant bonus coins
        transaction.update(userRef, {
          'coinBalance': FieldValue.increment(bonusCoins),
        });

        return WeeklyRewardResult(
          success: true,
          perksGranted: perks,
          bonusCoins: bonusCoins,
          message: 'ðŸŒŸ Weekly VIP perks claimed!',
        );
      });
    } catch (e) {
      debugPrint('âŒ [Retention] Failed to grant weekly VIP perks: $e');
      return WeeklyRewardResult(
        success: false,
        perksGranted: [],
        message: 'Failed to claim weekly perks',
      );
    }
  }

  /// Generate weekly themes for rooms
  Future<List<WeeklyTheme>> generateWeeklyThemes() async {
    try {
      final now = DateTime.now();
      // Week number can be used for theme rotation in future
      // ignore: unused_local_variable
      final weekNumber = (now.difference(DateTime(now.year)).inDays / 7).ceil();

      // Predefined theme rotation
      final themes = [
        WeeklyTheme(
          id: 'music_monday',
          name: 'Music Monday',
          description: 'Share your favorite tunes and discover new music!',
          emoji: 'ðŸŽµ',
          category: 'music',
          bonusCoins: 5,
        ),
        WeeklyTheme(
          id: 'trivia_tuesday',
          name: 'Trivia Tuesday',
          description: 'Test your knowledge in fun trivia rooms!',
          emoji: 'ðŸ§ ',
          category: 'games',
          bonusCoins: 10,
        ),
        WeeklyTheme(
          id: 'wellness_wednesday',
          name: 'Wellness Wednesday',
          description: 'Focus on self-care and mental health.',
          emoji: 'ðŸ§˜',
          category: 'wellness',
          bonusCoins: 5,
        ),
        WeeklyTheme(
          id: 'throwback_thursday',
          name: 'Throwback Thursday',
          description: 'Reminisce about the good old days!',
          emoji: 'ðŸ“¼',
          category: 'nostalgia',
          bonusCoins: 5,
        ),
        WeeklyTheme(
          id: 'fun_friday',
          name: 'Fun Friday',
          description: 'Party time! Let loose and have fun.',
          emoji: 'ðŸŽ‰',
          category: 'party',
          bonusCoins: 10,
        ),
        WeeklyTheme(
          id: 'social_saturday',
          name: 'Social Saturday',
          description: 'Make new friends and connections!',
          emoji: 'ðŸ¤',
          category: 'social',
          bonusCoins: 5,
        ),
        WeeklyTheme(
          id: 'chill_sunday',
          name: 'Chill Sunday',
          description: 'Relax and unwind with good conversation.',
          emoji: 'â˜•',
          category: 'chill',
          bonusCoins: 5,
        ),
      ];

      // Return theme for current day
      final dayOfWeek = now.weekday - 1; // 0-6
      return [themes[dayOfWeek]];
    } catch (e) {
      debugPrint('âŒ [Retention] Failed to generate themes: $e');
      return [];
    }
  }

  // ============================================================
  // LONG-TERM RETENTION
  // ============================================================

  /// Track room hosting/participation streaks
  Future<RoomStreakResult> trackRoomStreaks(
    String userId, {
    required bool isHosting,
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final streaksRef = userRef.collection('streaks').doc('rooms');

      return await _firestore.runTransaction((transaction) async {
        final streaksDoc = await transaction.get(streaksRef);

        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);

        int currentStreak = 0;
        int longestStreak = 0;
        DateTime? lastActivityDate;

        if (streaksDoc.exists) {
          final data = streaksDoc.data()!;
          currentStreak = isHosting
              ? (data['hostingStreak'] ?? 0)
              : (data['participationStreak'] ?? 0);
          longestStreak = isHosting
              ? (data['longestHostingStreak'] ?? 0)
              : (data['longestParticipationStreak'] ?? 0);
          final lastActivity = isHosting
              ? data['lastHostingDate'] as Timestamp?
              : data['lastParticipationDate'] as Timestamp?;
          if (lastActivity != null) {
            lastActivityDate = DateTime(
              lastActivity.toDate().year,
              lastActivity.toDate().month,
              lastActivity.toDate().day,
            );
          }
        }

        // Already logged today
        if (lastActivityDate != null && lastActivityDate.isAtSameMomentAs(today)) {
          return RoomStreakResult(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            isNewRecord: false,
          );
        }

        // Calculate new streak
        final yesterday = today.subtract(const Duration(days: 1));
        if (lastActivityDate != null && lastActivityDate.isAtSameMomentAs(yesterday)) {
          currentStreak++;
        } else if (lastActivityDate == null || !lastActivityDate.isAtSameMomentAs(today)) {
          currentStreak = 1;
        }

        final isNewRecord = currentStreak > longestStreak;
        if (isNewRecord) {
          longestStreak = currentStreak;
        }

        // Update streaks
        final updateData = isHosting
            ? {
                'hostingStreak': currentStreak,
                'longestHostingStreak': longestStreak,
                'lastHostingDate': FieldValue.serverTimestamp(),
                'totalHostingSessions': FieldValue.increment(1),
              }
            : {
                'participationStreak': currentStreak,
                'longestParticipationStreak': longestStreak,
                'lastParticipationDate': FieldValue.serverTimestamp(),
                'totalParticipationSessions': FieldValue.increment(1),
              };

        transaction.set(streaksRef, updateData, SetOptions(merge: true));

        // Award badge for milestones
        if (currentStreak == 7 || currentStreak == 30 || currentStreak == 100) {
          await _awardStreakBadge(userId, currentStreak, isHosting);
        }

        return RoomStreakResult(
          currentStreak: currentStreak,
          longestStreak: longestStreak,
          isNewRecord: isNewRecord,
        );
      });
    } catch (e) {
      debugPrint('âŒ [Retention] Failed to track streaks: $e');
      return RoomStreakResult(
        currentStreak: 0,
        longestStreak: 0,
        isNewRecord: false,
      );
    }
  }

  /// Track creator badges and achievements
  Future<List<CreatorBadge>> trackCreatorBadges(String userId) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final statsRef = userRef.collection('stats').doc('creator');
      final badgesRef = userRef.collection('badges');

      final statsDoc = await statsRef.get();
      final earnedBadgesQuery = await badgesRef.get();

      final earnedBadgeIds = earnedBadgesQuery.docs.map((d) => d.id).toSet();
      final newBadges = <CreatorBadge>[];

      if (statsDoc.exists) {
        final stats = statsDoc.data()!;
        final roomsHosted = stats['roomsHosted'] ?? 0;
        final totalListeners = stats['totalListeners'] ?? 0;
        final totalMinutesHosted = stats['totalMinutesHosted'] ?? 0;

        // Check badge eligibility
        final badgesToCheck = [
          CreatorBadge(
            id: 'first_room',
            name: 'Room Starter',
            description: 'Hosted your first room',
            emoji: 'ðŸŽ¤',
            requirement: 1,
            stat: 'roomsHosted',
          ),
          CreatorBadge(
            id: 'room_pro',
            name: 'Room Pro',
            description: 'Hosted 10 rooms',
            emoji: 'ðŸŽ¯',
            requirement: 10,
            stat: 'roomsHosted',
          ),
          CreatorBadge(
            id: 'host_master',
            name: 'Host Master',
            description: 'Hosted 50 rooms',
            emoji: 'ðŸ‘‘',
            requirement: 50,
            stat: 'roomsHosted',
          ),
          CreatorBadge(
            id: 'crowd_pleaser',
            name: 'Crowd Pleaser',
            description: 'Reached 100 total listeners',
            emoji: 'ðŸ‘¥',
            requirement: 100,
            stat: 'totalListeners',
          ),
          CreatorBadge(
            id: 'influencer',
            name: 'Influencer',
            description: 'Reached 1000 total listeners',
            emoji: 'â­',
            requirement: 1000,
            stat: 'totalListeners',
          ),
          CreatorBadge(
            id: 'marathon_host',
            name: 'Marathon Host',
            description: 'Hosted for 10+ hours total',
            emoji: 'â±ï¸',
            requirement: 600, // 10 hours in minutes
            stat: 'totalMinutesHosted',
          ),
        ];

        for (final badge in badgesToCheck) {
          if (earnedBadgeIds.contains(badge.id)) continue;

          int statValue;
          switch (badge.stat) {
            case 'roomsHosted':
              statValue = roomsHosted;
              break;
            case 'totalListeners':
              statValue = totalListeners;
              break;
            case 'totalMinutesHosted':
              statValue = totalMinutesHosted;
              break;
            default:
              continue;
          }

          if (statValue >= badge.requirement) {
            await badgesRef.doc(badge.id).set({
              'name': badge.name,
              'description': badge.description,
              'emoji': badge.emoji,
              'earnedAt': FieldValue.serverTimestamp(),
            });
            newBadges.add(badge);
          }
        }
      }

      return newBadges;
    } catch (e) {
      debugPrint('âŒ [Retention] Failed to track creator badges: $e');
      return [];
    }
  }

  // ============================================================
  // HELPER METHODS
  // ============================================================

  Future<int> _getCurrentStreak(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('rewards')
          .doc('daily')
          .get();
      return doc.data()?['loginStreak'] ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _awardStreakBadge(
    String userId,
    int streak,
    bool isHosting,
  ) async {
    try {
      final badgeId = isHosting
          ? 'hosting_streak_$streak'
          : 'participation_streak_$streak';

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('badges')
          .doc(badgeId)
          .set({
        'name': '$streak-Day ${isHosting ? 'Hosting' : 'Participation'} Streak',
        'emoji': streak >= 100 ? 'ðŸ†' : (streak >= 30 ? 'ðŸ¥‡' : 'ðŸ”¥'),
        'earnedAt': FieldValue.serverTimestamp(),
      });

      await _analytics.logEvent(
        name: 'streak_badge_earned',
        parameters: {
          'user_id': userId,
          'streak': streak,
          'is_hosting': isHosting,
        },
      );
    } catch (e) {
      debugPrint('âŒ [Retention] Failed to award streak badge: $e');
    }
  }

  /// Get user's retention stats
  Future<RetentionStats> getUserRetentionStats(String userId) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);

      final rewardsDoc = await userRef.collection('rewards').doc('daily').get();
      final streaksDoc = await userRef.collection('streaks').doc('rooms').get();
      final badgesQuery = await userRef.collection('badges').get();

      return RetentionStats(
        loginStreak: rewardsDoc.data()?['loginStreak'] ?? 0,
        hostingStreak: streaksDoc.data()?['hostingStreak'] ?? 0,
        participationStreak: streaksDoc.data()?['participationStreak'] ?? 0,
        totalBadges: badgesQuery.docs.length,
        longestLoginStreak: rewardsDoc.data()?['longestLoginStreak'] ?? 0,
      );
    } catch (e) {
      debugPrint('âŒ [Retention] Failed to get stats: $e');
      return const RetentionStats();
    }
  }
}

// ============================================================
// DATA CLASSES
// ============================================================

class DailyRewardResult {
  final bool success;
  final int coinsGranted;
  final int currentStreak;
  final String message;
  final DateTime? nextClaimTime;

  const DailyRewardResult({
    required this.success,
    required this.coinsGranted,
    required this.currentStreak,
    required this.message,
    this.nextClaimTime,
  });
}

class SpotlightRewardResult {
  final bool success;
  final int minutesGranted;
  final String message;

  const SpotlightRewardResult({
    required this.success,
    required this.minutesGranted,
    required this.message,
  });
}

class WeeklyRewardResult {
  final bool success;
  final List<String> perksGranted;
  final int bonusCoins;
  final String message;

  const WeeklyRewardResult({
    required this.success,
    required this.perksGranted,
    this.bonusCoins = 0,
    required this.message,
  });
}

class WeeklyTheme {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final String category;
  final int bonusCoins;

  const WeeklyTheme({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.category,
    required this.bonusCoins,
  });
}

class RoomStreakResult {
  final int currentStreak;
  final int longestStreak;
  final bool isNewRecord;

  const RoomStreakResult({
    required this.currentStreak,
    required this.longestStreak,
    required this.isNewRecord,
  });
}

class CreatorBadge {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final int requirement;
  final String stat;

  const CreatorBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.requirement,
    required this.stat,
  });
}

class RetentionStats {
  final int loginStreak;
  final int hostingStreak;
  final int participationStreak;
  final int totalBadges;
  final int longestLoginStreak;

  const RetentionStats({
    this.loginStreak = 0,
    this.hostingStreak = 0,
    this.participationStreak = 0,
    this.totalBadges = 0,
    this.longestLoginStreak = 0,
  });
}
