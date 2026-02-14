import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Badge types for different achievements
enum BadgeType {
  social, // Social interactions (friends, followers)
  engagement, // App engagement (messages, rooms joined)
  monetization, // Spending/gifting coins
  achievement, // Special milestones
  seasonal, // Time-limited badges
}

/// Badge rarity levels
enum BadgeRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
}

/// Badge definition
class BadgeDefinition {
  final String id;
  final String name;
  final String description;
  final String iconUrl;
  final BadgeType type;
  final BadgeRarity rarity;
  final Map<String, dynamic> criteria; // Conditions to earn the badge
  final int? maxAwarded; // Limited edition badges
  final DateTime? expiresAt; // Seasonal badges

  const BadgeDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.type,
    required this.rarity,
    required this.criteria,
    this.maxAwarded,
    this.expiresAt,
  });

  factory BadgeDefinition.fromMap(Map<String, dynamic> map) {
    return BadgeDefinition(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      iconUrl: map['iconUrl'],
      type: BadgeType.values.firstWhere(
        (e) => e.toString() == 'BadgeType.${map['type']}',
        orElse: () => BadgeType.achievement,
      ),
      rarity: BadgeRarity.values.firstWhere(
        (e) => e.toString() == 'BadgeRarity.${map['rarity']}',
        orElse: () => BadgeRarity.common,
      ),
      criteria: Map<String, dynamic>.from(map['criteria'] ?? {}),
      maxAwarded: map['maxAwarded'],
      expiresAt: map['expiresAt'] != null ? (map['expiresAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconUrl': iconUrl,
      'type': type.toString().split('.').last,
      'rarity': rarity.toString().split('.').last,
      'criteria': criteria,
      'maxAwarded': maxAwarded,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
    };
  }
}

/// User badge with metadata
class UserBadge {
  final String badgeId;
  final String userId;
  final DateTime awardedAt;
  final String? awardedBy; // User who awarded it (for admin badges)
  final Map<String, dynamic> metadata; // Additional context

  const UserBadge({
    required this.badgeId,
    required this.userId,
    required this.awardedAt,
    this.awardedBy,
    this.metadata = const {},
  });

  factory UserBadge.fromMap(Map<String, dynamic> map) {
    return UserBadge(
      badgeId: map['badgeId'],
      userId: map['userId'],
      awardedAt: (map['awardedAt'] as Timestamp).toDate(),
      awardedBy: map['awardedBy'],
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'badgeId': badgeId,
      'userId': userId,
      'awardedAt': Timestamp.fromDate(awardedAt),
      'awardedBy': awardedBy,
      'metadata': metadata,
    };
  }
}

/// Badge service for managing user achievements
class BadgeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Predefined badge definitions
  static const List<BadgeDefinition> predefinedBadges = [
    // Social badges
    BadgeDefinition(
      id: 'first_friend',
      name: 'Social Butterfly',
      description: 'Made your first friend!',
      iconUrl: 'badges/social_butterfly.png',
      type: BadgeType.social,
      rarity: BadgeRarity.common,
      criteria: {'minFriends': 1},
    ),
    BadgeDefinition(
      id: 'popular',
      name: 'Popular',
      description: 'Reached 100 followers',
      iconUrl: 'badges/popular.png',
      type: BadgeType.social,
      rarity: BadgeRarity.uncommon,
      criteria: {'minFollowers': 100},
    ),
  ];

  /// Get all available badge definitions
  Future<List<BadgeDefinition>> getAllBadgeDefinitions() async {
    try {
      final snapshot = await _firestore.collection('badges').get();
      final badges = snapshot.docs.map((doc) => BadgeDefinition.fromMap(doc.data())).toList();

      // Include predefined badges that aren't in Firestore yet
      final existingIds = badges.map((b) => b.id).toSet();
      final missingBadges = predefinedBadges.where((badge) => !existingIds.contains(badge.id)).toList();

      return [...badges, ...missingBadges];
    } catch (e) {
      // Fallback to predefined badges if Firestore fails
      return predefinedBadges;
    }
  }

  /// Get badge definition by ID
  Future<BadgeDefinition?> getBadgeDefinition(String badgeId) async {
    try {
      final doc = await _firestore.collection('badges').doc(badgeId).get();
      if (doc.exists) {
        return BadgeDefinition.fromMap(doc.data()!);
      }

      // Check predefined badges
      return predefinedBadges.firstWhere((badge) => badge.id == badgeId);
    } catch (e) {
      return predefinedBadges.firstWhere((badge) => badge.id == badgeId);
    }
  }

  /// Get user's badges
  Future<List<UserBadge>> getUserBadges(String userId) async {
    final snapshot = await _firestore
        .collection('user_badges')
        .where('userId', isEqualTo: userId)
        .orderBy('awardedAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => UserBadge.fromMap(doc.data())).toList();
  }

  /// Check if user has a specific badge
  Future<bool> userHasBadge(String userId, String badgeId) async {
    final snapshot = await _firestore
        .collection('user_badges')
        .where('userId', isEqualTo: userId)
        .where('badgeId', isEqualTo: badgeId)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  /// Award badge to user
  Future<bool> awardBadge({
    required String userId,
    required String badgeId,
    String? awardedBy,
    Map<String, dynamic> metadata = const {},
  }) async {
    try {
      // Check if user already has this badge
      if (await userHasBadge(userId, badgeId)) {
        return false; // Already awarded
      }

      // Create user badge
      final userBadge = UserBadge(
        badgeId: badgeId,
        userId: userId,
        awardedAt: DateTime.now(),
        awardedBy: awardedBy,
        metadata: metadata,
      );

      // Save to Firestore
      await _firestore.collection('user_badges').add(userBadge.toMap());

      // Update user's badge list
      await _updateUserBadges(userId, badgeId, add: true);

      return true;
    } catch (e) {
      debugPrint('Error awarding badge: $e');
      return false;
    }
  }

  /// Initialize predefined badges in Firestore
  Future<void> initializeBadges() async {
    final batch = _firestore.batch();

    for (final badge in predefinedBadges) {
      final docRef = _firestore.collection('badges').doc(badge.id);
      batch.set(docRef, badge.toMap(), SetOptions(merge: true));
    }

    await batch.commit();
  }

  /// Update user's badge list in their profile
  Future<void> _updateUserBadges(String userId, String badgeId, {required bool add}) async {
    final userRef = _firestore.collection('users').doc(userId);

    if (add) {
      await userRef.update({
        'badges': FieldValue.arrayUnion([badgeId]),
      });
    } else {
      await userRef.update({
        'badges': FieldValue.arrayRemove([badgeId]),
      });
    }
  }
}

/// Riverpod providers for badge service
final badgeServiceProvider = Provider<BadgeService>((ref) {
  return BadgeService();
});

final allBadgesProvider = FutureProvider<List<BadgeDefinition>>((ref) {
  final badgeService = ref.watch(badgeServiceProvider);
  return badgeService.getAllBadgeDefinitions();
});

final userBadgesProvider = FutureProvider.family<List<UserBadge>, String>((ref, userId) {
  final badgeService = ref.watch(badgeServiceProvider);
  return badgeService.getUserBadges(userId);
});

final badgeDefinitionProvider = FutureProvider.family<BadgeDefinition?, String>((ref, badgeId) {
  final badgeService = ref.watch(badgeServiceProvider);
  return badgeService.getBadgeDefinition(badgeId);
});
