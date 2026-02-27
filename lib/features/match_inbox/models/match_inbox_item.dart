// lib/features/match_inbox/models/match_inbox_item.dart
//
// Match Inbox data model.
//
// Firestore schema:
//   /users/{uid}/matches/{matchId}
//     matchedUserId  : String
//     timestamp      : Timestamp   — when the match was created
//     lastInteraction: Timestamp?  — last chat/interaction time
//     isNew          : bool        — true until user sees the match
//     source         : String      — 'speedDating' | 'discovery' | 'manual'
//     metadata       : Map         — extra data (roundId, score, etc.)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:cloud_firestore/cloud_firestore.dart';

/// Where the match was created from
enum MatchSource {
  speedDating,
  discovery,
  manual,
}

/// One entry in a user's match inbox
class MatchInboxItem {
  final String id;
  final String matchedUserId;
  final DateTime timestamp;
  final DateTime? lastInteraction;
  final bool isNew;
  final MatchSource source;
  final Map<String, dynamic> metadata;

  const MatchInboxItem({
    required this.id,
    required this.matchedUserId,
    required this.timestamp,
    this.lastInteraction,
    required this.isNew,
    required this.source,
    this.metadata = const {},
  });

  // ── Factories ──────────────────────────────────────────────────────────────

  factory MatchInboxItem.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return MatchInboxItem.fromMap(data, doc.id);
  }

  factory MatchInboxItem.fromMap(Map<String, dynamic> data, String id) {
    return MatchInboxItem(
      id: id,
      matchedUserId: data['matchedUserId'] as String? ?? '',
      timestamp: _parseTimestamp(data['timestamp']),
      lastInteraction: data['lastInteraction'] != null
          ? _parseTimestamp(data['lastInteraction'])
          : null,
      isNew: data['isNew'] as bool? ?? true,
      source: _parseSource(data['source'] as String?),
      metadata:
          Map<String, dynamic>.from(data['metadata'] as Map? ?? {}),
    );
  }

  // ── toMap ──────────────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      'matchedUserId': matchedUserId,
      'timestamp': Timestamp.fromDate(timestamp),
      if (lastInteraction != null)
        'lastInteraction': Timestamp.fromDate(lastInteraction!),
      'isNew': isNew,
      'source': source.name,
      'metadata': metadata,
    };
  }

  // ── copyWith ───────────────────────────────────────────────────────────────

  MatchInboxItem copyWith({
    String? id,
    String? matchedUserId,
    DateTime? timestamp,
    DateTime? lastInteraction,
    bool? isNew,
    MatchSource? source,
    Map<String, dynamic>? metadata,
  }) {
    return MatchInboxItem(
      id: id ?? this.id,
      matchedUserId: matchedUserId ?? this.matchedUserId,
      timestamp: timestamp ?? this.timestamp,
      lastInteraction: lastInteraction ?? this.lastInteraction,
      isNew: isNew ?? this.isNew,
      source: source ?? this.source,
      metadata: metadata ?? this.metadata,
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.now();
  }

  static MatchSource _parseSource(String? value) {
    switch (value) {
      case 'speedDating':
        return MatchSource.speedDating;
      case 'manual':
        return MatchSource.manual;
      default:
        return MatchSource.discovery;
    }
  }

  @override
  String toString() =>
      'MatchInboxItem(id: $id, matchedUserId: $matchedUserId, isNew: $isNew)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MatchInboxItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
