/// Seasonal Event Service
///
/// Manages seasonal events, holiday celebrations, special modes,
/// and time-limited experiences within the application.
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../analytics/analytics_service.dart';

/// Types of seasonal events
enum SeasonalEventType {
  holiday,
  celebration,
  anniversary,
  specialMode,
  communityChallenge,
  tournament,
  festival,
  promotion,
}

/// Season definitions
enum Season {
  spring,
  summer,
  fall,
  winter,
}

/// Special room modes available during events
enum SpecialRoomMode {
  karaokeNight,
  triviaContest,
  speedDating,
  talentShow,
  gameNight,
  movieWatch,
  studySession,
  fitnessChallenge,
  cookingShow,
  debateClub,
}

/// Model for seasonal events
class SeasonalEvent {
  final String id;
  final String name;
  final String description;
  final SeasonalEventType type;
  final DateTime startDate;
  final DateTime endDate;
  final String? bannerImageUrl;
  final String? thumbnailUrl;
  final String primaryColor;
  final String secondaryColor;
  final List<SpecialRoomMode> availableModes;
  final Map<String, dynamic> rewards;
  final Map<String, dynamic> challenges;
  final List<String> decorations;
  final bool isActive;
  final int priority;
  final Map<String, dynamic> metadata;

  const SeasonalEvent({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.startDate,
    required this.endDate,
    this.bannerImageUrl,
    this.thumbnailUrl,
    required this.primaryColor,
    required this.secondaryColor,
    this.availableModes = const [],
    this.rewards = const {},
    this.challenges = const {},
    this.decorations = const [],
    this.isActive = true,
    this.priority = 0,
    this.metadata = const {},
  });

  /// Check if event is currently running
  bool get isRunning {
    final now = DateTime.now();
    return isActive && now.isAfter(startDate) && now.isBefore(endDate);
  }

  /// Check if event is upcoming
  bool get isUpcoming {
    return isActive && DateTime.now().isBefore(startDate);
  }

  /// Get days remaining
  int get daysRemaining {
    if (!isRunning) return 0;
    return endDate.difference(DateTime.now()).inDays;
  }

  /// Get progress percentage (0-100)
  double get progressPercent {
    if (!isRunning) return isUpcoming ? 0 : 100;
    final total = endDate.difference(startDate).inMilliseconds;
    final elapsed = DateTime.now().difference(startDate).inMilliseconds;
    return (elapsed / total * 100).clamp(0, 100);
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'type': type.name,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'bannerImageUrl': bannerImageUrl,
    'thumbnailUrl': thumbnailUrl,
    'primaryColor': primaryColor,
    'secondaryColor': secondaryColor,
    'availableModes': availableModes.map((m) => m.name).toList(),
    'rewards': rewards,
    'challenges': challenges,
    'decorations': decorations,
    'isActive': isActive,
    'priority': priority,
    'metadata': metadata,
  };

  factory SeasonalEvent.fromMap(String id, Map<String, dynamic> map) {
    return SeasonalEvent(
      id: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      type: SeasonalEventType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => SeasonalEventType.celebration,
      ),
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      bannerImageUrl: map['bannerImageUrl'],
      thumbnailUrl: map['thumbnailUrl'],
      primaryColor: map['primaryColor'] ?? '#FF5722',
      secondaryColor: map['secondaryColor'] ?? '#FFC107',
      availableModes: (map['availableModes'] as List?)
          ?.map((m) => SpecialRoomMode.values.firstWhere(
                (mode) => mode.name == m,
                orElse: () => SpecialRoomMode.gameNight,
              ))
          .toList() ?? [],
      rewards: Map<String, dynamic>.from(map['rewards'] ?? {}),
      challenges: Map<String, dynamic>.from(map['challenges'] ?? {}),
      decorations: List<String>.from(map['decorations'] ?? []),
      isActive: map['isActive'] ?? true,
      priority: map['priority'] ?? 0,
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }
}

/// User's progress in a seasonal event
class EventProgress {
  final String eventId;
  final String oduserId;
  final int points;
  final int level;
  final Map<String, bool> completedChallenges;
  final List<String> claimedRewards;
  final DateTime? lastParticipation;
  final Map<String, int> statistics;

  const EventProgress({
    required this.eventId,
    required this.oduserId,
    this.points = 0,
    this.level = 1,
    this.completedChallenges = const {},
    this.claimedRewards = const [],
    this.lastParticipation,
    this.statistics = const {},
  });

  Map<String, dynamic> toMap() => {
    'eventId': eventId,
    'userId': oduserId,
    'points': points,
    'level': level,
    'completedChallenges': completedChallenges,
    'claimedRewards': claimedRewards,
    'lastParticipation': lastParticipation?.toIso8601String(),
    'statistics': statistics,
  };
}

/// Service for managing seasonal events and special modes
class SeasonalEventService {
  static SeasonalEventService? _instance;
  static SeasonalEventService get instance => _instance ??= SeasonalEventService._();

  SeasonalEventService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections
  CollectionReference<Map<String, dynamic>> get _eventsCollection =>
      _firestore.collection('seasonal_events');

  CollectionReference<Map<String, dynamic>> get _progressCollection =>
      _firestore.collection('event_progress');

  // Cache
  final List<SeasonalEvent> _cachedEvents = [];
  SeasonalEvent? _currentEvent;
  final Map<String, EventProgress> _progressCache = {};

  // Stream controllers
  final _eventController = StreamController<SeasonalEvent?>.broadcast();
  final _progressController = StreamController<EventProgress>.broadcast();

  /// Stream of current event changes
  Stream<SeasonalEvent?> get currentEventStream => _eventController.stream;

  /// Stream of progress updates
  Stream<EventProgress> get progressStream => _progressController.stream;

  /// Current active event
  SeasonalEvent? get currentEvent => _currentEvent;

  /// Initialize the service
  Future<void> initialize() async {
    await loadActiveEvents();
    _startEventMonitoring();

    AnalyticsService.instance.logEvent(
      name: 'seasonal_events_initialized',
      parameters: {
        'active_events': _cachedEvents.where((e) => e.isRunning).length,
      },
    );
  }

  /// Load all active events
  Future<List<SeasonalEvent>> loadActiveEvents() async {
    final now = DateTime.now();

    final snapshot = await _eventsCollection
        .where('isActive', isEqualTo: true)
        .where('endDate', isGreaterThan: now.toIso8601String())
        .orderBy('endDate')
        .orderBy('priority', descending: true)
        .get();

    _cachedEvents.clear();
    for (final doc in snapshot.docs) {
      _cachedEvents.add(SeasonalEvent.fromMap(doc.id, doc.data()));
    }

    // Set current highest priority running event
    _currentEvent = _cachedEvents.firstWhere(
      (e) => e.isRunning,
      orElse: () => _cachedEvents.isNotEmpty ? _cachedEvents.first : _createDefaultEvent(),
    );

    _eventController.add(_currentEvent);

    return _cachedEvents;
  }

  /// Get event by ID
  Future<SeasonalEvent?> getEventById(String eventId) async {
    // Check cache first
    final cached = _cachedEvents.cast<SeasonalEvent?>().firstWhere(
      (e) => e?.id == eventId,
      orElse: () => null,
    );
    if (cached != null) return cached;

    final doc = await _eventsCollection.doc(eventId).get();
    if (!doc.exists) return null;

    return SeasonalEvent.fromMap(doc.id, doc.data()!);
  }

  /// Get upcoming events
  List<SeasonalEvent> get upcomingEvents =>
      _cachedEvents.where((e) => e.isUpcoming).toList();

  /// Get running events
  List<SeasonalEvent> get runningEvents =>
      _cachedEvents.where((e) => e.isRunning).toList();

  /// Create a seasonal event
  Future<SeasonalEvent> createEvent({
    required String name,
    required String description,
    required SeasonalEventType type,
    required DateTime startDate,
    required DateTime endDate,
    String? bannerImageUrl,
    String? thumbnailUrl,
    String primaryColor = '#FF5722',
    String secondaryColor = '#FFC107',
    List<SpecialRoomMode> availableModes = const [],
    Map<String, dynamic> rewards = const {},
    Map<String, dynamic> challenges = const {},
    List<String> decorations = const [],
    int priority = 0,
  }) async {
    final docRef = _eventsCollection.doc();

    final event = SeasonalEvent(
      id: docRef.id,
      name: name,
      description: description,
      type: type,
      startDate: startDate,
      endDate: endDate,
      bannerImageUrl: bannerImageUrl,
      thumbnailUrl: thumbnailUrl,
      primaryColor: primaryColor,
      secondaryColor: secondaryColor,
      availableModes: availableModes,
      rewards: rewards,
      challenges: challenges,
      decorations: decorations,
      priority: priority,
    );

    await docRef.set(event.toMap());
    _cachedEvents.add(event);

    AnalyticsService.instance.logEvent(
      name: 'seasonal_event_created',
      parameters: {
        'event_id': event.id,
        'event_type': type.name,
      },
    );

    return event;
  }

  /// Get user's progress for an event
  Future<EventProgress> getEventProgress(String eventId, {String? userId}) async {
    final uid = userId ?? _auth.currentUser?.uid;
    if (uid == null) {
      return EventProgress(eventId: eventId, oduserId: '');
    }

    final cacheKey = '${eventId}_$uid';
    if (_progressCache.containsKey(cacheKey)) {
      return _progressCache[cacheKey]!;
    }

    final doc = await _progressCollection.doc(cacheKey).get();

    if (!doc.exists) {
      final progress = EventProgress(eventId: eventId, oduserId: uid);
      _progressCache[cacheKey] = progress;
      return progress;
    }

    final data = doc.data()!;
    final progress = EventProgress(
      eventId: eventId,
      oduserId: uid,
      points: data['points'] ?? 0,
      level: data['level'] ?? 1,
      completedChallenges: Map<String, bool>.from(data['completedChallenges'] ?? {}),
      claimedRewards: List<String>.from(data['claimedRewards'] ?? []),
      lastParticipation: data['lastParticipation'] != null
          ? DateTime.parse(data['lastParticipation'])
          : null,
      statistics: Map<String, int>.from(data['statistics'] ?? {}),
    );

    _progressCache[cacheKey] = progress;
    return progress;
  }

  /// Add points to user's event progress
  Future<EventProgress> addEventPoints({
    required String eventId,
    required int points,
    String? source,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not authenticated');

    final cacheKey = '${eventId}_$userId';

    await _progressCollection.doc(cacheKey).set({
      'eventId': eventId,
      'userId': userId,
      'points': FieldValue.increment(points),
      'lastParticipation': DateTime.now().toIso8601String(),
      if (source != null) 'statistics.$source': FieldValue.increment(1),
    }, SetOptions(merge: true));

    // Invalidate cache and refresh
    _progressCache.remove(cacheKey);
    final progress = await getEventProgress(eventId);

    _progressController.add(progress);

    AnalyticsService.instance.logEvent(
      name: 'event_points_earned',
      parameters: {
        'event_id': eventId,
        'points': points,
        'source': source ?? 'unknown',
      },
    );

    return progress;
  }

  /// Complete a challenge
  Future<bool> completeChallenge({
    required String eventId,
    required String challengeId,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    final cacheKey = '${eventId}_$userId';

    final progress = await getEventProgress(eventId);
    if (progress.completedChallenges[challengeId] == true) {
      return false; // Already completed
    }

    await _progressCollection.doc(cacheKey).set({
      'completedChallenges.$challengeId': true,
    }, SetOptions(merge: true));

    // Get challenge reward
    final event = await getEventById(eventId);
    final challengeData = event?.challenges[challengeId];
    if (challengeData != null && challengeData['points'] != null) {
      await addEventPoints(
        eventId: eventId,
        points: challengeData['points'] as int,
        source: 'challenge_$challengeId',
      );
    }

    _progressCache.remove(cacheKey);

    AnalyticsService.instance.logEvent(
      name: 'challenge_completed',
      parameters: {
        'event_id': eventId,
        'challenge_id': challengeId,
      },
    );

    return true;
  }

  /// Claim a reward
  Future<bool> claimReward({
    required String eventId,
    required String rewardId,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    final cacheKey = '${eventId}_$userId';

    final progress = await getEventProgress(eventId);
    if (progress.claimedRewards.contains(rewardId)) {
      return false; // Already claimed
    }

    // Check eligibility
    final event = await getEventById(eventId);
    final rewardData = event?.rewards[rewardId];
    if (rewardData != null) {
      final requiredPoints = rewardData['requiredPoints'] as int? ?? 0;
      if (progress.points < requiredPoints) {
        return false; // Not enough points
      }
    }

    await _progressCollection.doc(cacheKey).update({
      'claimedRewards': FieldValue.arrayUnion([rewardId]),
    });

    _progressCache.remove(cacheKey);

    AnalyticsService.instance.logEvent(
      name: 'reward_claimed',
      parameters: {
        'event_id': eventId,
        'reward_id': rewardId,
      },
    );

    return true;
  }

  /// Get event leaderboard
  Future<List<Map<String, dynamic>>> getLeaderboard(
    String eventId, {
    int limit = 100,
  }) async {
    final snapshot = await _progressCollection
        .where('eventId', isEqualTo: eventId)
        .orderBy('points', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.asMap().entries.map((entry) {
      final data = entry.value.data();
      return {
        'rank': entry.key + 1,
        'userId': data['userId'],
        'points': data['points'],
        'level': data['level'],
      };
    }).toList();
  }

  /// Get available special modes for current event
  List<SpecialRoomMode> get availableSpecialModes {
    if (_currentEvent == null) return [];
    return _currentEvent!.availableModes;
  }

  /// Check if a special mode is available
  bool isSpecialModeAvailable(SpecialRoomMode mode) {
    return availableSpecialModes.contains(mode);
  }

  /// Get current season
  Season getCurrentSeason() {
    final month = DateTime.now().month;
    if (month >= 3 && month <= 5) return Season.spring;
    if (month >= 6 && month <= 8) return Season.summer;
    if (month >= 9 && month <= 11) return Season.fall;
    return Season.winter;
  }

  /// Get seasonal decorations
  Map<String, dynamic> getSeasonalDecorations() {
    final season = getCurrentSeason();
    final event = _currentEvent;

    return {
      'season': season.name,
      'eventDecorations': event?.decorations ?? [],
      'primaryColor': event?.primaryColor ?? _getSeasonColor(season),
      'secondaryColor': event?.secondaryColor ?? _getSeasonSecondaryColor(season),
      'bannerImageUrl': event?.bannerImageUrl,
    };
  }

  // Private methods

  void _startEventMonitoring() {
    // Check for event changes every minute
    Timer.periodic(const Duration(minutes: 1), (_) {
      _checkEventStatus();
    });
  }

  Future<void> _checkEventStatus() async {
    final previousEvent = _currentEvent;

    // Reload events to check for status changes
    await loadActiveEvents();

    // Notify if current event changed
    if (previousEvent?.id != _currentEvent?.id) {
      _eventController.add(_currentEvent);

      AnalyticsService.instance.logEvent(
        name: 'current_event_changed',
        parameters: {
          'old_event': previousEvent?.id ?? 'none',
          'new_event': _currentEvent?.id ?? 'none',
        },
      );
    }
  }

  SeasonalEvent _createDefaultEvent() {
    final season = getCurrentSeason();
    return SeasonalEvent(
      id: 'default_${season.name}',
      name: '${season.name.toUpperCase()} Season',
      description: 'Enjoy the ${season.name} season!',
      type: SeasonalEventType.celebration,
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      endDate: DateTime.now().add(const Duration(days: 60)),
      primaryColor: _getSeasonColor(season),
      secondaryColor: _getSeasonSecondaryColor(season),
    );
  }

  String _getSeasonColor(Season season) {
    switch (season) {
      case Season.spring:
        return '#4CAF50';
      case Season.summer:
        return '#FF9800';
      case Season.fall:
        return '#FF5722';
      case Season.winter:
        return '#2196F3';
    }
  }

  String _getSeasonSecondaryColor(Season season) {
    switch (season) {
      case Season.spring:
        return '#8BC34A';
      case Season.summer:
        return '#FFC107';
      case Season.fall:
        return '#BF360C';
      case Season.winter:
        return '#03A9F4';
    }
  }

  /// Dispose resources
  void dispose() {
    _eventController.close();
    _progressController.close();
  }
}


