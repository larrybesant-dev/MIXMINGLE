import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Gift animation types
enum GiftAnimationType {
  fadeIn,
  slideUp,
  bounce,
  sparkle,
  heartExplosion,
  fireworks,
  rainbow,
  custom,
}

/// Gift categories
enum GiftCategory {
  romantic,
  celebration,
  luxury,
  fun,
  seasonal,
  custom,
}

/// Enhanced gift model
class EnhancedGift {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final int coinCost;
  final GiftCategory category;
  final GiftAnimationType animationType;
  final String? animationAsset; // Path to animation asset
  final Color primaryColor;
  final Color secondaryColor;
  final bool isPremium;
  final bool isLimited;
  final DateTime? availableUntil;
  final int? maxDailyUses;

  const EnhancedGift({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.coinCost,
    required this.category,
    required this.animationType,
    this.animationAsset,
    required this.primaryColor,
    required this.secondaryColor,
    this.isPremium = false,
    this.isLimited = false,
    this.availableUntil,
    this.maxDailyUses,
  });

  factory EnhancedGift.fromMap(Map<String, dynamic> map) {
    return EnhancedGift(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      emoji: map['emoji'] ?? '',
      coinCost: map['coinCost'] ?? 0,
      category: GiftCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => GiftCategory.fun,
      ),
      animationType: GiftAnimationType.values.firstWhere(
        (e) => e.name == map['animationType'],
        orElse: () => GiftAnimationType.fadeIn,
      ),
      animationAsset: map['animationAsset'],
      primaryColor: Color(map['primaryColor'] ?? Colors.pink.toARGB32()),
      secondaryColor: Color(map['secondaryColor'] ?? Colors.red.toARGB32()),
      isPremium: map['isPremium'] ?? false,
      isLimited: map['isLimited'] ?? false,
      availableUntil: map['availableUntil'] != null
          ? (map['availableUntil'] as Timestamp).toDate()
          : null,
      maxDailyUses: map['maxDailyUses'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'emoji': emoji,
      'coinCost': coinCost,
      'category': category.name,
      'animationType': animationType.name,
      'animationAsset': animationAsset,
      'primaryColor': primaryColor.toARGB32(),
      'secondaryColor': secondaryColor.toARGB32(),
      'isPremium': isPremium,
      'isLimited': isLimited,
      'availableUntil':
          availableUntil != null ? Timestamp.fromDate(availableUntil!) : null,
      'maxDailyUses': maxDailyUses,
    };
  }

  bool get isAvailable {
    if (availableUntil == null) return true;
    return DateTime.now().isBefore(availableUntil!);
  }
}

/// Gift transaction model
class GiftTransaction {
  final String id;
  final String senderId;
  final String senderName;
  final String receiverId;
  final String receiverName;
  final String giftId;
  final String giftName;
  final String giftEmoji;
  final int coinAmount;
  final String message;
  final String? roomId;
  final DateTime timestamp;
  final bool isAnonymous;

  const GiftTransaction({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.receiverName,
    required this.giftId,
    required this.giftName,
    required this.giftEmoji,
    required this.coinAmount,
    required this.message,
    this.roomId,
    required this.timestamp,
    this.isAnonymous = false,
  });

  factory GiftTransaction.fromMap(Map<String, dynamic> map) {
    return GiftTransaction(
      id: map['id'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      receiverId: map['receiverId'] ?? '',
      receiverName: map['receiverName'] ?? '',
      giftId: map['giftId'] ?? '',
      giftName: map['giftName'] ?? '',
      giftEmoji: map['giftEmoji'] ?? '',
      coinAmount: map['coinAmount'] ?? 0,
      message: map['message'] ?? '',
      roomId: map['roomId'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      isAnonymous: map['isAnonymous'] ?? false,
    );
  }
}

/// Enhanced gift service
class EnhancedGiftService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');

  /// Get all available gifts
  Future<List<EnhancedGift>> getAvailableGifts() async {
    try {
      final gifts = await _firestore.collection('enhanced_gifts').get();
      return gifts.docs
          .map((doc) => EnhancedGift.fromMap({'id': doc.id, ...doc.data()}))
          .where((gift) => gift.isAvailable)
          .toList();
    } catch (e) {
      debugPrint('Error getting available gifts: $e');
      return [];
    }
  }

  /// Get gifts by category
  Future<List<EnhancedGift>> getGiftsByCategory(GiftCategory category) async {
    try {
      final gifts = await _firestore
          .collection('enhanced_gifts')
          .where('category', isEqualTo: category.name)
          .get();

      return gifts.docs
          .map((doc) => EnhancedGift.fromMap({'id': doc.id, ...doc.data()}))
          .where((gift) => gift.isAvailable)
          .toList();
    } catch (e) {
      debugPrint('Error getting gifts by category: $e');
      return [];
    }
  }

  /// Send enhanced gift
  Future<void> sendGift({
    required String senderId,
    required String senderName,
    required String receiverId,
    required String receiverName,
    required EnhancedGift gift,
    required String message,
    String? roomId,
    bool isAnonymous = false,
  }) async {
    try {
      // Check daily usage limits for limited gifts
      if (gift.maxDailyUses != null) {
        await _checkDailyUsageLimit(senderId, gift.id, gift.maxDailyUses!);
      }

      await _functions.httpsCallable('sendEnhancedGift').call({
        'senderId': senderId,
        'senderName': senderName,
        'receiverId': receiverId,
        'receiverName': receiverName,
        'giftId': gift.id,
        'giftName': gift.name,
        'giftEmoji': gift.emoji,
        'coinAmount': gift.coinCost,
        'message': message,
        'roomId': roomId,
        'isAnonymous': isAnonymous,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error sending gift: $e');
      rethrow;
    }
  }

  /// Get user's received gifts
  Future<List<GiftTransaction>> getReceivedGifts(String userId,
      {int limit = 50}) async {
    try {
      final gifts = await _firestore
          .collection('gift_transactions')
          .where('receiverId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return gifts.docs
          .map((doc) => GiftTransaction.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting received gifts: $e');
      return [];
    }
  }

  /// Get user's sent gifts
  Future<List<GiftTransaction>> getSentGifts(String userId,
      {int limit = 50}) async {
    try {
      final gifts = await _firestore
          .collection('gift_transactions')
          .where('senderId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return gifts.docs
          .map((doc) => GiftTransaction.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting sent gifts: $e');
      return [];
    }
  }

  /// Get gift leaderboard (most gifted users)
  Future<List<Map<String, dynamic>>> getGiftLeaderboard(
      {int limit = 10}) async {
    try {
      // This would typically use a Firebase Function to aggregate data
      final result = await _functions.httpsCallable('getGiftLeaderboard').call({
        'limit': limit,
      });

      return List<Map<String, dynamic>>.from(result.data ?? []);
    } catch (e) {
      debugPrint('Error getting gift leaderboard: $e');
      return [];
    }
  }

  /// Get gift statistics for user
  Future<Map<String, dynamic>> getGiftStats(String userId) async {
    try {
      final sentGifts = await getSentGifts(userId, limit: 1000);
      final receivedGifts = await getReceivedGifts(userId, limit: 1000);

      final totalSent = sentGifts.length;
      final totalReceived = receivedGifts.length;
      final totalCoinsSent =
          sentGifts.fold<int>(0, (total, gift) => total + gift.coinAmount);
      final totalCoinsReceived =
          receivedGifts.fold<int>(0, (total, gift) => total + gift.coinAmount);

      // Most popular sent gift
      final sentGiftCounts = <String, int>{};
      for (final gift in sentGifts) {
        sentGiftCounts[gift.giftName] =
            (sentGiftCounts[gift.giftName] ?? 0) + 1;
      }
      final mostSentGift = sentGiftCounts.isNotEmpty
          ? sentGiftCounts.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key
          : null;

      // Most popular received gift
      final receivedGiftCounts = <String, int>{};
      for (final gift in receivedGifts) {
        receivedGiftCounts[gift.giftName] =
            (receivedGiftCounts[gift.giftName] ?? 0) + 1;
      }
      final mostReceivedGift = receivedGiftCounts.isNotEmpty
          ? receivedGiftCounts.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key
          : null;

      return {
        'totalSent': totalSent,
        'totalReceived': totalReceived,
        'totalCoinsSent': totalCoinsSent,
        'totalCoinsReceived': totalCoinsReceived,
        'mostSentGift': mostSentGift,
        'mostReceivedGift': mostReceivedGift,
        'netCoins': totalCoinsReceived - totalCoinsSent,
      };
    } catch (e) {
      debugPrint('Error getting gift stats: $e');
      return {};
    }
  }

  /// Create custom gift (premium feature)
  Future<void> createCustomGift({
    required String creatorId,
    required String name,
    required String description,
    required String emoji,
    required int coinCost,
    required GiftCategory category,
    required GiftAnimationType animationType,
    required Color primaryColor,
    required Color secondaryColor,
  }) async {
    try {
      await _functions.httpsCallable('createCustomGift').call({
        'creatorId': creatorId,
        'name': name,
        'description': description,
        'emoji': emoji,
        'coinCost': coinCost,
        'category': category.name,
        'animationType': animationType.name,
        'primaryColor': primaryColor.toARGB32(),
        'secondaryColor': secondaryColor.toARGB32(),
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error creating custom gift: $e');
      rethrow;
    }
  }

  /// Get user's custom gifts
  Future<List<EnhancedGift>> getUserCustomGifts(String userId) async {
    try {
      final gifts = await _firestore
          .collection('enhanced_gifts')
          .where('creatorId', isEqualTo: userId)
          .where('isCustom', isEqualTo: true)
          .get();

      return gifts.docs
          .map((doc) => EnhancedGift.fromMap({'id': doc.id, ...doc.data()}))
          .toList();
    } catch (e) {
      debugPrint('Error getting user custom gifts: $e');
      return [];
    }
  }

  Future<void> _checkDailyUsageLimit(
      String userId, String giftId, int maxUses) async {
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';

    final usageDoc = await _firestore
        .collection('gift_daily_usage')
        .doc('${userId}_${giftId}_$todayString')
        .get();

    final currentUses = usageDoc.data()?['count'] ?? 0;
    if (currentUses >= maxUses) {
      throw Exception('Daily usage limit exceeded for this gift');
    }
  }
}

/// Gift animation widget
class GiftAnimation extends StatefulWidget {
  final EnhancedGift gift;
  final VoidCallback? onAnimationComplete;

  const GiftAnimation({
    super.key,
    required this.gift,
    this.onAnimationComplete,
  });

  @override
  State<GiftAnimation> createState() => _GiftAnimationState();
}

class _GiftAnimationState extends State<GiftAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward().then((_) {
      widget.onAnimationComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [widget.gift.primaryColor, widget.gift.secondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: widget.gift.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.gift.emoji,
                  style: const TextStyle(fontSize: 60),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.gift.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (widget.gift.isPremium)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'PREMIUM',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Riverpod providers
final enhancedGiftServiceProvider = Provider<EnhancedGiftService>((ref) {
  return EnhancedGiftService();
});

final availableGiftsProvider = FutureProvider<List<EnhancedGift>>((ref) async {
  final service = ref.watch(enhancedGiftServiceProvider);
  return service.getAvailableGifts();
});

final giftsByCategoryProvider =
    FutureProvider.family<List<EnhancedGift>, GiftCategory>(
        (ref, category) async {
  final service = ref.watch(enhancedGiftServiceProvider);
  return service.getGiftsByCategory(category);
});

final receivedGiftsProvider =
    FutureProvider.family<List<GiftTransaction>, String>((ref, userId) async {
  final service = ref.watch(enhancedGiftServiceProvider);
  return service.getReceivedGifts(userId);
});

final sentGiftsProvider =
    FutureProvider.family<List<GiftTransaction>, String>((ref, userId) async {
  final service = ref.watch(enhancedGiftServiceProvider);
  return service.getSentGifts(userId);
});

final giftLeaderboardProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final service = ref.watch(enhancedGiftServiceProvider);
  return service.getGiftLeaderboard();
});

final userGiftStatsProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, userId) async {
  final service = ref.watch(enhancedGiftServiceProvider);
  return service.getGiftStats(userId);
});

final userCustomGiftsProvider =
    FutureProvider.family<List<EnhancedGift>, String>((ref, userId) async {
  final service = ref.watch(enhancedGiftServiceProvider);
  return service.getUserCustomGifts(userId);
});
