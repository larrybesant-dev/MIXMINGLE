/// Future Modes Service
///
/// Prototyping and experimentation service for new room modes,
/// interaction types, and monetization paths.
library;

import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../core/analytics/analytics_service.dart';
import 'extension_api.dart';

/// Prototype status
enum PrototypeStatus {
  draft,
  testing,
  feedback,
  approved,
  rejected,
  launched,
}

/// Room mode prototype
class RoomModePrototype {
  final String id;
  final String name;
  final String description;
  final String conceptArt;
  final PrototypeStatus status;
  final List<String> targetAudience;
  final Map<String, dynamic> featureSpec;
  final Map<String, dynamic> metrics;
  final List<PrototypeFeedback> feedback;
  final DateTime createdAt;
  final DateTime? launchedAt;

  const RoomModePrototype({
    required this.id,
    required this.name,
    required this.description,
    this.conceptArt = '',
    required this.status,
    this.targetAudience = const [],
    this.featureSpec = const {},
    this.metrics = const {},
    this.feedback = const [],
    required this.createdAt,
    this.launchedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'conceptArt': conceptArt,
    'status': status.name,
    'targetAudience': targetAudience,
    'featureSpec': featureSpec,
    'metrics': metrics,
    'feedback': feedback.map((f) => f.toMap()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'launchedAt': launchedAt?.toIso8601String(),
  };

  RoomModePrototype copyWith({
    String? id,
    String? name,
    String? description,
    String? conceptArt,
    PrototypeStatus? status,
    List<String>? targetAudience,
    Map<String, dynamic>? featureSpec,
    Map<String, dynamic>? metrics,
    List<PrototypeFeedback>? feedback,
    DateTime? createdAt,
    DateTime? launchedAt,
  }) {
    return RoomModePrototype(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      conceptArt: conceptArt ?? this.conceptArt,
      status: status ?? this.status,
      targetAudience: targetAudience ?? this.targetAudience,
      featureSpec: featureSpec ?? this.featureSpec,
      metrics: metrics ?? this.metrics,
      feedback: feedback ?? this.feedback,
      createdAt: createdAt ?? this.createdAt,
      launchedAt: launchedAt ?? this.launchedAt,
    );
  }
}

/// Interaction type prototype
class InteractionTypePrototype {
  final String id;
  final String name;
  final String description;
  final InteractionCategory category;
  final PrototypeStatus status;
  final Map<String, dynamic> implementation;
  final List<String> compatibleRoomModes;
  final Map<String, dynamic> metrics;
  final DateTime createdAt;

  const InteractionTypePrototype({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.status,
    this.implementation = const {},
    this.compatibleRoomModes = const [],
    this.metrics = const {},
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'category': category.name,
    'status': status.name,
    'implementation': implementation,
    'compatibleRoomModes': compatibleRoomModes,
    'metrics': metrics,
    'createdAt': createdAt.toIso8601String(),
  };
}

/// Interaction categories
enum InteractionCategory {
  gesture,
  reaction,
  voting,
  gamification,
  collaboration,
  commerce,
  social,
}

/// Monetization path prototype
class MonetizationPathPrototype {
  final String id;
  final String name;
  final String description;
  final MonetizationType type;
  final PrototypeStatus status;
  final Map<String, dynamic> revenueModel;
  final Map<String, dynamic> pricingTiers;
  final Map<String, double> projectedMetrics;
  final List<String> requirements;
  final DateTime createdAt;

  const MonetizationPathPrototype({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.status,
    this.revenueModel = const {},
    this.pricingTiers = const {},
    this.projectedMetrics = const {},
    this.requirements = const [],
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'type': type.name,
    'status': status.name,
    'revenueModel': revenueModel,
    'pricingTiers': pricingTiers,
    'projectedMetrics': projectedMetrics,
    'requirements': requirements,
    'createdAt': createdAt.toIso8601String(),
  };
}

/// Monetization types
enum MonetizationType {
  subscription,
  transaction,
  virtualGoods,
  advertising,
  sponsorship,
  licensing,
  marketplace,
}

/// Prototype feedback
class PrototypeFeedback {
  final String userId;
  final int rating;
  final String comment;
  final List<String> tags;
  final DateTime submittedAt;

  const PrototypeFeedback({
    required this.userId,
    required this.rating,
    required this.comment,
    this.tags = const [],
    required this.submittedAt,
  });

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'rating': rating,
    'comment': comment,
    'tags': tags,
    'submittedAt': submittedAt.toIso8601String(),
  };
}

/// Future modes prototyping service
class FutureModesService {
  static FutureModesService? _instance;
  static FutureModesService get instance => _instance ??= FutureModesService._();

  FutureModesService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _random = Random();

  // Stream controllers
  final _roomModePrototypeController = StreamController<RoomModePrototype>.broadcast();
  final _interactionPrototypeController = StreamController<InteractionTypePrototype>.broadcast();
  final _monetizationPrototypeController = StreamController<MonetizationPathPrototype>.broadcast();

  Stream<RoomModePrototype> get roomModePrototypeStream => _roomModePrototypeController.stream;
  Stream<InteractionTypePrototype> get interactionPrototypeStream => _interactionPrototypeController.stream;
  Stream<MonetizationPathPrototype> get monetizationPrototypeStream => _monetizationPrototypeController.stream;

  // Collections
  CollectionReference<Map<String, dynamic>> get _roomModePrototypesCollection =>
      _firestore.collection('room_mode_prototypes');

  CollectionReference<Map<String, dynamic>> get _interactionPrototypesCollection =>
      _firestore.collection('interaction_prototypes');

  CollectionReference<Map<String, dynamic>> get _monetizationPrototypesCollection =>
      _firestore.collection('monetization_prototypes');

  // ============================================================
  // ROOM MODE PROTOTYPING
  // ============================================================

  /// Create new room mode prototypes
  Future<List<RoomModePrototype>> prototypeNewRoomModes({
    int count = 3,
    List<String>? targetAudience,
  }) async {
    debugPrint('ðŸŽ­ [FutureModesService] Generating $count room mode prototypes');

    final prototypes = <RoomModePrototype>[];
    final templates = _getRoomModeTemplates();

    for (int i = 0; i < count && i < templates.length; i++) {
      final template = templates[i];

      final prototype = RoomModePrototype(
        id: 'proto_room_${DateTime.now().millisecondsSinceEpoch}_$i',
        name: template['name'] as String,
        description: template['description'] as String,
        status: PrototypeStatus.draft,
        targetAudience: targetAudience ?? ['creators', 'viewers'],
        featureSpec: template['features'] as Map<String, dynamic>,
        metrics: {
          'estimatedEngagement': 0.7 + _random.nextDouble() * 0.3,
          'developmentEffort': _random.nextInt(5) + 1,
          'marketPotential': _random.nextDouble() * 100,
        },
        feedback: [],
        createdAt: DateTime.now(),
      );

      prototypes.add(prototype);

      // Save to Firestore
      await _roomModePrototypesCollection.doc(prototype.id).set(prototype.toMap());

      // Emit event
      _roomModePrototypeController.add(prototype);
    }

    // Track analytics
    AnalyticsService.instance.logEvent(name: 'prototype_room_modes', parameters: {
      'count': prototypes.length,
    });

    debugPrint('âœ… [FutureModesService] Created ${prototypes.length} room mode prototypes');
    return prototypes;
  }

  List<Map<String, dynamic>> _getRoomModeTemplates() {
    return [
      {
        'name': 'Collaborative Canvas',
        'description': 'Real-time collaborative drawing and whiteboarding with live video feeds',
        'features': {
          'canvas': true,
          'layers': true,
          'tools': ['brush', 'shapes', 'text', 'images'],
          'maxCollaborators': 20,
          'exportFormats': ['png', 'svg', 'pdf'],
        },
      },
      {
        'name': 'Debate Arena',
        'description': 'Structured debate format with timed speaking turns and audience voting',
        'features': {
          'timedSpeaking': true,
          'audienceVoting': true,
          'topicQueue': true,
          'moderatorTools': true,
          'factCheckOverlay': true,
        },
      },
      {
        'name': 'Learning Lab',
        'description': 'Interactive educational sessions with quizzes, polls, and progress tracking',
        'features': {
          'quizzes': true,
          'polls': true,
          'progressTracking': true,
          'certificates': true,
          'breakoutRooms': true,
          'screenAnnotation': true,
        },
      },
      {
        'name': 'Virtual Stage',
        'description': 'Performance-focused room with virtual stage effects and audience reactions',
        'features': {
          'stageEffects': true,
          'lightingControl': true,
          'audienceReactions': true,
          'tipjar': true,
          'recordingStudio': true,
        },
      },
      {
        'name': 'Auction House',
        'description': 'Live auction room with bidding system and digital asset showcase',
        'features': {
          'biddingSystem': true,
          'reservePrice': true,
          'buyNow': true,
          'itemShowcase': true,
          'paymentIntegration': true,
        },
      },
    ];
  }

  // ============================================================
  // INTERACTION TYPE PROTOTYPING
  // ============================================================

  /// Create new interaction type prototypes
  Future<List<InteractionTypePrototype>> prototypeNewInteractionTypes({
    int count = 3,
    InteractionCategory? category,
  }) async {
    debugPrint('ðŸ¤ [FutureModesService] Generating $count interaction type prototypes');

    final prototypes = <InteractionTypePrototype>[];
    final templates = _getInteractionTemplates();

    final filtered = category != null
        ? templates.where((t) => t['category'] == category.name).toList()
        : templates;

    for (int i = 0; i < count && i < filtered.length; i++) {
      final template = filtered[i];

      final prototype = InteractionTypePrototype(
        id: 'proto_interaction_${DateTime.now().millisecondsSinceEpoch}_$i',
        name: template['name'] as String,
        description: template['description'] as String,
        category: InteractionCategory.values.firstWhere(
          (c) => c.name == template['category'],
        ),
        status: PrototypeStatus.draft,
        implementation: template['implementation'] as Map<String, dynamic>,
        compatibleRoomModes: List<String>.from(template['compatibleModes'] ?? []),
        metrics: {
          'engagementPotential': 0.6 + _random.nextDouble() * 0.4,
          'implementationComplexity': _random.nextInt(5) + 1,
        },
        createdAt: DateTime.now(),
      );

      prototypes.add(prototype);

      // Save to Firestore
      await _interactionPrototypesCollection.doc(prototype.id).set(prototype.toMap());

      // Emit event
      _interactionPrototypeController.add(prototype);
    }

    debugPrint('âœ… [FutureModesService] Created ${prototypes.length} interaction prototypes');
    return prototypes;
  }

  List<Map<String, dynamic>> _getInteractionTemplates() {
    return [
      {
        'name': 'Gesture Reactions',
        'description': 'Hand gesture recognition for real-time reactions',
        'category': 'gesture',
        'implementation': {
          'recognizedGestures': ['thumbsUp', 'wave', 'clap', 'heart'],
          'mlModel': 'hand_landmark_detection',
          'triggerThreshold': 0.8,
        },
        'compatibleModes': ['standard', 'stage', 'debate'],
      },
      {
        'name': 'Prediction Markets',
        'description': 'In-room prediction betting on outcomes',
        'category': 'gamification',
        'implementation': {
          'tokenSystem': true,
          'outcomes': 'binary_or_multiple',
          'settlementAuto': true,
        },
        'compatibleModes': ['debate', 'quiz', 'live_events'],
      },
      {
        'name': 'Collaborative Playlist',
        'description': 'Audience-curated music queue with voting',
        'category': 'collaboration',
        'implementation': {
          'votingSystem': 'updown',
          'queueLimit': 50,
          'skipThreshold': 0.6,
          'spotifyIntegration': true,
        },
        'compatibleModes': ['lounge', 'party', 'chill'],
      },
      {
        'name': 'Micro Tips',
        'description': 'Instant micro-transactions for appreciation',
        'category': 'commerce',
        'implementation': {
          'minAmount': 0.10,
          'maxAmount': 10.00,
          'animatedEffects': true,
          'leaderboard': true,
        },
        'compatibleModes': ['all'],
      },
      {
        'name': 'Sentiment Pulse',
        'description': 'Real-time audience sentiment visualization',
        'category': 'social',
        'implementation': {
          'emotions': ['happy', 'sad', 'excited', 'bored', 'confused'],
          'aggregation': 'rolling_average',
          'visualization': 'pulse_wave',
        },
        'compatibleModes': ['all'],
      },
    ];
  }

  // ============================================================
  // MONETIZATION PATH PROTOTYPING
  // ============================================================

  /// Create new monetization path prototypes
  Future<List<MonetizationPathPrototype>> prototypeNewMonetizationPaths({
    int count = 3,
    MonetizationType? type,
  }) async {
    debugPrint('ðŸ’° [FutureModesService] Generating $count monetization prototypes');

    final prototypes = <MonetizationPathPrototype>[];
    final templates = _getMonetizationTemplates();

    final filtered = type != null
        ? templates.where((t) => t['type'] == type.name).toList()
        : templates;

    for (int i = 0; i < count && i < filtered.length; i++) {
      final template = filtered[i];

      final prototype = MonetizationPathPrototype(
        id: 'proto_monetization_${DateTime.now().millisecondsSinceEpoch}_$i',
        name: template['name'] as String,
        description: template['description'] as String,
        type: MonetizationType.values.firstWhere(
          (t) => t.name == template['type'],
        ),
        status: PrototypeStatus.draft,
        revenueModel: template['revenueModel'] as Map<String, dynamic>,
        pricingTiers: template['pricingTiers'] as Map<String, dynamic>,
        projectedMetrics: {
          'monthlyRevenuePotential': 10000 + _random.nextDouble() * 90000,
          'adoptionRate': 0.05 + _random.nextDouble() * 0.15,
          'marginPercent': 0.6 + _random.nextDouble() * 0.3,
        },
        requirements: List<String>.from(template['requirements'] ?? []),
        createdAt: DateTime.now(),
      );

      prototypes.add(prototype);

      // Save to Firestore
      await _monetizationPrototypesCollection.doc(prototype.id).set(prototype.toMap());

      // Emit event
      _monetizationPrototypeController.add(prototype);
    }

    debugPrint('âœ… [FutureModesService] Created ${prototypes.length} monetization prototypes');
    return prototypes;
  }

  List<Map<String, dynamic>> _getMonetizationTemplates() {
    return [
      {
        'name': 'Creator Subscriptions',
        'description': 'Monthly subscriptions to individual creators with tiered benefits',
        'type': 'subscription',
        'revenueModel': {
          'platformFee': 0.20,
          'creatorShare': 0.80,
          'billingCycle': 'monthly',
        },
        'pricingTiers': {
          'supporter': 4.99,
          'superfan': 9.99,
          'vip': 24.99,
        },
        'requirements': ['payment_processor', 'creator_verification'],
      },
      {
        'name': 'Virtual Gift Economy',
        'description': 'Purchasable virtual gifts with animated effects',
        'type': 'virtualGoods',
        'revenueModel': {
          'platformFee': 0.30,
          'creatorShare': 0.70,
          'refundable': false,
        },
        'pricingTiers': {
          'basic_gifts': {'range': [0.99, 4.99]},
          'premium_gifts': {'range': [9.99, 49.99]},
          'legendary_gifts': {'range': [99.99, 499.99]},
        },
        'requirements': ['gift_catalog', 'animation_system'],
      },
      {
        'name': 'Room Sponsorship',
        'description': 'Brand sponsorship of popular rooms and events',
        'type': 'sponsorship',
        'revenueModel': {
          'platformFee': 0.25,
          'creatorShare': 0.75,
          'minimumCommitment': 'weekly',
        },
        'pricingTiers': {
          'bronze': 500,
          'silver': 2000,
          'gold': 5000,
          'platinum': 15000,
        },
        'requirements': ['brand_portal', 'analytics_integration', 'compliance_review'],
      },
      {
        'name': 'Creator Marketplace',
        'description': 'Platform for creators to sell digital products',
        'type': 'marketplace',
        'revenueModel': {
          'transactionFee': 0.10,
          'listingFee': 0,
          'withdrawalFee': 0.02,
        },
        'pricingTiers': {
          'digital_downloads': {'range': [0.99, 99.99]},
          'courses': {'range': [9.99, 499.99]},
          'services': {'range': [19.99, 999.99]},
        },
        'requirements': ['file_hosting', 'drm_system', 'dispute_resolution'],
      },
      {
        'name': 'Premium Events',
        'description': 'Ticketed exclusive events and experiences',
        'type': 'transaction',
        'revenueModel': {
          'platformFee': 0.15,
          'creatorShare': 0.85,
          'refundPolicy': 'flexible',
        },
        'pricingTiers': {
          'general_admission': {'range': [4.99, 29.99]},
          'premium_access': {'range': [29.99, 99.99]},
          'vip_experience': {'range': [99.99, 499.99]},
        },
        'requirements': ['ticketing_system', 'capacity_management', 'refund_processing'],
      },
    ];
  }

  // ============================================================
  // PROTOTYPE MANAGEMENT
  // ============================================================

  /// Get all prototypes by type
  Future<List<RoomModePrototype>> getRoomModePrototypes({
    PrototypeStatus? status,
  }) async {
    var query = _roomModePrototypesCollection.orderBy('createdAt', descending: true);

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return RoomModePrototype(
        id: data['id'] as String,
        name: data['name'] as String,
        description: data['description'] as String,
        conceptArt: data['conceptArt'] as String? ?? '',
        status: PrototypeStatus.values.firstWhere((s) => s.name == data['status']),
        targetAudience: List<String>.from(data['targetAudience'] ?? []),
        featureSpec: (data['featureSpec'] as Map<String, dynamic>?) ?? {},
        metrics: (data['metrics'] as Map<String, dynamic>?) ?? {},
        feedback: [],
        createdAt: DateTime.parse(data['createdAt'] as String),
        launchedAt: data['launchedAt'] != null ? DateTime.parse(data['launchedAt'] as String) : null,
      );
    }).toList();
  }

  /// Update prototype status
  Future<bool> updatePrototypeStatus(
    String prototypeId,
    PrototypeStatus newStatus, {
    String? collection,
  }) async {
    try {
      final collectionRef = collection == 'interaction'
          ? _interactionPrototypesCollection
          : collection == 'monetization'
              ? _monetizationPrototypesCollection
              : _roomModePrototypesCollection;

      await collectionRef.doc(prototypeId).update({
        'status': newStatus.name,
        if (newStatus == PrototypeStatus.launched) 'launchedAt': DateTime.now().toIso8601String(),
      });

      debugPrint('âœ… [FutureModesService] Updated prototype status: $prototypeId -> ${newStatus.name}');
      return true;
    } catch (e) {
      debugPrint('âŒ [FutureModesService] Failed to update prototype status: $e');
      return false;
    }
  }

  /// Add feedback to prototype
  Future<bool> addPrototypeFeedback(
    String prototypeId,
    PrototypeFeedback feedback,
  ) async {
    try {
      await _roomModePrototypesCollection.doc(prototypeId).update({
        'feedback': FieldValue.arrayUnion([feedback.toMap()]),
      });

      debugPrint('âœ… [FutureModesService] Added feedback to prototype: $prototypeId');
      return true;
    } catch (e) {
      debugPrint('âŒ [FutureModesService] Failed to add feedback: $e');
      return false;
    }
  }

  /// Launch prototype as official feature
  Future<bool> launchPrototype(String prototypeId) async {
    try {
      // Get prototype data
      final doc = await _roomModePrototypesCollection.doc(prototypeId).get();
      if (!doc.exists) return false;

      final data = doc.data()!;

      // Register as official room mode
      await ExtensionAPI.instance.registerRoomMode(
        id: prototypeId.replaceFirst('proto_room_', ''),
        name: data['name'] as String,
        description: data['description'] as String,
        features: List<String>.from((data['featureSpec'] as Map<String, dynamic>).keys),
      );

      // Update prototype status
      await updatePrototypeStatus(prototypeId, PrototypeStatus.launched);

      // Track analytics
      AnalyticsService.instance.logEvent(name: 'prototype_launched', parameters: {
        'prototype_id': prototypeId,
        'name': data['name'],
      });

      debugPrint('ðŸš€ [FutureModesService] Launched prototype: ${data['name']}');
      return true;
    } catch (e) {
      debugPrint('âŒ [FutureModesService] Failed to launch prototype: $e');
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _roomModePrototypeController.close();
    _interactionPrototypeController.close();
    _monetizationPrototypeController.close();
  }
}
