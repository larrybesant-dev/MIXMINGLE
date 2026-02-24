import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../shared/models/camera_state.dart';
import '../../shared/models/camera_quality.dart';

class CameraService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Toggle user's camera on/off
  Future<void> toggleCamera(String roomId, bool enable) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('Not authenticated');

    try {
      await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('participants')
          .doc(userId)
          .update({
        'isCameraOn': enable,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (enable) {
        await _firestore
            .collection('rooms')
            .doc(roomId)
            .collection('camera')
            .doc(userId)
            .set({
          'isLive': true,
          'startedAt': FieldValue.serverTimestamp(),
          'quality': 'high',
          'status': 'active',
          'viewCount': 0,
          'isSpotlighted': false,
        });
      } else {
        await _firestore
            .collection('rooms')
            .doc(roomId)
            .collection('camera')
            .doc(userId)
            .delete();
      }
      debugPrint('âœ… Camera toggled: $enable');
    } catch (e) {
      debugPrint('âŒ Failed to toggle camera: $e');
      rethrow;
    }
  }

  /// Set camera quality (low/medium/high)
  Future<void> setCameraQuality(String roomId, CameraQuality quality) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('Not authenticated');

    try {
      final settings = CameraQualitySettings.forQuality(quality);

      await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('camera')
          .doc(userId)
          .update({
        'quality': quality.name,
        'resolution': settings.resolution,
        'bitrate': settings.bitrate,
        'fps': settings.fps,
      });
      debugPrint('âœ… Camera quality set to: ${quality.name}');
    } catch (e) {
      debugPrint('âŒ Failed to set camera quality: $e');
      rethrow;
    }
  }

  /// Spotlight a camera (host/moderator only)
  Future<void> spotlightCamera(String roomId, String targetUid) async {
    try {
      final roomRef = _firestore.collection('rooms').doc(roomId);

      // Remove current spotlight
      final spotlightQuery = await roomRef
          .collection('camera')
          .where('isSpotlighted', isEqualTo: true)
          .get();

      for (var doc in spotlightQuery.docs) {
        await doc.reference.update({'isSpotlighted': false});
      }

      // Apply new spotlight
      await roomRef
          .collection('camera')
          .doc(targetUid)
          .update({'isSpotlighted': true});

      debugPrint('âœ… Camera spotlighted: $targetUid');
    } catch (e) {
      debugPrint('âŒ Failed to spotlight camera: $e');
      rethrow;
    }
  }

  /// Remove spotlight
  Future<void> removeSpotlight(String roomId) async {
    try {
      final spotlightQuery = await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('camera')
          .where('isSpotlighted', isEqualTo: true)
          .get();

      for (var doc in spotlightQuery.docs) {
        await doc.reference.update({'isSpotlighted': false});
      }

      debugPrint('âœ… Spotlight removed');
    } catch (e) {
      debugPrint('âŒ Failed to remove spotlight: $e');
      rethrow;
    }
  }

  /// Get active cameras in room
  Stream<List<CameraState>> streamActiveCameras(String roomId) {
    return _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('camera')
        .where('isLive', isEqualTo: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final cameras = <CameraState>[];

      for (var doc in snapshot.docs) {
        try {
          final participantDoc = await _firestore
              .collection('rooms')
              .doc(roomId)
              .collection('participants')
              .doc(doc.id)
              .get();

          if (participantDoc.exists) {
            // âœ… SAFETY FIX: Use optional chaining instead of force unwrap
            final data = participantDoc.data();
            if (data != null) {
              cameras.add(CameraState(
                uid: doc.id,
                isLive: true,
                quality: _parseQuality(doc['quality'] as String?),
                status: CameraStatus.active,
                viewCount: doc['viewCount'] ?? 0,
                isFrozen: _isFrozen(doc['lastFrameAt'] as Timestamp?),
                isSpotlighted: doc['isSpotlighted'] ?? false,
                startedAt: (doc['startedAt'] as Timestamp?)?.toDate() ??
                    DateTime.now(),
                userName: data['displayName'] ?? 'User',
                userPhotoUrl: data['photoUrl'],
                isVIP: data['isVIP'] ?? false,
                isBroadcaster: data['isBroadcaster'] ?? false,
              ));
            }
          }
        } catch (e) {
          debugPrint('âš ï¸ Error loading camera $doc.id: $e');
        }
      }

      // Sort: spotlighted first, then VIP, then broadcasters
      cameras.sort((a, b) {
        if (a.isSpotlighted) return -1;
        if (b.isSpotlighted) return 1;
        if (a.isVIP && !b.isVIP) return -1;
        if (b.isVIP && !a.isVIP) return 1;
        if (a.isBroadcaster && !b.isBroadcaster) return -1;
        return 1;
      });

      return cameras;
    });
  }

  /// Detect if camera is frozen
  bool _isFrozen(Timestamp? lastFrameAt) {
    if (lastFrameAt == null) return false;
    final secondsSinceLastFrame =
        DateTime.now().difference(lastFrameAt.toDate()).inSeconds;
    return secondsSinceLastFrame > 10; // Frozen if no frame in 10s
  }

  /// Parse quality string
  CameraQuality _parseQuality(String? quality) {
    return switch (quality?.toLowerCase()) {
      'low' => CameraQuality.low,
      'medium' || 'med' => CameraQuality.medium,
      _ => CameraQuality.high,
    };
  }

  /// Enforce max camera limit
  Future<void> enforceMaxCameraLimit(String roomId, int maxCams) async {
    try {
      final snapshot = await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('camera')
          .where('isLive', isEqualTo: true)
          .orderBy('startedAt', descending: false)
          .get();

      if (snapshot.docs.length > maxCams) {
        // Remove oldest cameras
        final toRemove = snapshot.docs.length - maxCams;
        for (int i = 0; i < toRemove; i++) {
          await snapshot.docs[i].reference.delete();
        }
        debugPrint('âš ï¸ Removed $toRemove cameras to enforce limit');
      }
    } catch (e) {
      debugPrint('âŒ Failed to enforce camera limit: $e');
    }
  }

  /// Get camera count
  Future<int> getActiveCameraCount(String roomId) async {
    try {
      final snapshot = await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('camera')
          .where('isLive', isEqualTo: true)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      debugPrint('âŒ Failed to get camera count: $e');
      return 0;
    }
  }

  /// Increment view count
  Future<void> incrementViewCount(String roomId, String cameraUid) async {
    try {
      await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('camera')
          .doc(cameraUid)
          .update({
        'viewCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('âš ï¸ Failed to increment view count: $e');
    }
  }
}
