import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Unified search result type
enum SearchResultType { user, room, post, event }

/// A single search result that can represent any entity.
class SearchResult {
  final String id;
  final SearchResultType type;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final Map<String, dynamic> raw;

  const SearchResult({
    required this.id,
    required this.type,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.raw = const {},
  });
}

/// SearchService performs real-time Firestore prefix queries across
/// users, rooms, posts, and events using indexed `searchTokens` arrays
/// when available, with a graceful displayName/title prefix fallback.
class SearchService {
  static final SearchService _instance = SearchService._internal();
  factory SearchService() => _instance;
  SearchService._internal();

  static SearchService get instance => _instance;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Main search entry point ────────────────────────────────────────────────

  /// Search all entity types for [query]. Returns up to [limit] results
  /// per type (total up to 4×limit). Empty query returns empty list.
  Future<List<SearchResult>> search(String query, {int limit = 10}) async {
    if (query.trim().isEmpty) return [];
    final q = query.trim().toLowerCase();

    final results = await Future.wait([
      _searchUsers(q, limit: limit),
      _searchRooms(q, limit: limit),
      _searchPosts(q, limit: limit),
      _searchEvents(q, limit: limit),
    ]);

    return results.expand((r) => r).toList();
  }

  /// Search only users — useful for @-mention pickers.
  Future<List<SearchResult>> searchUsers(String query, {int limit = 20}) async {
    if (query.trim().isEmpty) return [];
    return _searchUsers(query.trim().toLowerCase(), limit: limit);
  }

  // ── Private per-collection search ─────────────────────────────────────────

  Future<List<SearchResult>> _searchUsers(String q, {required int limit}) async {
    try {
      // Firestore range query on displayNameLower for prefix matching
      final qs = await _db
          .collection('users')
          .where('displayNameLower', isGreaterThanOrEqualTo: q)
          .where('displayNameLower', isLessThan: '${q}z')
          .where('isBanned', isEqualTo: false)
          .limit(limit)
          .get();

      return qs.docs.map((doc) {
        final d = doc.data();
        return SearchResult(
          id: doc.id,
          type: SearchResultType.user,
          title: d['displayName'] ?? d['username'] ?? 'User',
          subtitle: d['bio'] ?? d['vibeTag'],
          imageUrl: d['photoUrl'] ?? d['avatarUrl'],
          raw: d,
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ [Search] users error: $e');
      return [];
    }
  }

  Future<List<SearchResult>> _searchRooms(String q, {required int limit}) async {
    try {
      final qs = await _db
          .collection('rooms')
          .where('titleLower', isGreaterThanOrEqualTo: q)
          .where('titleLower', isLessThan: '${q}z')
          .where('isActive', isEqualTo: true)
          .limit(limit)
          .get();

      return qs.docs.map((doc) {
        final d = doc.data();
        return SearchResult(
          id: doc.id,
          type: SearchResultType.room,
          title: d['title'] ?? d['name'] ?? 'Room',
          subtitle: '${d['participantCount'] ?? 0} listening',
          imageUrl: d['coverImageUrl'],
          raw: d,
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ [Search] rooms error: $e');
      return [];
    }
  }

  Future<List<SearchResult>> _searchPosts(String q, {required int limit}) async {
    try {
      // Posts don't have a canonical sortable field; search tags if present
      final qs = await _db
          .collection('posts')
          .where('tags', arrayContains: q)
          .where('isVisible', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return qs.docs.map((doc) {
        final d = doc.data();
        return SearchResult(
          id: doc.id,
          type: SearchResultType.post,
          title: d['content'] != null
              ? (d['content'] as String).length > 60
                  ? '${(d['content'] as String).substring(0, 60)}…'
                  : d['content'] as String
              : 'Post',
          subtitle: 'by ${d['userName'] ?? 'User'}',
          imageUrl: d['imageUrl'],
          raw: d,
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ [Search] posts error: $e');
      return [];
    }
  }

  Future<List<SearchResult>> _searchEvents(String q, {required int limit}) async {
    try {
      final qs = await _db
          .collection('events')
          .where('titleLower', isGreaterThanOrEqualTo: q)
          .where('titleLower', isLessThan: '${q}z')
          .orderBy('titleLower')
          .limit(limit)
          .get();

      return qs.docs.map((doc) {
        final d = doc.data();
        return SearchResult(
          id: doc.id,
          type: SearchResultType.event,
          title: d['title'] ?? 'Event',
          subtitle: d['description'] != null
              ? (d['description'] as String).length > 50
                  ? '${(d['description'] as String).substring(0, 50)}…'
                  : d['description'] as String
              : null,
          imageUrl: d['coverImage'] ?? d['imageUrl'],
          raw: d,
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ [Search] events error: $e');
      return [];
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Call this when a user creates/updates a profile to ensure their
  /// displayName is stored lowercase for the range-query search.
  Future<void> indexUser(String userId, String displayName) async {
    try {
      await _db.collection('users').doc(userId).update({
        'displayNameLower': displayName.toLowerCase(),
      });
    } catch (_) {}
  }

  /// Call this when a room is created to ensure range-query search works.
  Future<void> indexRoom(String roomId, String title) async {
    try {
      await _db.collection('rooms').doc(roomId).update({
        'titleLower': title.toLowerCase(),
      });
    } catch (_) {}
  }

  /// Call this when an event is created.
  Future<void> indexEvent(String eventId, String title) async {
    try {
      await _db.collection('events').doc(eventId).update({
        'titleLower': title.toLowerCase(),
      });
    } catch (_) {}
  }
}
