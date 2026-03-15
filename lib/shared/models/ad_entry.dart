// lib/shared/models/ad_entry.dart
//
// A single ad creative served in the app.
// Firestore path: /ads/{adId}

import 'package:cloud_firestore/cloud_firestore.dart';

enum AdType { tile, banner, fullscreen }
enum AdPlacement { discover, feed, profile, rooms }

class AdEntry {
  final String id;
  final String advertiserId;
  final AdType type;
  final String imageUrl;
  final String linkUrl;
  final List<AdPlacement> placements;
  final int weight; // higher = served more often
  final bool active;
  final bool ageRestricted;
  final String? headline;
  final String? ctaLabel; // e.g. "Shop Now"
  final int impressionCount;
  final int clickCount;
  final DateTime createdAt;

  const AdEntry({
    required this.id,
    required this.advertiserId,
    required this.type,
    required this.imageUrl,
    required this.linkUrl,
    required this.placements,
    this.weight = 1,
    required this.active,
    this.ageRestricted = false,
    this.headline,
    this.ctaLabel,
    this.impressionCount = 0,
    this.clickCount = 0,
    required this.createdAt,
  });

  // ── Firestore ─────────────────────────────────────────────────────────────

  factory AdEntry.fromMap(String id, Map<String, dynamic> data) {
    return AdEntry(
      id: id,
      advertiserId: data['advertiserId'] as String? ?? '',
      type: _parseType(data['type'] as String?),
      imageUrl: data['imageUrl'] as String? ?? '',
      linkUrl: data['linkUrl'] as String? ?? '',
      placements: _parsePlacements(data['placement']),
      weight: data['weight'] as int? ?? 1,
      active: data['active'] as bool? ?? false,
      ageRestricted: data['ageRestricted'] as bool? ?? false,
      headline: data['headline'] as String?,
      ctaLabel: data['ctaLabel'] as String?,
      impressionCount: data['impressionCount'] as int? ?? 0,
      clickCount: data['clickCount'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory AdEntry.fromDoc(DocumentSnapshot doc) =>
      AdEntry.fromMap(doc.id, doc.data() as Map<String, dynamic>? ?? {});

  Map<String, dynamic> toMap() => {
        'advertiserId': advertiserId,
        'type': type.name,
        'imageUrl': imageUrl,
        'linkUrl': linkUrl,
        'placement': placements.map((p) => p.name).toList(),
        'weight': weight,
        'active': active,
        'ageRestricted': ageRestricted,
        'headline': headline,
        'ctaLabel': ctaLabel,
        'impressionCount': impressionCount,
        'clickCount': clickCount,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  // ── Helpers ───────────────────────────────────────────────────────────────

  static AdType _parseType(String? v) {
    switch (v) {
      case 'banner':
        return AdType.banner;
      case 'fullscreen':
        return AdType.fullscreen;
      default:
        return AdType.tile;
    }
  }

  static List<AdPlacement> _parsePlacements(dynamic raw) {
    if (raw == null) return [];
    final list = raw is List ? raw : [raw];
    return list.map((e) {
      switch (e as String?) {
        case 'feed':
          return AdPlacement.feed;
        case 'profile':
          return AdPlacement.profile;
        case 'rooms':
          return AdPlacement.rooms;
        default:
          return AdPlacement.discover;
      }
    }).toList();
  }
}
