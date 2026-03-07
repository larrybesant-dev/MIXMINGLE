
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/social/match_service.dart';
import '../models/match.dart';
import '../models/user_profile.dart';
import 'auth_providers.dart';
import 'discovery_providers.dart';

/// Service provider
final matchServiceProvider = Provider<MatchService>((ref) => MatchService());

/// Helper to convert a Firestore match document to a [Match] object.
/// Handles both old (userId1/userId2) and new (user1/user2) field naming.
Match _matchFromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
  final data = doc.data();
  return Match.fromJson({
    'id': doc.id,
    'userId1': data['user1'] ?? data['userId1'] ?? '',
    'userId2': data['user2'] ?? data['userId2'] ?? '',
    'matchScore': (data['matchQualityScore'] as num?)?.toInt() ?? 0,
    'status': (data['isActive'] == true) ? 'active' : 'archived',
    'matchedAt': data['matchedAt'],
    'conversationId': data['chatId'] ?? data['conversationId'],
  });
}

/// User matches stream provider — real-time Firestore stream.
final userMatchesProvider = StreamProvider<List<Match>>((ref) {
  final currentUser = ref.watch(currentUserProvider).value;
  if (currentUser == null) return Stream.value([]);

  final firestore = FirebaseFirestore.instance;
  final uid = currentUser.id;

  // Firestore does not support OR across different fields; combine two streams.
  final stream1 = firestore
      .collection('matches')
      .where('user1', isEqualTo: uid)
      .where('isActive', isEqualTo: true)
      .snapshots()
      .map((s) => s.docs.map(_matchFromDoc).toList());

  final stream2 = firestore
      .collection('matches')
      .where('user2', isEqualTo: uid)
      .where('isActive', isEqualTo: true)
      .snapshots()
      .map((s) => s.docs.map(_matchFromDoc).toList());

  // Merge both streams into a combined list, deduplicating by id.
  late StreamSubscription<List<Match>> sub1;
  late StreamSubscription<List<Match>> sub2;
  List<Match> list1 = [];
  List<Match> list2 = [];

  final controller = StreamController<List<Match>>(onCancel: () {
    sub1.cancel();
    sub2.cancel();
  });

  sub1 = stream1.listen((data) {
    list1 = data;
    final seen = <String>{};
    controller.add([...list1, ...list2].where((m) => seen.add(m.id)).toList());
  }, onError: controller.addError);

  sub2 = stream2.listen((data) {
    list2 = data;
    final seen = <String>{};
    controller.add([...list1, ...list2].where((m) => seen.add(m.id)).toList());
  }, onError: controller.addError);

  controller.add([]);
  return controller.stream;
});

/// Pending match requests provider (kept for backward compat; active matches are in userMatchesProvider).
final pendingMatchRequestsProvider = StreamProvider<List<Match>>((ref) {
  return Stream.value([]);
});

/// Accepted matches provider (alias of userMatchesProvider for backward compat).
final acceptedMatchesProvider = StreamProvider<List<Match>>((ref) {
  return ref.watch(userMatchesProvider).when(
    data: (matches) => Stream.value(matches),
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

/// Potential matches provider (users to swipe on)
final potentialMatchesProvider = StreamProvider<List<UserProfile>>((ref) async* {
  final currentUser = ref.watch(currentUserProvider).value;
  if (currentUser == null) {
    yield [];
    return;
  }

  try {
    // This would query potential matches based on preferences
    // For now, return empty list
    yield [];
  } catch (e) {
    yield [];
  }
});


/// Match controller for match operations
final matchControllerProvider = NotifierProvider<MatchController, AsyncValue<Match?>>(() {
  return MatchController();
});

class MatchController extends Notifier<AsyncValue<Match?>> {
  late final MatchService _matchService;

  @override
  AsyncValue<Match?> build() {
    _matchService = ref.watch(matchServiceProvider);
    return const AsyncValue.data(null);
  }

  /// Like a user (create match request)
  Future<void> likeUser(String userId) async {
    state = const AsyncValue.loading();
    try {
      final currentUser = await ref.read(currentUserProvider.future);
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      await _matchService.likeUser(currentUser.id, userId);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  /// Unlike a user
  Future<void> unlikeUser(String userId) async {
    try {
      final currentUser = await ref.read(currentUserProvider.future);
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      await _matchService.unlikeUser(currentUser.id, userId);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  /// Accept a match request
  Future<void> acceptMatch(String matchId) async {
    state = const AsyncValue.loading();
    try {
      final currentUser = await ref.read(currentUserProvider.future);
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Update match status to accepted
      // This would be implemented in MatchService
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  /// Reject a match request
  Future<void> rejectMatch(String matchId) async {
    try {
      final currentUser = await ref.read(currentUserProvider.future);
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Update match status to rejected
      // This would be implemented in MatchService
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  /// Unmatch (remove match)
  Future<void> unmatch(String matchId) async {
    try {
      final currentUser = await ref.read(currentUserProvider.future);
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Delete match or set status to unmatched
      // This would be implemented in MatchService
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      rethrow;
    }
  }

  /// Alias methods for backward compatibility
  Future<void> like(String userId) => likeUser(userId);
  Future<void> accept(String matchId) => acceptMatch(matchId);
  Future<void> reject(String matchId) => rejectMatch(matchId);

  /// Check if user is liked
  Future<bool> isUserLiked(String userId) async {
    try {
      final currentUser = await ref.read(currentUserProvider.future);
      if (currentUser == null) {
        return false;
      }

      return await _matchService.isUserLiked(currentUser.id, userId);
    } catch (e) {
      return false;
    }
  }

  /// Check if users are matched
  Future<bool> isMatched(String userId) async {
    try {
      final currentUser = await ref.read(currentUserProvider.future);
      if (currentUser == null) {
        return false;
      }

      // Check if match exists and is accepted
      return false; // Would query Firestore
    } catch (e) {
      return false;
    }
  }
}

/// Swipe controller for swipe-based matching
final swipeControllerProvider = NotifierProvider<SwipeController, AsyncValue<List<UserProfile>>>(() {
  return SwipeController();
});

class SwipeController extends Notifier<AsyncValue<List<UserProfile>>> {
  late final MatchService _matchService;
  final List<UserProfile> _swipeQueue = [];
  int _currentIndex = 0;

  @override
  AsyncValue<List<UserProfile>> build() {
    _matchService = ref.watch(matchServiceProvider);
    _loadSwipeQueue();
    return const AsyncValue.loading();
  }

  Future<void> _loadSwipeQueue() async {
    state = const AsyncValue.loading();
    try {
      final currentUser = await ref.read(currentUserProvider.future);
      if (currentUser == null) {
        state = const AsyncValue.data([]);
        return;
      }

      // Load potential matches
      // This would query Firestore for users matching preferences
      _swipeQueue.clear();
      _currentIndex = 0;
      state = AsyncValue.data(List.from(_swipeQueue));
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Swipe right (like)
  Future<void> swipeRight() async {
    if (_currentIndex >= _swipeQueue.length) return;

    try {
      final currentUser = await ref.read(currentUserProvider.future);
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final targetUser = _swipeQueue[_currentIndex];
      await _matchService.likeUser(currentUser.id, targetUser.id);

      _currentIndex++;
      state = AsyncValue.data(List.from(_swipeQueue));

      // Load more if running low
      if (_swipeQueue.length - _currentIndex < 3) {
        await _loadMoreProfiles();
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Swipe left (pass)
  Future<void> swipeLeft() async {
    if (_currentIndex >= _swipeQueue.length) return;

    try {
      _currentIndex++;
      state = AsyncValue.data(List.from(_swipeQueue));

      // Load more if running low
      if (_swipeQueue.length - _currentIndex < 3) {
        await _loadMoreProfiles();
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Super like
  Future<void> superLike() async {
    if (_currentIndex >= _swipeQueue.length) return;

    try {
      final currentUser = await ref.read(currentUserProvider.future);
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final targetUser = _swipeQueue[_currentIndex];
      // Would create a match with super_like flag
      await _matchService.likeUser(currentUser.id, targetUser.id);

      _currentIndex++;
      state = AsyncValue.data(List.from(_swipeQueue));
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  /// Undo last swipe
  void undoSwipe() {
    if (_currentIndex > 0) {
      _currentIndex--;
      state = AsyncValue.data(List.from(_swipeQueue));
    }
  }

  /// Get current profile
  UserProfile? get currentProfile {
    if (_currentIndex < _swipeQueue.length) {
      return _swipeQueue[_currentIndex];
    }
    return null;
  }

  /// Reload queue
  Future<void> reload() async {
    await _loadSwipeQueue();
  }

  Future<void> _loadMoreProfiles() async {
    try {
      // Load more potential matches
      // This would append to _swipeQueue
    } catch (e) {
      // Handle error
    }
  }
}

/// Match statistics provider
final matchStatisticsProvider = StreamProvider<Map<String, dynamic>>((ref) async* {
  final currentUser = ref.watch(currentUserProvider).value;
  if (currentUser == null) {
    yield {};
    return;
  }

  // Calculate match statistics
  yield {
    'totalMatches': 0,
    'pendingRequests': 0,
    'acceptedMatches': 0,
    'rejectedMatches': 0,
  };
});

/// Daily swipe limit provider
final dailySwipeLimitProvider = StreamProvider<int>((ref) async* {
  final currentUser = ref.watch(currentUserProvider).value;
  if (currentUser == null) {
    yield 0;
    return;
  }

  // Check subscription status and return limit
  // Free users: 50 swipes/day, Premium: unlimited
  yield 50;
});

/// Remaining swipes provider
final remainingSwipesProvider = StreamProvider<int>((ref) async* {
  final currentUser = ref.watch(currentUserProvider).value;
  if (currentUser == null) {
    yield 0;
    return;
  }

  final limit = await ref.watch(dailySwipeLimitProvider.future);

  // Calculate swipes used today
  // This would query Firestore for likes created today
  const swipesUsed = 0;

  yield limit - swipesUsed;
});

// ── Phase 9: Match Inbox & Like Streams ──────────────────────────────────────

/// Real-time stream of active matches for the current user, ordered newest-first.
final matchInboxProvider = StreamProvider<List<Match>>((ref) {
  final currentUser = ref.watch(currentUserProvider).value;
  if (currentUser == null) return Stream.value([]);

  final service = ref.watch(matchServiceProvider);
  return service.getMatchInboxStream(currentUser.id).map(
    (docs) => docs.map((doc) {
      final data = doc.data();
      return Match.fromJson({
        'id': doc.id,
        'userId1': data['user1'] ?? data['userId1'] ?? '',
        'userId2': data['user2'] ?? data['userId2'] ?? '',
        'matchScore': (data['matchQualityScore'] as num?)?.toInt() ?? 0,
        'status': (data['isActive'] == true) ? 'active' : 'archived',
        'matchedAt': data['matchedAt'],
        'conversationId': data['chatId'] ?? data['conversationId'],
      });
    }).toList(),
  );
});

/// Real-time stream of UserProfiles who have liked the current user (incoming likes).
final incomingLikesProvider = StreamProvider<List<UserProfile>>((ref) {
  final currentUser = ref.watch(currentUserProvider).value;
  if (currentUser == null) return Stream.value([]);

  final service = ref.watch(matchServiceProvider);
  final firestore = FirebaseFirestore.instance;

  return service.getIncomingLikesStream(currentUser.id).asyncMap((snapshot) async {
    final profiles = <UserProfile>[];
    for (final doc in snapshot.docs) {
      final likerId = doc.data()['likerId'] as String?;
      if (likerId == null) continue;
      try {
        final userDoc = await firestore.collection('users').doc(likerId).get();
        if (userDoc.exists) {
          profiles.add(UserProfile.fromMap({'id': userDoc.id, ...?userDoc.data()}));
        }
      } catch (_) {}
    }
    return profiles;
  });
});

/// Real-time stream of UserProfiles the current user has liked (outgoing likes).
final outgoingLikesProvider = StreamProvider<List<UserProfile>>((ref) {
  final currentUser = ref.watch(currentUserProvider).value;
  if (currentUser == null) return Stream.value([]);

  final service = ref.watch(matchServiceProvider);
  final firestore = FirebaseFirestore.instance;

  return service.getOutgoingLikesStream(currentUser.id).asyncMap((snapshot) async {
    final profiles = <UserProfile>[];
    for (final doc in snapshot.docs) {
      final likedUserId = doc.data()['likedUserId'] as String?;
      if (likedUserId == null) continue;
      try {
        final userDoc = await firestore.collection('users').doc(likedUserId).get();
        if (userDoc.exists) {
          profiles.add(UserProfile.fromMap({'id': userDoc.id, ...?userDoc.data()}));
        }
      } catch (_) {}
    }
    return profiles;
  });
});

/// Alias: people who liked the current user and haven't been matched yet.
/// Equivalent to [incomingLikesProvider].
final matchRequestsProvider = incomingLikesProvider;

/// Discovery recommendations: top suggested + trending users, deduplicated, capped at 20.
final matchRecommendationsProvider = FutureProvider<List<UserProfile>>((ref) async {
  final suggested = await ref.watch(suggestedUsersProvider.future);
  final trending = await ref.watch(trendingUsersProvider.future);
  final seen = <String>{};
  final combined = <UserProfile>[];
  for (final u in [...suggested, ...trending]) {
    if (seen.add(u.id)) combined.add(u);
    if (combined.length >= 20) break;
  }
  return combined;
});


