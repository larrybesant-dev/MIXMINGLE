/// Live Event Model
///
/// Defines the data model for live operations events including
/// daily/weekly events, limited time offers, and room themes.
library;

import 'package:cloud_firestore/cloud_firestore.dart';

/// Types of live events that can be scheduled
enum LiveEventType {
  dailyChallenge,
  weeklyContest,
  limitedOffer,
  roomTheme,
  creatorSpotlight,
  communityEvent,
  holidayEvent,
  flashSale,
  doubleCoins,
  vipTrial,
  weekendBoost,
}

/// Status of a live event
enum LiveEventStatus {
  scheduled,
  active,
  completed,
  cancelled,
}

/// Priority level for events
enum EventPriority {
  low,
  normal,
  high,
  critical,
}

/// Model representing a live operations event
class LiveEvent {
  final String id;
  final LiveEventType type;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final LiveEventStatus status;
  final EventPriority priority;
  final Map<String, dynamic> metadata;
  final List<String> targetAudience;
  final String? imageUrl;
  final String? deepLink;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const LiveEvent({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.priority = EventPriority.normal,
    this.metadata = const {},
    this.targetAudience = const [],
    this.imageUrl,
    this.deepLink,
    required this.createdAt,
    this.updatedAt,
  });

  /// Create from Firestore document
  factory LiveEvent.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return LiveEvent(
      id: doc.id,
      type: LiveEventType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => LiveEventType.communityEvent,
      ),
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      status: LiveEventStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => LiveEventStatus.scheduled,
      ),
      priority: EventPriority.values.firstWhere(
        (p) => p.name == data['priority'],
        orElse: () => EventPriority.normal,
      ),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      targetAudience: List<String>.from(data['targetAudience'] ?? []),
      imageUrl: data['imageUrl'],
      deepLink: data['deepLink'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() => {
    'type': type.name,
    'title': title,
    'description': description,
    'startTime': Timestamp.fromDate(startTime),
    'endTime': Timestamp.fromDate(endTime),
    'status': status.name,
    'priority': priority.name,
    'metadata': metadata,
    'targetAudience': targetAudience,
    'imageUrl': imageUrl,
    'deepLink': deepLink,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
  };

  /// Check if event is currently active
  bool get isActive {
    final now = DateTime.now();
    return status == LiveEventStatus.active &&
        now.isAfter(startTime) &&
        now.isBefore(endTime);
  }

  /// Check if event is upcoming
  bool get isUpcoming {
    final now = DateTime.now();
    return status == LiveEventStatus.scheduled && now.isBefore(startTime);
  }

  /// Get duration of the event
  Duration get duration => endTime.difference(startTime);

  /// Get remaining time until event starts
  Duration get timeUntilStart => startTime.difference(DateTime.now());

  /// Get remaining time until event ends
  Duration get timeRemaining => endTime.difference(DateTime.now());

  /// Copy with modifications
  LiveEvent copyWith({
    String? id,
    LiveEventType? type,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    LiveEventStatus? status,
    EventPriority? priority,
    Map<String, dynamic>? metadata,
    List<String>? targetAudience,
    String? imageUrl,
    String? deepLink,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LiveEvent(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      metadata: metadata ?? this.metadata,
      targetAudience: targetAudience ?? this.targetAudience,
      imageUrl: imageUrl ?? this.imageUrl,
      deepLink: deepLink ?? this.deepLink,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'LiveEvent($id, $type, $title, $status)';
}

/// Model for limited time offers
class LimitedTimeOffer {
  final String id;
  final String title;
  final String description;
  final double originalPrice;
  final double discountedPrice;
  final int discountPercent;
  final String productId;
  final DateTime startTime;
  final DateTime endTime;
  final int? maxRedemptions;
  final int currentRedemptions;
  final List<String> eligibleTiers;
  final String? imageUrl;

  const LimitedTimeOffer({
    required this.id,
    required this.title,
    required this.description,
    required this.originalPrice,
    required this.discountedPrice,
    required this.discountPercent,
    required this.productId,
    required this.startTime,
    required this.endTime,
    this.maxRedemptions,
    this.currentRedemptions = 0,
    this.eligibleTiers = const [],
    this.imageUrl,
  });

  bool get isAvailable {
    final now = DateTime.now();
    final withinTime = now.isAfter(startTime) && now.isBefore(endTime);
    final underLimit = maxRedemptions == null || currentRedemptions < maxRedemptions!;
    return withinTime && underLimit;
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'originalPrice': originalPrice,
    'discountedPrice': discountedPrice,
    'discountPercent': discountPercent,
    'productId': productId,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'maxRedemptions': maxRedemptions,
    'currentRedemptions': currentRedemptions,
    'eligibleTiers': eligibleTiers,
    'imageUrl': imageUrl,
  };
}

/// Model for room theme rotation
class RoomTheme {
  final String id;
  final String name;
  final String description;
  final String primaryColor;
  final String secondaryColor;
  final String? backgroundImageUrl;
  final String? iconUrl;
  final Map<String, String> decorations;
  final DateTime activeFrom;
  final DateTime activeTo;

  const RoomTheme({
    required this.id,
    required this.name,
    required this.description,
    required this.primaryColor,
    required this.secondaryColor,
    this.backgroundImageUrl,
    this.iconUrl,
    this.decorations = const {},
    required this.activeFrom,
    required this.activeTo,
  });

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(activeFrom) && now.isBefore(activeTo);
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'primaryColor': primaryColor,
    'secondaryColor': secondaryColor,
    'backgroundImageUrl': backgroundImageUrl,
    'iconUrl': iconUrl,
    'decorations': decorations,
    'activeFrom': activeFrom.toIso8601String(),
    'activeTo': activeTo.toIso8601String(),
  };
}

/// Model for creator spotlights
class CreatorSpotlight {
  final String id;
  final String creatorId;
  final String creatorName;
  final String? creatorAvatar;
  final String spotlightTitle;
  final String spotlightDescription;
  final DateTime featuredFrom;
  final DateTime featuredTo;
  final int position;
  final Map<String, int> stats;

  const CreatorSpotlight({
    required this.id,
    required this.creatorId,
    required this.creatorName,
    this.creatorAvatar,
    required this.spotlightTitle,
    required this.spotlightDescription,
    required this.featuredFrom,
    required this.featuredTo,
    this.position = 0,
    this.stats = const {},
  });

  bool get isFeatured {
    final now = DateTime.now();
    return now.isAfter(featuredFrom) && now.isBefore(featuredTo);
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'creatorId': creatorId,
    'creatorName': creatorName,
    'creatorAvatar': creatorAvatar,
    'spotlightTitle': spotlightTitle,
    'spotlightDescription': spotlightDescription,
    'featuredFrom': featuredFrom.toIso8601String(),
    'featuredTo': featuredTo.toIso8601String(),
    'position': position,
    'stats': stats,
  };
}


