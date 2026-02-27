# 🎥 MODULE A: MULTI-CAM SYSTEM

## Complete Implementation Guide

**Status**: Ready to Build
**Priority**: P0 (Foundation)
**Est. Time**: 5-7 days
**LOC**: ~2,000

---

## 🎯 FEATURES

### Core Features

- ✅ Multi-camera grid (4-20 simultaneous cams)
- ✅ Dynamic responsive layout
- ✅ Spotlight mode (pin 1 camera)
- ✅ Camera quality selector (low/med/high)
- ✅ Frozen camera detection
- ✅ Camera count limit enforcement
- ✅ VIP camera priority (VIP cams appear first)
- ✅ View counter per camera
- ✅ Camera "on-air" indicators

### User Experience

- Toggle between grid view and spotlight
- Pinch-to-zoom in spotlight
- Camera preview before going live
- Quality indicator badges (📡 HD, 📶 SD)
- "Streaming Now" badge for each camera
- Empty camera placeholder while loading
- Smooth layout transitions

---

## 📂 FILE STRUCTURE

```
lib/
├── models/
│   ├── camera_state.dart          [NEW]
│   └── camera_quality.dart        [NEW]
│
├── services/
│   └── camera_service.dart        [NEW]
│
├── providers/
│   └── camera_providers.dart      [NEW]
│
└── features/room/
    ├── widgets/
    │   ├── camera_grid.dart       [NEW]
    │   ├── camera_tile.dart       [NEW]
    │   ├── spotlight_view.dart    [NEW]
    │   ├── camera_quality_selector.dart [NEW]
    │   ├── freeze_detector.dart   [NEW]
    │   └── cam_count_indicator.dart [NEW]
    │
    └── screens/
        └── room_page.dart         [MODIFY]
```

---

## 1️⃣ MODELS

### `camera_state.dart`

```dart
enum CameraQuality {
  low,      // 360p, 500 kbps
  medium,   // 720p, 1 mbps
  high,     // 1080p, 2 mbps
}

enum CameraStatus {
  inactive,    // Not streaming
  loading,     // Connecting
  active,      // Streaming
  frozen,      // Detected frozen
  error,       // Error state
}

class CameraState {
  final String uid;
  final bool isLive;
  final CameraQuality quality;
  final CameraStatus status;
  final int viewCount;
  final bool isFrozen;
  final bool isSpotlighted;
  final DateTime startedAt;

  // Paltalk-style metadata
  final String userName;
  final String? userPhotoUrl;
  final bool isVIP;
  final bool isBroadcaster;

  const CameraState({
    required this.uid,
    required this.isLive,
    required this.quality,
    required this.status,
    required this.viewCount,
    required this.isFrozen,
    required this.isSpotlighted,
    required this.startedAt,
    required this.userName,
    this.userPhotoUrl,
    required this.isVIP,
    required this.isBroadcaster,
  });

  // Uptime in seconds
  int get uptimeSeconds {
    return DateTime.now().difference(startedAt).inSeconds;
  }

  // Quality icon for display
  String get qualityIcon {
    switch (quality) {
      case CameraQuality.high:
        return '📡';  // HD
      case CameraQuality.medium:
        return '📶';  // SD
      case CameraQuality.low:
        return '📱';  // Mobile
    }
  }
}
```

### `camera_quality.dart`

```dart
class CameraQualitySettings {
  final CameraQuality quality;
  final int resolution;    // pixels (360, 720, 1080)
  final int fps;          // frames per second
  final int bitrate;      // kbps
  final int bandwidth;    // estimated MB/s

  const CameraQualitySettings._({
    required this.quality,
    required this.resolution,
    required this.fps,
    required this.bitrate,
    required this.bandwidth,
  });

  static const low = CameraQualitySettings._(
    quality: CameraQuality.low,
    resolution: 360,
    fps: 15,
    bitrate: 500,
    bandwidth: 1,
  );

  static const medium = CameraQualitySettings._(
    quality: CameraQuality.medium,
    resolution: 720,
    fps: 24,
    bitrate: 1000,
    bandwidth: 2,
  );

  static const high = CameraQualitySettings._(
    quality: CameraQuality.high,
    resolution: 1080,
    fps: 30,
    bitrate: 2000,
    bandwidth: 4,
  );

  static CameraQualitySettings forQuality(CameraQuality quality) {
    return switch (quality) {
      CameraQuality.low => low,
      CameraQuality.medium => medium,
      CameraQuality.high => high,
    };
  }
}
```

---

## 2️⃣ SERVICE

### `camera_service.dart`

```dart
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
        });
      } else {
        await _firestore
            .collection('rooms')
            .doc(roomId)
            .collection('camera')
            .doc(userId)
            .delete();
      }
    } catch (e) {
      debugPrint('❌ Failed to toggle camera: $e');
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
    } catch (e) {
      debugPrint('❌ Failed to set camera quality: $e');
      rethrow;
    }
  }

  /// Spotlight a camera (host only)
  Future<void> spotlightCamera(String roomId, String targetUid) async {
    try {
      final roomRef = _firestore.collection('rooms').doc(roomId);

      // Remove current spotlight
      await roomRef
          .collection('camera')
          .where('isSpotlighted', isEqualTo: true)
          .get()
          .then((snap) {
        for (var doc in snap.docs) {
          doc.reference.update({'isSpotlighted': false});
        }
      });

      // Apply new spotlight
      await roomRef
          .collection('camera')
          .doc(targetUid)
          .update({'isSpotlighted': true});

      debugPrint('✅ Camera spotlighted: $targetUid');
    } catch (e) {
      debugPrint('❌ Failed to spotlight camera: $e');
      rethrow;
    }
  }

  /// Remove spotlight
  Future<void> removeSpotlight(String roomId) async {
    try {
      await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('camera')
          .where('isSpotlighted', isEqualTo: true)
          .get()
          .then((snap) {
        for (var doc in snap.docs) {
          doc.reference.update({'isSpotlighted': false});
        }
      });

      debugPrint('✅ Spotlight removed');
    } catch (e) {
      debugPrint('❌ Failed to remove spotlight: $e');
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
            final participantDoc = await _firestore
                .collection('rooms')
                .doc(roomId)
                .collection('participants')
                .doc(doc.id)
                .get();

            if (participantDoc.exists) {
              final data = participantDoc.data()!;
              cameras.add(CameraState(
                uid: doc.id,
                isLive: true,
                quality: _parseQuality(doc['quality'] as String?),
                status: CameraStatus.active,
                viewCount: doc['viewCount'] ?? 0,
                isFrozen: _isFrozen(doc['lastFrameAt'] as Timestamp?),
                isSpotlighted: doc['isSpotlighted'] ?? false,
                startedAt: (doc['startedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                userName: data['displayName'] ?? 'User',
                userPhotoUrl: data['photoUrl'],
                isVIP: data['isVIP'] ?? false,
                isBroadcaster: data['isBroadcaster'] ?? false,
              ));
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
        debugPrint('⚠️ Removed $toRemove cameras to enforce limit');
      }
    } catch (e) {
      debugPrint('❌ Failed to enforce camera limit: $e');
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
          .count
          .get();

      return snapshot.count;
    } catch (e) {
      debugPrint('❌ Failed to get camera count: $e');
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
      debugPrint('⚠️ Failed to increment view count: $e');
    }
  }
}
```

---

## 3️⃣ PROVIDERS

### `camera_providers.dart`

```dart
final cameraServiceProvider = Provider((ref) => CameraService());

final activeCamerasProvider = StreamProvider.family<List<CameraState>, String>(
  (ref, roomId) {
    final service = ref.watch(cameraServiceProvider);
    return service.streamActiveCameras(roomId);
  },
);

final activeCameraCountProvider = FutureProvider.family<int, String>(
  (ref, roomId) async {
    final service = ref.watch(cameraServiceProvider);
    return service.getActiveCameraCount(roomId);
  },
);

final spotlightedCameraProvider = StateProvider<String?>((ref) => null);

final cameraQualityProvider = StateProvider.family<CameraQuality, String>(
  (ref, userId) => CameraQuality.high,
);

final showSpotlightViewProvider = StateProvider<bool>((ref) => false);
```

---

## 4️⃣ UI WIDGETS

### Key Implementation Notes

1. **CameraGrid**:
   - Responsive (2 cols mobile, 4 cols tablet, 4-6 cols desktop)
   - Maintains 16:9 aspect ratio per camera
   - Smooth grid transitions when cams join/leave

2. **SpotlightView**:
   - Full-screen main camera
   - 4 thumbnail previews in corner
   - Tap thumbnail to swap

3. **CameraQualitySelector**:
   - Radio buttons (Low/Med/High)
   - Shows bandwidth estimate
   - Real-time apply

---

## 5️⃣ DATABASE SCHEMA

```firestore
rooms/{roomId}/
  camera/
    {uid}/
      - isLive: boolean
      - quality: string (low/medium/high)
      - status: string (loading/active/frozen/error)
      - resolution: number
      - bitrate: number
      - fps: number
      - viewCount: number
      - isSpotlighted: boolean
      - startedAt: timestamp
      - lastFrameAt: timestamp (for freeze detection)

  participants/
    {uid}/
      - isCameraOn: boolean
      - cameraQuality: string
      - isVIP: boolean
      - isBroadcaster: boolean
```

---

## 🎯 IMPLEMENTATION CHECKLIST

- [ ] Create models (CameraState, CameraQuality)
- [ ] Build CameraService with all methods
- [ ] Create Riverpod providers
- [ ] Build CameraGrid widget (responsive)
- [ ] Build CameraTile widget (with overlay badges)
- [ ] Build SpotlightView widget
- [ ] Build CameraQualitySelector
- [ ] Build FreezeDetector logic
- [ ] Build CamCountIndicator
- [ ] Add to room_page.dart
- [ ] Test with 4-20 cameras
- [ ] Performance optimize (lazy loading)
- [ ] Deploy to production

---

## 📱 UI PREVIEW

```
┌─────────────────────────────────────┐
│  Room: Gaming Party   [3/20 CAMS]   │ ← CamCountIndicator
├─────────────────────────────────────┤
│                                     │
│  ┌────────┐ ┌────────┐              │
│  │📡 John │ │📶 Sarah│              │ ← Grid View
│  │ HD     │ │ SD     │              │
│  └────────┘ └────────┘              │
│  ┌────────┐ ┌────────┐              │
│  │🌟 Mike │ │📱 Emma │              │ ← VIP badge, quality badges
│  │ HD     │ │ Mobile │              │
│  └────────┘ └────────┘              │
│                                     │
├─────────────────────────────────────┤
│  [Grid] [Spotlight] [Quality: High] │ ← Controls
└─────────────────────────────────────┘
```

---

## 🚀 DEPLOYMENT

1. Implement all files
2. Run tests (grid responsiveness, freeze detection, etc.)
3. Deploy to production
4. Monitor:
   - Rendering performance (FPS)
   - Bandwidth per quality level
   - Camera transition smoothness

---

**Ready to build?** Let me know and I'll generate the complete Widget code!
