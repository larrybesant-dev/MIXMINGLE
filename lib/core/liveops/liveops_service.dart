/// LiveOps Service
///
/// Manages live operations including daily/weekly events, limited time offers,
/// room theme rotation, and creator spotlights for dynamic content delivery.
library;

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../analytics/analytics_service.dart';
import 'live_event_model.dart';

/// Service for managing live operations and dynamic content
class LiveOpsService {
  static LiveOpsService? _instance;
  static LiveOpsService get instance => _instance ??= LiveOpsService._();

  LiveOpsService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections
  CollectionReference<Map<String, dynamic>> get _eventsCollection =>
      _firestore.collection('liveops_events');

  CollectionReference<Map<String, dynamic>> get _offersCollection =>
      _firestore.collection('liveops_offers');

  CollectionReference<Map<String, dynamic>> get _themesCollection =>
      _firestore.collection('liveops_themes');

  CollectionReference<Map<String, dynamic>> get _spotlightsCollection =>
      _firestore.collection('liveops_spotlights');

  // Streams
  StreamSubscription<QuerySnapshot>? _eventsSubscription;
  StreamSubscription<QuerySnapshot>? _offersSubscription;

  // Cached data
  final List<LiveEvent> _cachedEvents = [];
  final List<LimitedTimeOffer> _cachedOffers = [];
  RoomTheme? _currentTheme;
  final List<CreatorSpotlight> _cachedSpotlights = [];

  // Stream controllers
  final _activeEventsController = StreamController<List<LiveEvent>>.broadcast();
  final _offersController = StreamController<List<LimitedTimeOffer>>.broadcast();
  final _themeController = StreamController<RoomTheme?>.broadcast();
  final _spotlightsController = StreamController<List<CreatorSpotlight>>.broadcast();

  /// Stream of active events
  Stream<List<LiveEvent>> get activeEventsStream => _activeEventsController.stream;

  /// Stream of available offers
  Stream<List<LimitedTimeOffer>> get offersStream => _offersController.stream;

  /// Stream of current theme
  Stream<RoomTheme?> get themeStream => _themeController.stream;

  /// Stream of creator spotlights
  Stream<List<CreatorSpotlight>> get spotlightsStream => _spotlightsController.stream;

  /// Current active events
  List<LiveEvent> get activeEvents =>
      _cachedEvents.where((e) => e.isActive).toList();

  /// Current theme
  RoomTheme? get currentTheme => _currentTheme;

  /// Current spotlights
  List<CreatorSpotlight> get currentSpotlights =>
      _cachedSpotlights.where((s) => s.isFeatured).toList();

  /// Initialize the service and start listening to changes
  Future<void> initialize() async {
    await _loadActiveEvents();
    await _loadOffers();
    await _loadCurrentTheme();
    await _loadSpotlights();
    _startListening();

    AnalyticsService.instance.logEvent(
      name: 'liveops_initialized',
      parameters: {
        'active_events': _cachedEvents.length,
        'active_offers': _cachedOffers.length,
      },
    );
  }

  /// Schedule daily events
  Future<List<LiveEvent>> scheduleDailyEvents() async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    // Fetch today's scheduled events
    final snapshot = await _eventsCollection
        .where('type', isEqualTo: LiveEventType.dailyChallenge.name)
        .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart))
        .where('startTime', isLessThan: Timestamp.fromDate(todayEnd))
        .get();

    final events = snapshot.docs.map((doc) => LiveEvent.fromFirestore(doc)).toList();

    // Activate scheduled events that should be live
    for (final event in events) {
      if (event.status == LiveEventStatus.scheduled &&
          now.isAfter(event.startTime) &&
          now.isBefore(event.endTime)) {
        await _activateEvent(event.id);
      }
    }

    AnalyticsService.instance.logEvent(
      name: 'daily_events_scheduled',
      parameters: {'count': events.length},
    );

    return events;
  }

  /// Schedule weekly events
  Future<List<LiveEvent>> scheduleWeeklyEvents() async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));

    final snapshot = await _eventsCollection
        .where('type', isEqualTo: LiveEventType.weeklyContest.name)
        .where('startTime', isGreaterThanOrEqualTo: Timestamp.fromDate(weekStart))
        .where('startTime', isLessThan: Timestamp.fromDate(weekEnd))
        .get();

    final events = snapshot.docs.map((doc) => LiveEvent.fromFirestore(doc)).toList();

    for (final event in events) {
      if (event.status == LiveEventStatus.scheduled &&
          now.isAfter(event.startTime) &&
          now.isBefore(event.endTime)) {
        await _activateEvent(event.id);
      }
    }

    AnalyticsService.instance.logEvent(
      name: 'weekly_events_scheduled',
      parameters: {'count': events.length},
    );

    return events;
  }

  /// Push limited time offers to eligible users
  Future<List<LimitedTimeOffer>> pushLimitedTimeOffers({
    String? userTier,
    List<String>? specificOfferIds,
  }) async {
    Query<Map<String, dynamic>> query = _offersCollection;

    final now = DateTime.now();
    query = query
        .where('startTime', isLessThanOrEqualTo: Timestamp.fromDate(now))
        .where('endTime', isGreaterThan: Timestamp.fromDate(now));

    final snapshot = await query.get();
    final offers = <LimitedTimeOffer>[];

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final offer = LimitedTimeOffer(
        id: doc.id,
        title: data['title'] ?? '',
        description: data['description'] ?? '',
        originalPrice: (data['originalPrice'] ?? 0).toDouble(),
        discountedPrice: (data['discountedPrice'] ?? 0).toDouble(),
        discountPercent: data['discountPercent'] ?? 0,
        productId: data['productId'] ?? '',
        startTime: (data['startTime'] as Timestamp).toDate(),
        endTime: (data['endTime'] as Timestamp).toDate(),
        maxRedemptions: data['maxRedemptions'],
        currentRedemptions: data['currentRedemptions'] ?? 0,
        eligibleTiers: List<String>.from(data['eligibleTiers'] ?? []),
        imageUrl: data['imageUrl'],
      );

      // Filter by user tier if specified
      if (userTier != null &&
          offer.eligibleTiers.isNotEmpty &&
          !offer.eligibleTiers.contains(userTier)) {
        continue;
      }

      // Filter by specific offer IDs if specified
      if (specificOfferIds != null && !specificOfferIds.contains(offer.id)) {
        continue;
      }

      if (offer.isAvailable) {
        offers.add(offer);
      }
    }

    _cachedOffers.clear();
    _cachedOffers.addAll(offers);
    _offersController.add(offers);

    AnalyticsService.instance.logEvent(
      name: 'offers_pushed',
      parameters: {
        'count': offers.length,
        'user_tier': userTier ?? 'all',
      },
    );

    return offers;
  }

  /// Rotate room themes based on schedule
  Future<RoomTheme?> rotateRoomThemes() async {
    final now = DateTime.now();

    final snapshot = await _themesCollection
        .where('activeFrom', isLessThanOrEqualTo: Timestamp.fromDate(now))
        .where('activeTo', isGreaterThan: Timestamp.fromDate(now))
        .orderBy('activeFrom', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      _currentTheme = null;
      _themeController.add(null);
      return null;
    }

    final doc = snapshot.docs.first;
    final data = doc.data();

    _currentTheme = RoomTheme(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      primaryColor: data['primaryColor'] ?? '#000000',
      secondaryColor: data['secondaryColor'] ?? '#FFFFFF',
      backgroundImageUrl: data['backgroundImageUrl'],
      iconUrl: data['iconUrl'],
      decorations: Map<String, String>.from(data['decorations'] ?? {}),
      activeFrom: (data['activeFrom'] as Timestamp).toDate(),
      activeTo: (data['activeTo'] as Timestamp).toDate(),
    );

    _themeController.add(_currentTheme);

    AnalyticsService.instance.logEvent(
      name: 'theme_rotated',
      parameters: {
        'theme_id': _currentTheme!.id,
        'theme_name': _currentTheme!.name,
      },
    );

    return _currentTheme;
  }

  /// Manage creator spotlights
  Future<List<CreatorSpotlight>> manageCreatorSpotlights({
    int limit = 5,
  }) async {
    final now = DateTime.now();

    final snapshot = await _spotlightsCollection
        .where('featuredFrom', isLessThanOrEqualTo: Timestamp.fromDate(now))
        .where('featuredTo', isGreaterThan: Timestamp.fromDate(now))
        .orderBy('position')
        .limit(limit)
        .get();

    final spotlights = <CreatorSpotlight>[];

    for (final doc in snapshot.docs) {
      final data = doc.data();
      spotlights.add(CreatorSpotlight(
        id: doc.id,
        creatorId: data['creatorId'] ?? '',
        creatorName: data['creatorName'] ?? '',
        creatorAvatar: data['creatorAvatar'],
        spotlightTitle: data['spotlightTitle'] ?? '',
        spotlightDescription: data['spotlightDescription'] ?? '',
        featuredFrom: (data['featuredFrom'] as Timestamp).toDate(),
        featuredTo: (data['featuredTo'] as Timestamp).toDate(),
        position: data['position'] ?? 0,
        stats: Map<String, int>.from(data['stats'] ?? {}),
      ));
    }

    _cachedSpotlights.clear();
    _cachedSpotlights.addAll(spotlights);
    _spotlightsController.add(spotlights);

    AnalyticsService.instance.logEvent(
      name: 'spotlights_refreshed',
      parameters: {'count': spotlights.length},
    );

    return spotlights;
  }

  /// Create a new live event
  Future<LiveEvent> createEvent({
    required LiveEventType type,
    required String title,
    required String description,
    required DateTime startTime,
    required DateTime endTime,
    EventPriority priority = EventPriority.normal,
    Map<String, dynamic> metadata = const {},
    List<String> targetAudience = const [],
    String? imageUrl,
    String? deepLink,
  }) async {
    final docRef = _eventsCollection.doc();
    final event = LiveEvent(
      id: docRef.id,
      type: type,
      title: title,
      description: description,
      startTime: startTime,
      endTime: endTime,
      status: LiveEventStatus.scheduled,
      priority: priority,
      metadata: metadata,
      targetAudience: targetAudience,
      imageUrl: imageUrl,
      deepLink: deepLink,
      createdAt: DateTime.now(),
    );

    await docRef.set(event.toFirestore());

    AnalyticsService.instance.logEvent(
      name: 'event_created',
      parameters: {
        'event_id': event.id,
        'event_type': type.name,
      },
    );

    return event;
  }

  /// Create a limited time offer
  Future<LimitedTimeOffer> createOffer({
    required String title,
    required String description,
    required double originalPrice,
    required double discountedPrice,
    required String productId,
    required DateTime startTime,
    required DateTime endTime,
    int? maxRedemptions,
    List<String> eligibleTiers = const [],
    String? imageUrl,
  }) async {
    final discountPercent = ((originalPrice - discountedPrice) / originalPrice * 100).round();

    final docRef = _offersCollection.doc();
    final offer = LimitedTimeOffer(
      id: docRef.id,
      title: title,
      description: description,
      originalPrice: originalPrice,
      discountedPrice: discountedPrice,
      discountPercent: discountPercent,
      productId: productId,
      startTime: startTime,
      endTime: endTime,
      maxRedemptions: maxRedemptions,
      eligibleTiers: eligibleTiers,
      imageUrl: imageUrl,
    );

    await docRef.set(offer.toMap());

    AnalyticsService.instance.logEvent(
      name: 'offer_created',
      parameters: {
        'offer_id': offer.id,
        'discount_percent': discountPercent,
      },
    );

    return offer;
  }

  /// Redeem an offer
  Future<bool> redeemOffer(String offerId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    return _firestore.runTransaction((transaction) async {
      final offerDoc = await transaction.get(_offersCollection.doc(offerId));

      if (!offerDoc.exists) return false;

      final data = offerDoc.data()!;
      final maxRedemptions = data['maxRedemptions'] as int?;
      final currentRedemptions = data['currentRedemptions'] as int? ?? 0;

      if (maxRedemptions != null && currentRedemptions >= maxRedemptions) {
        return false;
      }

      // Check if user already redeemed
      final redemptionDoc = await transaction.get(
        _offersCollection.doc(offerId).collection('redemptions').doc(userId),
      );

      if (redemptionDoc.exists) return false;

      // Record redemption
      transaction.set(
        _offersCollection.doc(offerId).collection('redemptions').doc(userId),
        {
          'redeemedAt': FieldValue.serverTimestamp(),
          'userId': userId,
        },
      );

      // Increment counter
      transaction.update(_offersCollection.doc(offerId), {
        'currentRedemptions': FieldValue.increment(1),
      });

      return true;
    });
  }

  /// Get upcoming events for a user
  Future<List<LiveEvent>> getUpcomingEvents({
    int limit = 10,
    List<LiveEventType>? types,
  }) async {
    Query<Map<String, dynamic>> query = _eventsCollection
        .where('status', isEqualTo: LiveEventStatus.scheduled.name)
        .where('startTime', isGreaterThan: Timestamp.fromDate(DateTime.now()));

    if (types != null && types.isNotEmpty) {
      query = query.where('type', whereIn: types.map((t) => t.name).toList());
    }

    final snapshot = await query.orderBy('startTime').limit(limit).get();

    return snapshot.docs.map((doc) => LiveEvent.fromFirestore(doc)).toList();
  }

  /// Get event by ID
  Future<LiveEvent?> getEventById(String eventId) async {
    final doc = await _eventsCollection.doc(eventId).get();
    if (!doc.exists) return null;
    return LiveEvent.fromFirestore(doc);
  }

  /// Track event participation
  Future<void> trackEventParticipation(String eventId, {
    Map<String, dynamic>? metadata,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _eventsCollection.doc(eventId).collection('participants').doc(userId).set({
      'joinedAt': FieldValue.serverTimestamp(),
      'userId': userId,
      'metadata': metadata ?? {},
    });

    AnalyticsService.instance.logEvent(
      name: 'event_participation',
      parameters: {
        'event_id': eventId,
        'user_id': userId,
      },
    );
  }

  // Private methods

  Future<void> _loadActiveEvents() async {
    final now = DateTime.now();

    final snapshot = await _eventsCollection
        .where('status', isEqualTo: LiveEventStatus.active.name)
        .where('endTime', isGreaterThan: Timestamp.fromDate(now))
        .get();

    _cachedEvents.clear();
    _cachedEvents.addAll(
      snapshot.docs.map((doc) => LiveEvent.fromFirestore(doc)),
    );
    _activeEventsController.add(_cachedEvents);
  }

  Future<void> _loadOffers() async {
    await pushLimitedTimeOffers();
  }

  Future<void> _loadCurrentTheme() async {
    await rotateRoomThemes();
  }

  Future<void> _loadSpotlights() async {
    await manageCreatorSpotlights();
  }

  void _startListening() {
    _eventsSubscription = _eventsCollection
        .where('status', isEqualTo: LiveEventStatus.active.name)
        .snapshots()
        .listen((snapshot) {
      _cachedEvents.clear();
      _cachedEvents.addAll(
        snapshot.docs.map((doc) => LiveEvent.fromFirestore(doc)),
      );
      _activeEventsController.add(_cachedEvents);
    });

    _offersSubscription = _offersCollection.snapshots().listen((_) {
      pushLimitedTimeOffers();
    });
  }

  Future<void> _activateEvent(String eventId) async {
    await _eventsCollection.doc(eventId).update({
      'status': LiveEventStatus.active.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Dispose of resources
  void dispose() {
    _eventsSubscription?.cancel();
    _offersSubscription?.cancel();
    _activeEventsController.close();
    _offersController.close();
    _themeController.close();
    _spotlightsController.close();
  }
}
