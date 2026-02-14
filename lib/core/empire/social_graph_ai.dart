/// AI-Assisted Social Graph Service
///
/// Provides AI-powered friend recommendations, room recommendations,
/// creator discovery, and community detection.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Recommendation type
enum RecommendationType {
  friend,
  room,
  creator,
  community,
  content,
}

/// Recommendation reason
enum RecommendationReason {
  mutualFriends,
  commonInterests,
  similarActivity,
  geographicProximity,
  trendingContent,
  followedCreator,
  recentlyJoined,
  highEngagement,
  personalizedAlgorithm,
}

/// Social connection type
enum ConnectionType {
  friend,
  follower,
  following,
  blocked,
  muted,
}

/// Community detection status
enum CommunityStatus {
  emerging,
  growing,
  stable,
  declining,
  inactive,
}

/// Friend recommendation
class FriendRecommendation {
  final String targetUserId;
  final String targetDisplayName;
  final String? targetAvatarUrl;
  final double score;
  final List<RecommendationReason> reasons;
  final List<String> mutualFriends;
  final List<String> commonInterests;
  final DateTime generatedAt;

  const FriendRecommendation({
    required this.targetUserId,
    required this.targetDisplayName,
    this.targetAvatarUrl,
    required this.score,
    this.reasons = const [],
    this.mutualFriends = const [],
    this.commonInterests = const [],
    required this.generatedAt,
  });

  factory FriendRecommendation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FriendRecommendation(
      targetUserId: data['targetUserId'] ?? '',
      targetDisplayName: data['targetDisplayName'] ?? '',
      targetAvatarUrl: data['targetAvatarUrl'],
      score: (data['score'] ?? 0).toDouble(),
      reasons: (data['reasons'] as List<dynamic>? ?? [])
          .map((r) => RecommendationReason.values.firstWhere(
                (rr) => rr.name == r,
                orElse: () => RecommendationReason.personalizedAlgorithm,
              ))
          .toList(),
      mutualFriends: List<String>.from(data['mutualFriends'] ?? []),
      commonInterests: List<String>.from(data['commonInterests'] ?? []),
      generatedAt: (data['generatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'targetUserId': targetUserId,
        'targetDisplayName': targetDisplayName,
        'targetAvatarUrl': targetAvatarUrl,
        'score': score,
        'reasons': reasons.map((r) => r.name).toList(),
        'mutualFriends': mutualFriends,
        'commonInterests': commonInterests,
        'generatedAt': Timestamp.fromDate(generatedAt),
      };
}

/// Room recommendation
class RoomRecommendation {
  final String roomId;
  final String roomName;
  final String? thumbnailUrl;
  final double score;
  final List<RecommendationReason> reasons;
  final int participantCount;
  final List<String> friendsInRoom;
  final String category;
  final bool isLive;

  const RoomRecommendation({
    required this.roomId,
    required this.roomName,
    this.thumbnailUrl,
    required this.score,
    this.reasons = const [],
    this.participantCount = 0,
    this.friendsInRoom = const [],
    this.category = 'general',
    this.isLive = false,
  });

  factory RoomRecommendation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RoomRecommendation(
      roomId: data['roomId'] ?? '',
      roomName: data['roomName'] ?? '',
      thumbnailUrl: data['thumbnailUrl'],
      score: (data['score'] ?? 0).toDouble(),
      reasons: (data['reasons'] as List<dynamic>? ?? [])
          .map((r) => RecommendationReason.values.firstWhere(
                (rr) => rr.name == r,
                orElse: () => RecommendationReason.personalizedAlgorithm,
              ))
          .toList(),
      participantCount: data['participantCount'] ?? 0,
      friendsInRoom: List<String>.from(data['friendsInRoom'] ?? []),
      category: data['category'] ?? 'general',
      isLive: data['isLive'] ?? false,
    );
  }
}

/// Creator recommendation
class CreatorRecommendation {
  final String creatorId;
  final String displayName;
  final String? avatarUrl;
  final double score;
  final List<RecommendationReason> reasons;
  final int followerCount;
  final String primaryCategory;
  final double engagementRate;
  final bool isVerified;

  const CreatorRecommendation({
    required this.creatorId,
    required this.displayName,
    this.avatarUrl,
    required this.score,
    this.reasons = const [],
    this.followerCount = 0,
    this.primaryCategory = 'general',
    this.engagementRate = 0,
    this.isVerified = false,
  });

  factory CreatorRecommendation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CreatorRecommendation(
      creatorId: data['creatorId'] ?? '',
      displayName: data['displayName'] ?? '',
      avatarUrl: data['avatarUrl'],
      score: (data['score'] ?? 0).toDouble(),
      reasons: (data['reasons'] as List<dynamic>? ?? [])
          .map((r) => RecommendationReason.values.firstWhere(
                (rr) => rr.name == r,
                orElse: () => RecommendationReason.personalizedAlgorithm,
              ))
          .toList(),
      followerCount: data['followerCount'] ?? 0,
      primaryCategory: data['primaryCategory'] ?? 'general',
      engagementRate: (data['engagementRate'] ?? 0).toDouble(),
      isVerified: data['isVerified'] ?? false,
    );
  }
}

/// Detected community
class DetectedCommunity {
  final String communityId;
  final String name;
  final String description;
  final CommunityStatus status;
  final List<String> coreMembers;
  final List<String> relatedTopics;
  final int memberCount;
  final double cohesionScore;
  final double growthRate;
  final DateTime firstDetected;
  final DateTime lastUpdated;

  const DetectedCommunity({
    required this.communityId,
    required this.name,
    required this.description,
    required this.status,
    this.coreMembers = const [],
    this.relatedTopics = const [],
    this.memberCount = 0,
    this.cohesionScore = 0,
    this.growthRate = 0,
    required this.firstDetected,
    required this.lastUpdated,
  });

  factory DetectedCommunity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DetectedCommunity(
      communityId: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      status: CommunityStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => CommunityStatus.emerging,
      ),
      coreMembers: List<String>.from(data['coreMembers'] ?? []),
      relatedTopics: List<String>.from(data['relatedTopics'] ?? []),
      memberCount: data['memberCount'] ?? 0,
      cohesionScore: (data['cohesionScore'] ?? 0).toDouble(),
      growthRate: (data['growthRate'] ?? 0).toDouble(),
      firstDetected: (data['firstDetected'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'description': description,
        'status': status.name,
        'coreMembers': coreMembers,
        'relatedTopics': relatedTopics,
        'memberCount': memberCount,
        'cohesionScore': cohesionScore,
        'growthRate': growthRate,
        'firstDetected': Timestamp.fromDate(firstDetected),
        'lastUpdated': Timestamp.fromDate(lastUpdated),
      };
}

/// User social profile
class SocialProfile {
  final String oderId;
  final List<String> interests;
  final List<String> friends;
  final List<String> following;
  final List<String> recentRooms;
  final Map<String, double> categoryPreferences;
  final Map<String, int> activityByHour;

  const SocialProfile({
    required this.oderId,
    this.interests = const [],
    this.friends = const [],
    this.following = const [],
    this.recentRooms = const [],
    this.categoryPreferences = const {},
    this.activityByHour = const {},
  });

  factory SocialProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SocialProfile(
      oderId: doc.id,
      interests: List<String>.from(data['interests'] ?? []),
      friends: List<String>.from(data['friends'] ?? []),
      following: List<String>.from(data['following'] ?? []),
      recentRooms: List<String>.from(data['recentRooms'] ?? []),
      categoryPreferences: Map<String, double>.from(
        (data['categoryPreferences'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, (v as num).toDouble())),
      ),
      activityByHour: Map<String, int>.from(
        (data['activityByHour'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, (v as num).toInt())),
      ),
    );
  }
}

/// Social graph AI service singleton
class SocialGraphAI {
  static SocialGraphAI? _instance;
  static SocialGraphAI get instance => _instance ??= SocialGraphAI._();

  SocialGraphAI._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _profilesCollection =>
      _firestore.collection('social_profiles');
  CollectionReference get _recommendationsCollection =>
      _firestore.collection('recommendations');
  CollectionReference get _communitiesCollection =>
      _firestore.collection('detected_communities');
  CollectionReference get _roomsCollection => _firestore.collection('rooms');
  CollectionReference get _usersCollection => _firestore.collection('users');

  final StreamController<List<FriendRecommendation>> _friendRecsController =
      StreamController<List<FriendRecommendation>>.broadcast();
  final StreamController<List<DetectedCommunity>> _communitiesController =
      StreamController<List<DetectedCommunity>>.broadcast();

  Stream<List<FriendRecommendation>> get friendRecommendationsStream =>
      _friendRecsController.stream;
  Stream<List<DetectedCommunity>> get communitiesStream =>
      _communitiesController.stream;

  // ============================================================
  // FRIEND RECOMMENDATIONS
  // ============================================================

  /// Predict friend connections for a user
  Future<List<FriendRecommendation>> predictFriendConnections(
    String oderId, {
    int limit = 20,
  }) async {
    debugPrint('👥 [SocialGraphAI] Predicting friend connections for $oderId');

    final profile = await _getOrCreateProfile(oderId);
    final candidates = await _findFriendCandidates(profile);
    final scored = await _scoreFriendCandidates(profile, candidates);

    // Sort by score and limit
    scored.sort((a, b) => b.score.compareTo(a.score));
    final recommendations = scored.take(limit).toList();

    // Cache recommendations
    await _cacheRecommendations(oderId, 'friends', recommendations);

    _friendRecsController.add(recommendations);
    debugPrint('✅ [SocialGraphAI] Generated ${recommendations.length} friend recommendations');

    return recommendations;
  }

  Future<SocialProfile> _getOrCreateProfile(String oderId) async {
    final doc = await _profilesCollection.doc(oderId).get();
    if (doc.exists) {
      return SocialProfile.fromFirestore(doc);
    }

    // Create basic profile
    return SocialProfile(oderId: oderId);
  }

  Future<List<Map<String, dynamic>>> _findFriendCandidates(
    SocialProfile profile,
  ) async {
    final candidates = <Map<String, dynamic>>[];

    // Get friends of friends
    for (final friendId in profile.friends.take(10)) {
      final friendDoc = await _profilesCollection.doc(friendId).get();
      if (!friendDoc.exists) continue;

      final friendProfile = SocialProfile.fromFirestore(friendDoc);
      for (final fofId in friendProfile.friends) {
        if (fofId != profile.oderId && !profile.friends.contains(fofId)) {
          candidates.add({
            'userId': fofId,
            'source': 'fof',
            'mutualFriend': friendId,
          });
        }
      }
    }

    // Get users with similar interests
    if (profile.interests.isNotEmpty) {
      final interestSnapshot = await _profilesCollection
          .where('interests', arrayContainsAny: profile.interests.take(10).toList())
          .limit(50)
          .get();

      for (final doc in interestSnapshot.docs) {
        if (doc.id != profile.oderId && !profile.friends.contains(doc.id)) {
          candidates.add({
            'userId': doc.id,
            'source': 'interests',
          });
        }
      }
    }

    // Get users in same recent rooms
    for (final roomId in profile.recentRooms.take(5)) {
      final roomDoc = await _roomsCollection.doc(roomId).get();
      if (!roomDoc.exists) continue;

      final roomData = roomDoc.data() as Map<String, dynamic>;
      final participants = List<String>.from(roomData['participants'] ?? []);

      for (final participantId in participants) {
        if (participantId != profile.oderId &&
            !profile.friends.contains(participantId)) {
          candidates.add({
            'userId': participantId,
            'source': 'room',
            'roomId': roomId,
          });
        }
      }
    }

    // Deduplicate
    final seen = <String>{};
    return candidates.where((c) => seen.add(c['userId'] as String)).toList();
  }

  Future<List<FriendRecommendation>> _scoreFriendCandidates(
    SocialProfile profile,
    List<Map<String, dynamic>> candidates,
  ) async {
    final recommendations = <FriendRecommendation>[];

    for (final candidate in candidates.take(50)) {
      final userId = candidate['userId'] as String;

      // Get user data
      final userDoc = await _usersCollection.doc(userId).get();
      if (!userDoc.exists) continue;

      final userData = userDoc.data() as Map<String, dynamic>;
      final candidateProfile = await _getOrCreateProfile(userId);

      // Calculate score
      double score = 0;
      final reasons = <RecommendationReason>[];

      // Mutual friends
      final mutualFriends = profile.friends
          .where((f) => candidateProfile.friends.contains(f))
          .toList();
      if (mutualFriends.isNotEmpty) {
        score += mutualFriends.length * 10;
        reasons.add(RecommendationReason.mutualFriends);
      }

      // Common interests
      final commonInterests = profile.interests
          .where((i) => candidateProfile.interests.contains(i))
          .toList();
      if (commonInterests.isNotEmpty) {
        score += commonInterests.length * 5;
        reasons.add(RecommendationReason.commonInterests);
      }

      // Similar activity patterns
      final activitySimilarity = _calculateActivitySimilarity(
        profile.activityByHour,
        candidateProfile.activityByHour,
      );
      if (activitySimilarity > 0.5) {
        score += activitySimilarity * 20;
        reasons.add(RecommendationReason.similarActivity);
      }

      // Normalize score to 0-100
      score = math.min(100, score);

      if (score > 10) {
        recommendations.add(FriendRecommendation(
          targetUserId: userId,
          targetDisplayName: userData['displayName'] ?? 'User',
          targetAvatarUrl: userData['avatarUrl'],
          score: score,
          reasons: reasons,
          mutualFriends: mutualFriends.take(5).toList(),
          commonInterests: commonInterests.take(5).toList(),
          generatedAt: DateTime.now(),
        ));
      }
    }

    return recommendations;
  }

  double _calculateActivitySimilarity(
    Map<String, int> activity1,
    Map<String, int> activity2,
  ) {
    if (activity1.isEmpty || activity2.isEmpty) return 0;

    var dotProduct = 0.0;
    var norm1 = 0.0;
    var norm2 = 0.0;

    for (int i = 0; i < 24; i++) {
      final hour = i.toString();
      final v1 = (activity1[hour] ?? 0).toDouble();
      final v2 = (activity2[hour] ?? 0).toDouble();

      dotProduct += v1 * v2;
      norm1 += v1 * v1;
      norm2 += v2 * v2;
    }

    if (norm1 == 0 || norm2 == 0) return 0;
    return dotProduct / (math.sqrt(norm1) * math.sqrt(norm2));
  }

  // ============================================================
  // ROOM RECOMMENDATIONS
  // ============================================================

  /// Recommend rooms for a user
  Future<List<RoomRecommendation>> recommendRooms(
    String oderId, {
    int limit = 20,
  }) async {
    debugPrint('🏠 [SocialGraphAI] Recommending rooms for $oderId');

    final profile = await _getOrCreateProfile(oderId);
    final recommendations = <RoomRecommendation>[];

    // Get live rooms
    final liveRoomsSnapshot = await _roomsCollection
        .where('isLive', isEqualTo: true)
        .limit(50)
        .get();

    for (final doc in liveRoomsSnapshot.docs) {
      final roomData = doc.data() as Map<String, dynamic>;
      final participants = List<String>.from(roomData['participants'] ?? []);

      // Calculate score
      double score = 0;
      final reasons = <RecommendationReason>[];

      // Friends in room
      final friendsInRoom = participants
          .where((p) => profile.friends.contains(p))
          .toList();
      if (friendsInRoom.isNotEmpty) {
        score += friendsInRoom.length * 15;
        reasons.add(RecommendationReason.mutualFriends);
      }

      // Category preference match
      final category = roomData['category'] as String? ?? 'general';
      final categoryPref = profile.categoryPreferences[category] ?? 0;
      score += categoryPref * 10;
      if (categoryPref > 0.5) {
        reasons.add(RecommendationReason.commonInterests);
      }

      // Trending rooms get boost
      if (participants.length > 50) {
        score += 10;
        reasons.add(RecommendationReason.trendingContent);
      }

      // High engagement rooms
      final engagementRate = (roomData['engagementRate'] as num?)?.toDouble() ?? 0;
      if (engagementRate > 0.7) {
        score += 15;
        reasons.add(RecommendationReason.highEngagement);
      }

      if (score > 5) {
        recommendations.add(RoomRecommendation(
          roomId: doc.id,
          roomName: roomData['name'] ?? 'Room',
          thumbnailUrl: roomData['thumbnailUrl'],
          score: math.min(100, score),
          reasons: reasons,
          participantCount: participants.length,
          friendsInRoom: friendsInRoom.take(5).toList(),
          category: category,
          isLive: true,
        ));
      }
    }

    // Sort by score
    recommendations.sort((a, b) => b.score.compareTo(a.score));

    debugPrint('✅ [SocialGraphAI] Recommended ${recommendations.length} rooms');
    return recommendations.take(limit).toList();
  }

  // ============================================================
  // CREATOR RECOMMENDATIONS
  // ============================================================

  /// Recommend creators for a user to follow
  Future<List<CreatorRecommendation>> recommendCreators(
    String oderId, {
    int limit = 20,
  }) async {
    debugPrint('⭐ [SocialGraphAI] Recommending creators for $oderId');

    final profile = await _getOrCreateProfile(oderId);
    final recommendations = <CreatorRecommendation>[];

    // Get creators
    final creatorsSnapshot = await _usersCollection
        .where('isCreator', isEqualTo: true)
        .limit(100)
        .get();

    for (final doc in creatorsSnapshot.docs) {
      if (doc.id == oderId || profile.following.contains(doc.id)) {
        continue;
      }

      final creatorData = doc.data() as Map<String, dynamic>;

      // Calculate score
      double score = 0;
      final reasons = <RecommendationReason>[];

      // Category match
      final primaryCategory = creatorData['primaryCategory'] as String? ?? 'general';
      final categoryPref = profile.categoryPreferences[primaryCategory] ?? 0;
      score += categoryPref * 20;
      if (categoryPref > 0.5) {
        reasons.add(RecommendationReason.commonInterests);
      }

      // Friends following this creator
      final followers = List<String>.from(creatorData['followers'] ?? []);
      final friendsFollowing = followers
          .where((f) => profile.friends.contains(f))
          .length;
      if (friendsFollowing > 0) {
        score += friendsFollowing * 10;
        reasons.add(RecommendationReason.followedCreator);
      }

      // High engagement creators
      final engagementRate = (creatorData['engagementRate'] as num?)?.toDouble() ?? 0;
      if (engagementRate > 0.5) {
        score += engagementRate * 15;
        reasons.add(RecommendationReason.highEngagement);
      }

      // Popular creators
      final followerCount = (creatorData['followerCount'] as num?)?.toInt() ?? 0;
      if (followerCount > 10000) {
        score += 10;
        reasons.add(RecommendationReason.trendingContent);
      }

      if (score > 5) {
        recommendations.add(CreatorRecommendation(
          creatorId: doc.id,
          displayName: creatorData['displayName'] ?? 'Creator',
          avatarUrl: creatorData['avatarUrl'],
          score: math.min(100, score),
          reasons: reasons,
          followerCount: followerCount,
          primaryCategory: primaryCategory,
          engagementRate: engagementRate,
          isVerified: creatorData['isVerified'] ?? false,
        ));
      }
    }

    recommendations.sort((a, b) => b.score.compareTo(a.score));

    debugPrint('✅ [SocialGraphAI] Recommended ${recommendations.length} creators');
    return recommendations.take(limit).toList();
  }

  // ============================================================
  // COMMUNITY DETECTION
  // ============================================================

  /// Detect emerging communities
  Future<List<DetectedCommunity>> detectEmergingCommunities() async {
    debugPrint('🔍 [SocialGraphAI] Detecting emerging communities');

    final communities = <DetectedCommunity>[];

    // Analyze recent room activity to detect clusters
    final recentRoomsSnapshot = await _roomsCollection
        .where('createdAt', isGreaterThan: Timestamp.fromDate(
          DateTime.now().subtract(const Duration(days: 7)),
        ))
        .orderBy('createdAt', descending: true)
        .limit(100)
        .get();

    // Group by category and analyze
    final categoryGroups = <String, List<DocumentSnapshot>>{};
    for (final doc in recentRoomsSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final category = data['category'] as String? ?? 'general';
      categoryGroups.putIfAbsent(category, () => []).add(doc);
    }

    // Detect communities for each category with enough activity
    for (final entry in categoryGroups.entries) {
      if (entry.value.length < 5) continue;

      final category = entry.key;
      final rooms = entry.value;

      // Analyze participants
      final participantCounts = <String, int>{};
      final topics = <String>{};

      for (final room in rooms) {
        final data = room.data() as Map<String, dynamic>;
        final participants = List<String>.from(data['participants'] ?? []);
        final roomTopics = List<String>.from(data['topics'] ?? []);

        for (final p in participants) {
          participantCounts[p] = (participantCounts[p] ?? 0) + 1;
        }
        topics.addAll(roomTopics);
      }

      // Identify core members (participated in 3+ rooms)
      final coreMembers = participantCounts.entries
          .where((e) => e.value >= 3)
          .map((e) => e.key)
          .take(20)
          .toList();

      if (coreMembers.length >= 3) {
        // Calculate cohesion score
        final cohesion = coreMembers.length / participantCounts.length;

        // Determine growth rate
        final roomsLastDay = rooms
            .where((r) {
              final data = r.data() as Map<String, dynamic>;
              final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
              return createdAt != null &&
                  createdAt.isAfter(DateTime.now().subtract(const Duration(days: 1)));
            })
            .length;
        final growthRate = roomsLastDay / math.max(1, rooms.length);

        // Determine status
        final status = growthRate > 0.3
            ? CommunityStatus.emerging
            : growthRate > 0.1
                ? CommunityStatus.growing
                : CommunityStatus.stable;

        final community = DetectedCommunity(
          communityId: 'comm_${category}_${DateTime.now().millisecondsSinceEpoch}',
          name: '$category Community',
          description: 'Emerging community around $category content',
          status: status,
          coreMembers: coreMembers,
          relatedTopics: topics.take(10).toList(),
          memberCount: participantCounts.length,
          cohesionScore: cohesion,
          growthRate: growthRate,
          firstDetected: DateTime.now(),
          lastUpdated: DateTime.now(),
        );

        communities.add(community);

        // Store community
        await _communitiesCollection.doc(community.communityId).set(
              community.toFirestore(),
            );
      }
    }

    _communitiesController.add(communities);
    debugPrint('✅ [SocialGraphAI] Detected ${communities.length} communities');

    return communities;
  }

  /// Get existing detected communities
  Future<List<DetectedCommunity>> getDetectedCommunities({
    CommunityStatus? status,
    int limit = 50,
  }) async {
    var query = _communitiesCollection.orderBy('memberCount', descending: true);

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    final snapshot = await query.limit(limit).get();
    return snapshot.docs.map((doc) => DetectedCommunity.fromFirestore(doc)).toList();
  }

  // ============================================================
  // HELPERS
  // ============================================================

  Future<void> _cacheRecommendations(
    String oderId,
    String type,
    List<dynamic> recommendations,
  ) async {
    await _recommendationsCollection.doc('${oderId}_$type').set({
      'userId': oderId,
      'type': type,
      'recommendations': recommendations.take(20).map((r) {
        if (r is FriendRecommendation) return r.toFirestore();
        return {'id': r.toString()};
      }).toList(),
      'generatedAt': Timestamp.now(),
    });
  }

  /// Update user profile with activity
  Future<void> updateUserActivity(
    String oderId, {
    String? roomVisited,
    String? interactionWith,
    String? interestExpressed,
  }) async {
    final updates = <String, dynamic>{
      'lastActive': Timestamp.now(),
    };

    if (roomVisited != null) {
      updates['recentRooms'] = FieldValue.arrayUnion([roomVisited]);
    }

    if (interestExpressed != null) {
      updates['interests'] = FieldValue.arrayUnion([interestExpressed]);
    }

    // Update activity by hour
    final hour = DateTime.now().hour.toString();
    updates['activityByHour.$hour'] = FieldValue.increment(1);

    await _profilesCollection.doc(oderId).set(updates, SetOptions(merge: true));
  }

  void dispose() {
    _friendRecsController.close();
    _communitiesController.close();
  }
}
