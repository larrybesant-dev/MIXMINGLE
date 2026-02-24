import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../shared/models/mic_state.dart';

class MicService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Request mic access (join mic queue)
  Future<void> requestMic(String roomId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('Not authenticated');

    try {
      final now = DateTime.now();
      await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('micQueue')
          .doc(userId)
          .set({
        'userId': userId,
        'status': 'pending',
        'requestedAt': now,
        'queuePosition': now.millisecondsSinceEpoch,
        'isMuted': true,
        'quality': 'high',
        'noiseLevel': 0,
        'gainLevel': 50,
      });

      debugPrint('âœ… Mic requested for room: $roomId');
    } catch (e) {
      debugPrint('âŒ Failed to request mic: $e');
      rethrow;
    }
  }

  /// Cancel mic request
  Future<void> cancelMicRequest(String roomId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('Not authenticated');

    try {
      await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('micQueue')
          .doc(userId)
          .delete();

      debugPrint('âœ… Mic request cancelled');
    } catch (e) {
      debugPrint('âŒ Failed to cancel mic request: $e');
      rethrow;
    }
  }

  /// Approve user's mic (moderator only)
  Future<void> approveMic(String roomId, String userId) async {
    try {
      await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('micQueue')
          .doc(userId)
          .update({
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('âœ… Mic approved for user: $userId');
    } catch (e) {
      debugPrint('âŒ Failed to approve mic: $e');
      rethrow;
    }
  }

  /// Revoke user's mic
  Future<void> revokeMic(String roomId, String userId) async {
    try {
      await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('micQueue')
          .doc(userId)
          .delete();

      debugPrint('âœ… Mic revoked for user: $userId');
    } catch (e) {
      debugPrint('âŒ Failed to revoke mic: $e');
      rethrow;
    }
  }

  /// Toggle mute status
  Future<void> toggleMute(String roomId, bool mute) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('Not authenticated');

    try {
      await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('micQueue')
          .doc(userId)
          .update({'isMuted': mute});

      debugPrint('âœ… Mute toggled: $mute');
    } catch (e) {
      debugPrint('âŒ Failed to toggle mute: $e');
      rethrow;
    }
  }

  /// Set mic quality (low/medium/high)
  Future<void> setMicQuality(String roomId, MicQuality quality) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('Not authenticated');

    try {
      await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('micQueue')
          .doc(userId)
          .update({'quality': quality.name});

      debugPrint('âœ… Mic quality set to: ${quality.name}');
    } catch (e) {
      debugPrint('âŒ Failed to set mic quality: $e');
      rethrow;
    }
  }

  /// Update gain level (0-100)
  Future<void> setGainLevel(String roomId, int gainLevel) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('Not authenticated');

    try {
      await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('micQueue')
          .doc(userId)
          .update({'gainLevel': gainLevel.clamp(0, 100)});

      debugPrint('âœ… Gain level set to: $gainLevel');
    } catch (e) {
      debugPrint('âŒ Failed to set gain level: $e');
      rethrow;
    }
  }

  /// Set noise suppression level
  Future<void> setNoiseSuppressionLevel(
    String roomId,
    NoiseSuppressionSettings settings,
  ) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('Not authenticated');

    try {
      await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('micQueue')
          .doc(userId)
          .update({
        'noiseSuppression': {
          'enabled': settings.enabled,
          'threshold': settings.threshold,
          'reductionFactor': settings.reductionFactor,
        },
      });

      debugPrint('âœ… Noise suppression configured');
    } catch (e) {
      debugPrint('âŒ Failed to set noise suppression: $e');
      rethrow;
    }
  }

  /// Stream mic queue
  Stream<List<MicState>> streamMicQueue(String roomId) {
    return _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('micQueue')
        .snapshots()
        .asyncMap((snapshot) async {
      final mics = <MicState>[];

      for (var doc in snapshot.docs) {
        try {
          final participantDoc = await _firestore
              .collection('rooms')
              .doc(roomId)
              .collection('participants')
              .doc(doc.id)
              .get();

          if (participantDoc.exists) {
            final data = participantDoc.data()!;
            final status = (doc['status'] == 'approved' && !doc['isMuted'])
                ? MicStatus.active
                : (doc['status'] == 'approved'
                    ? MicStatus.muted
                    : MicStatus.inactive);

            mics.add(MicState(
              uid: doc.id,
              isActive: doc['status'] == 'approved',
              isMuted: doc['isMuted'] ?? true,
              status: status,
              quality: _parseMicQuality(doc['quality']),
              noiseLevel: doc['noiseLevel'] ?? 0,
              gainLevel: doc['gainLevel'] ?? 50,
              prioritySpeaker: doc['prioritySpeaker'] ?? false,
              queuePosition: doc['queuePosition'] ?? 0,
              approvedAt: (doc['approvedAt'] as Timestamp?)?.toDate(),
              userName: data['displayName'] ?? 'User',
              userPhotoUrl: data['photoUrl'],
              isVIP: data['isVIP'] ?? false,
              isBroadcaster: data['isBroadcaster'] ?? false,
            ));
          }
        } catch (e) {
          debugPrint('âš ï¸ Error loading mic state for ${doc.id}: $e');
        }
      }

      // Sort: speaking first, then muted, then inactive
      mics.sort((a, b) {
        if (a.status == MicStatus.active && b.status != MicStatus.active) {
          return -1;
        }
        if (b.status == MicStatus.active && a.status != MicStatus.active) {
          return 1;
        }
        if (a.status == MicStatus.muted && b.status != MicStatus.muted) {
          return -1;
        }
        if (b.status == MicStatus.muted && a.status != MicStatus.muted) {
          return 1;
        }
        return 0;
      });

      return mics;
    });
  }

  /// Get active mic count
  Future<int> getActiveMicCount(String roomId) async {
    try {
      final snapshot = await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('micQueue')
          .where('status', isEqualTo: 'approved')
          .get();

      return snapshot.docs.length;
    } catch (e) {
      debugPrint('âŒ Failed to get mic count: $e');
      return 0;
    }
  }

  /// Get pending mic requests count
  Future<int> getPendingMicCount(String roomId) async {
    try {
      final snapshot = await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('micQueue')
          .where('status', isEqualTo: 'pending')
          .get();

      return snapshot.docs.length;
    } catch (e) {
      debugPrint('âŒ Failed to get pending mic count: $e');
      return 0;
    }
  }

  MicQuality _parseMicQuality(String? quality) {
    return switch (quality?.toLowerCase()) {
      'low' => MicQuality.low,
      'medium' => MicQuality.medium,
      _ => MicQuality.high,
    };
  }
}
