// lib/services/social/discovery_service.dart
//
// DiscoveryService – Firestore snapshot-backed discovery queries.
// All four methods return live Streams.  No polling, no Stream.periodic.
//
// Collections used:
//   users/       – profile data, ordered by followersCount
//   presence/    – online/away state written by PresenceService
//   rooms/       – public active rooms, ordered by viewerCount

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_profile.dart';
import '../../shared/models/room.dart';

class DiscoveryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── Suggested Users ──────────────────────────────────────────────────────

  /// Streams [limit] users the current user hasn't followed yet,
  /// ranked by follower count.  Excludes blocked users (self + following).
  /// Uses [asyncMap] to read the following sub-collection once per snapshot.
  Stream<List<UserProfile>> streamSuggestedUsers({int limit = 20}) {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return Stream.value([]);

    return _db
        .collection('users')
        .orderBy('followersCount', descending: true)
        .limit(limit * 3) // over-fetch to have room after exclusions
        .snapshots()
        .asyncMap((snap) async {
          final followingSnap = await _db
              .collection('users')
              .doc(currentUserId)
              .collection('following')
              .get();

          final excludeIds = <String>{
            currentUserId,
            ...followingSnap.docs.map((d) => d.id),
          };

          final results = <UserProfile>[];
          for (final doc in snap.docs) {
            if (excludeIds.contains(doc.id)) continue;
            final data = Map<String, dynamic>.from(doc.data());
            try {
              results.add(UserProfile.fromMap(data, doc.id));
            } catch (_) {}
            if (results.length >= limit) break;
          }
          return results;
        });
  }

  // ── Trending Users ───────────────────────────────────────────────────────

  /// Streams the top [limit] users ranked by follower count descending.
  Stream<List<UserProfile>> streamTrendingUsers({int limit = 20}) {
    return _db
        .collection('users')
        .orderBy('followersCount', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) {
          final results = <UserProfile>[];
          for (final doc in snap.docs) {
            final data = Map<String, dynamic>.from(doc.data());
            try {
              results.add(UserProfile.fromMap(data, doc.id));
            } catch (_) {}
          }
          return results;
        });
  }

  // ── Active Now Users ─────────────────────────────────────────────────────

  /// Streams up to [limit] users currently online or away.
  /// Reads `presence` for live state, then batch-fetches their `users` docs.
  Stream<List<UserProfile>> streamActiveNowUsers({int limit = 30}) {
    return _db
        .collection('presence')
        .where('state', whereIn: ['online', 'away'])
        .limit(limit)
        .snapshots()
        .asyncMap((snap) async {
          final userIds = snap.docs.map((d) => d.id).toList();
          if (userIds.isEmpty) return <UserProfile>[];

          // Firestore whereIn supports up to 30 values; limit handles cap above
          final usersSnap = await _db
              .collection('users')
              .where(FieldPath.documentId, whereIn: userIds)
              .get();

          final results = <UserProfile>[];
          for (final doc in usersSnap.docs) {
            final data = Map<String, dynamic>.from(doc.data());
            data['id'] = doc.id;
            try {
              results.add(UserProfile.fromMap(data));
            } catch (_) {}
          }
          return results;
        });
  }

  // ── Discoverable Rooms ───────────────────────────────────────────────────

  /// Streams public, active rooms ordered by viewer count descending.
  Stream<List<Room>> streamDiscoverableRooms({int limit = 20}) {
    return _db
        .collection('rooms')
        .where('privacy', isEqualTo: 'public')
        .where('isActive', isEqualTo: true)
        .orderBy('viewerCount', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) {
          final results = <Room>[];
          for (final doc in snap.docs) {
            final data = Map<String, dynamic>.from(doc.data());
            data['id'] = doc.id;
            try {
              results.add(Room.fromJson(data));
            } catch (_) {}
          }
          return results;
        });
  }
}
