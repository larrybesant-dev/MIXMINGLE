/// Firestore Room Presence Service
///
/// Specialized service for:
/// - Participant presence (arrival/departure)
/// - Speaking state tracking
/// - Real-time room updates
/// - Energy level calculations
/// Reference: DESIGN_BIBLE.md Section G.3 (Firestore Schema)
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../shared/models/participant.dart';

/// Exception thrown when Firestore room operation fails
class RoomFirestoreException implements Exception {
  final String message;
  final Object? originalError;

  RoomFirestoreException(this.message, [this.originalError]);

  @override
  String toString() => 'RoomFirestoreException: $message';
}

/// Firestore service for room presence, speaking state, and energy tracking
class RoomFirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Collection path for rooms
  static const String roomsCollection = 'rooms';

  /// Subcollection path for room members/participants
  static const String membersSubcollection = 'members';

  /// Stream of participants in a room
  /// Emits list when presence changes
  Stream<List<Participant>> participantsStream(String roomId) {
    try {
      return _firestore
          .collection(roomsCollection)
          .doc(roomId)
          .collection(membersSubcollection)
          .orderBy('joinedAt', descending: false)
          .snapshots()
          .map((snapshot) {
            if (kDebugMode) {
              print('[Room Presence] Update: ${snapshot.docs.length} members');
            }
            return snapshot.docs
                .map((doc) => Participant.fromFirestore(doc.id, doc.data()))
                .toList();
          });
    } catch (e) {
      if (kDebugMode) print('[Room Presence] Stream error: $e');
      throw RoomFirestoreException(
        'Failed to stream participants for room: $roomId',
        e,
      );
    }
  }

  /// Update participant presence and speaking state
  Future<void> updateParticipant(
    String roomId,
    Participant participant,
  ) async {
    try {
      await _firestore
          .collection(roomsCollection)
          .doc(roomId)
          .collection(membersSubcollection)
          .doc(participant.uid)
          .set(participant.toFirestore(), SetOptions(merge: true));

      if (kDebugMode) {
        print('[Room Presence] Updated: ${participant.name} '
            '(speaking=${participant.isSpeaking}, present=${participant.isPresent})');
      }
    } catch (e) {
      if (kDebugMode) print('[Room Presence] Update failed: $e');
      throw RoomFirestoreException(
        'Failed to update participant ${participant.uid}',
        e,
      );
    }
  }

  /// Remove participant from room (on leave/disconnect)
  Future<void> removeParticipant(String roomId, String uid) async {
    try {
      await _firestore
          .collection(roomsCollection)
          .doc(roomId)
          .collection(membersSubcollection)
          .doc(uid)
          .delete();

      if (kDebugMode) print('[Room Presence] Removed: $uid');
    } catch (e) {
      if (kDebugMode) print('[Room Presence] Remove failed: $e');
      throw RoomFirestoreException('Failed to remove participant $uid', e);
    }
  }

  /// Get all participants in room (one-time fetch)
  Future<List<Participant>> getParticipants(String roomId) async {
    try {
      final snapshot = await _firestore
          .collection(roomsCollection)
          .doc(roomId)
          .collection(membersSubcollection)
          .get();

      final participants = snapshot.docs
          .map((doc) => Participant.fromFirestore(doc.id, doc.data()))
          .toList();

      if (kDebugMode) {
        print('[Room Presence] Fetched ${participants.length} participants');
      }

      return participants;
    } catch (e) {
      if (kDebugMode) print('[Room Presence] Fetch failed: $e');
      throw RoomFirestoreException(
        'Failed to fetch participants for room: $roomId',
        e,
      );
    }
  }

  /// Update room energy level (from presence + speaking + activity)
  /// Called when room state changes
  Future<void> updateRoomEnergy(String roomId, double energy) async {
    try {
      await _firestore.collection(roomsCollection).doc(roomId).update({
        'energy': energy,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) print('[Room Presence] Energy updated: $energy');
    } catch (e) {
      if (kDebugMode) print('[Room Presence] Energy update failed: $e');
      // Don't throw; energy is secondary
    }
  }

  /// Cleanup: remove user from all rooms they're in
  /// Optimized to only query rooms where user is a participant
  Future<void> cleanupUserPresence(String uid) async {
    try {
      // Query only rooms where user is a participant
      final rooms = await _firestore
          .collection(roomsCollection)
          .where('participantIds', arrayContains: uid)
          .limit(100)
          .get();
      for (final roomDoc in rooms.docs) {
        await removeParticipant(roomDoc.id, uid);
      }
      if (kDebugMode) print('[Room Presence] Cleaned up user from ${rooms.docs.length} rooms: $uid');
    } catch (e) {
      if (kDebugMode) print('[Room Presence] Cleanup failed: $e');
      // Best-effort cleanup
    }
  }
}




