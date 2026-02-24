import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Coin earning sources
enum CoinSource {
  dailyLogin,
  roomParticipation,
  messageSent,
  friendAdded,
  badgeEarned,
  referral,
  purchase,
  adminGrant,
}

/// Coin transaction types
enum TransactionType {
  earn,
  spend,
  purchase,
  refund,
}

/// Enhanced coin economy service
class CoinEconomyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');

  /// Get user's current coin balance
  Future<int> getUserBalance(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data()?['coinBalance'] ?? 0;
    } catch (e) {
      debugPrint('Error getting user balance: $e');
      return 0;
    }
  }

  /// Add coins to user balance with transaction logging
  Future<void> addCoins({
    required String userId,
    required int amount,
    required CoinSource source,
    String? description,
    String? referenceId,
  }) async {
    try {
      // Call Firebase Function to add coins and log transaction
      await _functions.httpsCallable('addCoinsWithTransaction').call({
        'userId': userId,
        'amount': amount,
        'source': source.name,
        'description': description ?? _getDefaultDescription(source),
        'referenceId': referenceId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error adding coins: $e');
      rethrow;
    }
  }

  /// Spend coins with transaction logging
  Future<void> spendCoins({
    required String userId,
    required int amount,
    required String purpose,
    String? referenceId,
  }) async {
    try {
      await _functions.httpsCallable('spendCoins').call({
        'userId': userId,
        'amount': amount,
        'purpose': purpose,
        'referenceId': referenceId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error spending coins: $e');
      rethrow;
    }
  }

  /// Process coin purchase
  Future<void> purchaseCoins({
    required String userId,
    required int coinAmount,
    required double usdAmount,
    required String paymentMethod,
    String? transactionId,
  }) async {
    try {
      await _functions.httpsCallable('purchaseCoins').call({
        'userId': userId,
        'coinAmount': coinAmount,
        'usdAmount': usdAmount,
        'paymentMethod': paymentMethod,
        'transactionId': transactionId,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error purchasing coins: $e');
      rethrow;
    }
  }

  /// Award daily login bonus
  Future<void> awardDailyLoginBonus(String userId) async {
    try {
      // Check if user already claimed today
      final today = DateTime.now();
      final todayString = '${today.year}-${today.month}-${today.day}';

      final lastClaimDoc = await _firestore
          .collection('user_daily_logins')
          .doc('${userId}_$todayString')
          .get();

      if (!lastClaimDoc.exists) {
        // Award 10 coins for daily login
        await addCoins(
          userId: userId,
          amount: 10,
          source: CoinSource.dailyLogin,
          description: 'Daily login bonus',
          referenceId: todayString,
        );

        // Mark as claimed
        await _firestore
            .collection('user_daily_logins')
            .doc('${userId}_$todayString')
            .set({
          'userId': userId,
          'date': todayString,
          'claimedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error awarding daily login bonus: $e');
    }
  }

  /// Award room participation bonus
  Future<void> awardRoomParticipationBonus(
      String userId, String roomId, int minutes) async {
    try {
      // Award 1 coin per 5 minutes of participation
      final coinsEarned = (minutes / 5).floor();
      if (coinsEarned > 0) {
        await addCoins(
          userId: userId,
          amount: coinsEarned,
          source: CoinSource.roomParticipation,
          description: 'Room participation bonus ($minutes minutes)',
          referenceId: roomId,
        );
      }
    } catch (e) {
      debugPrint('Error awarding room participation bonus: $e');
    }
  }

  /// Award message activity bonus
  Future<void> awardMessageBonus(String userId) async {
    try {
      // Award 1 coin for every 10 messages sent (daily limit)
      const messagesPerCoin = 10;
      final today = DateTime.now();
      final todayString = '${today.year}-${today.month}-${today.day}';

      final messageCountDoc = await _firestore
          .collection('user_message_counts')
          .doc('${userId}_$todayString')
          .get();

      final currentCount = messageCountDoc.data()?['count'] ?? 0;
      final newCount = currentCount + 1;

      // Update message count
      await _firestore
          .collection('user_message_counts')
          .doc('${userId}_$todayString')
          .set({
        'userId': userId,
        'date': todayString,
        'count': newCount,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Award coin every 10 messages
      if (newCount % messagesPerCoin == 0) {
        await addCoins(
          userId: userId,
          amount: 1,
          source: CoinSource.messageSent,
          description: 'Message activity bonus ($newCount messages today)',
          referenceId: todayString,
        );
      }
    } catch (e) {
      debugPrint('Error awarding message bonus: $e');
    }
  }

  /// Award friend addition bonus
  Future<void> awardFriendBonus(String userId, String friendId) async {
    try {
      await addCoins(
        userId: userId,
        amount: 5,
        source: CoinSource.friendAdded,
        description: 'Friend addition bonus',
        referenceId: friendId,
      );
    } catch (e) {
      debugPrint('Error awarding friend bonus: $e');
    }
  }

  /// Award badge earning bonus
  Future<void> awardBadgeBonus(
      String userId, String badgeId, String badgeName) async {
    try {
      // Different coin amounts based on badge rarity
      final rarityMultipliers = {
        'common': 5,
        'uncommon': 10,
        'rare': 25,
        'epic': 50,
        'legendary': 100,
      };

      // Get badge rarity from badge definition
      final badgeDoc =
          await _firestore.collection('badge_definitions').doc(badgeId).get();
      final rarity = badgeDoc.data()?['rarity'] ?? 'common';
      final coinAmount = rarityMultipliers[rarity] ?? 5;

      await addCoins(
        userId: userId,
        amount: coinAmount,
        source: CoinSource.badgeEarned,
        description: 'Badge earned: $badgeName',
        referenceId: badgeId,
      );
    } catch (e) {
      debugPrint('Error awarding badge bonus: $e');
    }
  }

  /// Get coin purchase packages
  Future<List<Map<String, dynamic>>> getCoinPackages() async {
    try {
      final packages = await _firestore.collection('coin_packages').get();
      return packages.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      debugPrint('Error getting coin packages: $e');
      return [];
    }
  }

  /// Get user's transaction history
  Future<List<Map<String, dynamic>>> getTransactionHistory(String userId,
      {int limit = 50}) async {
    try {
      final transactions = await _firestore
          .collection('coin_transactions')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return transactions.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    } catch (e) {
      debugPrint('Error getting transaction history: $e');
      return [];
    }
  }

  /// Get coin earning statistics
  Future<Map<String, dynamic>> getEarningStats(String userId) async {
    try {
      final transactions = await _firestore
          .collection('coin_transactions')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: 'earn')
          .get();

      final stats = <String, dynamic>{
        'totalEarned': 0,
        'bySource': <String, int>{},
        'todayEarned': 0,
        'thisWeekEarned': 0,
        'thisMonthEarned': 0,
      };

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final weekStart = today.subtract(Duration(days: now.weekday - 1));
      final monthStart = DateTime(now.year, now.month, 1);

      for (final doc in transactions.docs) {
        final data = doc.data();
        final amount = (data['amount'] as num?)?.toInt() ?? 0;
        final source = data['source'] as String? ?? 'unknown';
        final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

        if (timestamp == null) continue;

        stats['totalEarned'] = (stats['totalEarned'] as int) + amount;
        final bySource = stats['bySource'] as Map<String, int>;
        bySource[source] = (bySource[source] ?? 0) + amount;

        if (timestamp.isAfter(today)) {
          stats['todayEarned'] = (stats['todayEarned'] as int) + amount;
        }
        if (timestamp.isAfter(weekStart)) {
          stats['thisWeekEarned'] = (stats['thisWeekEarned'] as int) + amount;
        }
        if (timestamp.isAfter(monthStart)) {
          stats['thisMonthEarned'] = (stats['thisMonthEarned'] as int) + amount;
        }
      }

      return stats;
    } catch (e) {
      debugPrint('Error getting earning stats: $e');
      return {};
    }
  }

  String _getDefaultDescription(CoinSource source) {
    switch (source) {
      case CoinSource.dailyLogin:
        return 'Daily login bonus';
      case CoinSource.roomParticipation:
        return 'Room participation bonus';
      case CoinSource.messageSent:
        return 'Message activity bonus';
      case CoinSource.friendAdded:
        return 'Friend addition bonus';
      case CoinSource.badgeEarned:
        return 'Badge earning bonus';
      case CoinSource.referral:
        return 'Referral bonus';
      case CoinSource.purchase:
        return 'Coin purchase';
      case CoinSource.adminGrant:
        return 'Admin grant';
    }
  }
}

/// Riverpod providers
final coinEconomyServiceProvider = Provider<CoinEconomyService>((ref) {
  return CoinEconomyService();
});

final userCoinBalanceProvider =
    FutureProvider.family<int, String>((ref, userId) async {
  final service = ref.watch(coinEconomyServiceProvider);
  return service.getUserBalance(userId);
});

final coinPackagesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(coinEconomyServiceProvider);
  return service.getCoinPackages();
});

final userTransactionHistoryProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>(
        (ref, userId) async {
  final service = ref.watch(coinEconomyServiceProvider);
  return service.getTransactionHistory(userId);
});

final userEarningStatsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, userId) async {
  final service = ref.watch(coinEconomyServiceProvider);
  return service.getEarningStats(userId);
});

// Add missing awardCoins method as alias
extension CoinEconomyServiceExtension on CoinEconomyService {
  Future<void> awardCoins(String userId, int amount, String source) async {
    await addCoins(
      userId: userId,
      amount: amount,
      source: CoinSource.values.firstWhere(
        (s) => s.name == source,
        orElse: () => CoinSource.adminGrant,
      ),
    );
  }
}
