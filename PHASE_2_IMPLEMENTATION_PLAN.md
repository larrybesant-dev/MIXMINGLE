# PHASE 2: DETAILED IMPLEMENTATION PLAN

**Timeline:** ~20 hours to production readiness
**Sprint 1 (P0):** 2-3 hours - Critical fixes
**Sprint 2 (P1):** 5-8 hours - Core features & cleanup
**Sprint 3 (P2):** 5-10 hours - Polish & hardening

---

## PHASE 2A: CRITICAL FIXES (P0) - 2-3 Hours

### Fix #1: Agora Web Bridge Missing Import
**File:** `lib/services/agora_web_bridge_v2.dart`
**Issue:** `allowInterop` not found (line 209)
**Root Cause:** Missing `import 'dart:js_util'` for interop utilities
**Action:**
```dart
// ADD this import at top of file:
import 'dart:js_util' as js_util;

// CHANGE line 209 from:
final onSuccess = js.allowInterop((dynamic result) { ... })
// TO:
final onSuccess = js_util.allowInterop((dynamic result) { ... })
```
**Verification:** Run `flutter analyze lib/services/agora_web_bridge_v2.dart`

---

### Fix #2: AppLogger.warn() → .warning()
**File:** `lib/services/agora_platform_service.dart`
**Issue:** Line 67 calls undefined `AppLogger.warn()`
**Root Cause:** Method is named `warning()` not `warn()`
**Action:**
```dart
// CHANGE line 67 from:
AppLogger.warn('⚠️ Failed to enable local tracks');
// TO:
AppLogger.warning('⚠️ Failed to enable local tracks');
```
**Verification:** Build web target: `flutter build web --release 2>&1 | grep -i error`

---

### Fix #3: Reorder enableLocalTracks After Join
**File:** `lib/services/agora_platform_service.dart`
**Issue:** Lines 58-75 - enableLocalTracks called before permissions granted
**Root Cause:** Browser permission prompt happens during `joinChannel`, not before
**Action:**

```dart
// CURRENT (WRONG) order in joinChannel():
1. initSuccess = await AgoraWebBridgeV2.init(appId);           // ← Init SDK
2. tracksSuccess = await AgoraWebBridgeV2.enableLocalTracks(...)  // ← TOO EARLY!
3. result = await AgoraWebBridgeV2.joinChannel(...)             // ← Permissions prompt here

// CHANGE TO:
1. initSuccess = await AgoraWebBridgeV2.init(appId);           // ← Init SDK
2. result = await AgoraWebBridgeV2.joinChannel(...);            // ← Join (permissions prompt)
3. tracksSuccess = await AgoraWebBridgeV2.enableLocalTracks(...)  // ← Now safe

// Code change:
// Move lines 58-68 (enableLocalTracks call) to AFTER the joinChannel() call
```

**Detailed Change:**
```dart
if (kIsWeb) {
  _consoleLog('✅ WEB PATH: Initializing AgoraWebBridgeV2');

  // Step 1: Init
  final initSuccess = await AgoraWebBridgeV2.init(appId);
  if (!initSuccess) {
    return false;
  }

  // Step 2: JOIN FIRST (this is when browser prompts for permissions)
  _consoleLog('✅ WEB PATH: Calling AgoraWebBridgeV2.joinChannel()');
  final result = await AgoraWebBridgeV2.joinChannel(
    channelName: channelName,
    token: token,
    uid: uid,
  );
  if (!result) {
    return false;
  }

  // Step 3: ENABLE TRACKS AFTER JOIN (permissions now granted)
  _consoleLog('✅ WEB PATH: Enabling local tracks...');
  final tracksSuccess = await AgoraWebBridgeV2.enableLocalTracks(
    enableAudio: true,
    enableVideo: true,
  );
  if (!tracksSuccess) {
    AppLogger.warning('⚠️ Failed to enable local tracks');
  }

  _consoleLog('✅ WEB PATH: Result = $result');
  AppLogger.info('✅ WEB PATH: Result = $result');
  return result;
}
```

**Verification:**
- Test web join flow
- Verify browser prompts for permissions
- Verify local video appears

---

### Fix #4: Verify Build After Critical Fixes
**Command:**
```bash
flutter pub get
flutter analyze lib/services/agora_web_bridge_v2.dart lib/services/agora_platform_service.dart
flutter build web --release 2>&1 | tail -20
```

**Expected Output:**
```
✅ No errors
✅ Build successful
```

---

## PHASE 2B: CORE FEATURES & CLEANUP (P1) - 5-8 Hours

### Sprint 1: Agora Web Remote User Handling
**ETA:** 3-4 hours

#### 1B.1 Add Remote Video Event Forwarding (JS Bridge)
**File:** `web/index.html`
**Current Status:** JS bridge has init/join but no remote user events
**Action:** Add event listeners in the agoraWeb bridge

```javascript
// ADD to web/index.html in agoraWeb bridge (after joinChannel definition):

// Remote user event callbacks
window.agoraWeb.onRemoteUserPublished = null;
window.agoraWeb.onRemoteUserUnpublished = null;

// After client.join() succeeds, attach event listeners:
client.on('user-published', async (remoteUser, mediaType) => {
  log('Remote user published:', remoteUser.uid, mediaType);

  // Fire callback to Dart
  if (window.agoraWeb.onRemoteUserPublished) {
    try {
      window.agoraWeb.onRemoteUserPublished({
        uid: remoteUser.uid,
        mediaType: mediaType,
        displayName: remoteUser.videoTrack ? 'has_video' : 'audio_only'
      });
    } catch (e) {
      console.error('[BRIDGE] Error in onRemoteUserPublished callback:', e);
    }
  }

  // Auto-subscribe to remote user
  try {
    await client.subscribe(remoteUser, mediaType);
    log('Subscribed to remote user:', remoteUser.uid, mediaType);

    // If video, play it
    if (mediaType === 'video' && remoteUser.videoTrack) {
      const videoTrack = remoteUser.videoTrack;
      // Create container for this user's video
      const containerId = `remote-video-${remoteUser.uid}`;
      let container = document.getElementById(containerId);

      if (!container) {
        container = document.createElement('div');
        container.id = containerId;
        container.style.width = 'auto';
        container.style.height = 'auto';
        document.body.appendChild(container);
      }

      videoTrack.play(container);
      log('Playing video for remote user:', remoteUser.uid);
    }
  } catch (err) {
    console.error('[BRIDGE] Error subscribing to remote user:', err);
  }
});

client.on('user-unpublished', (remoteUser, mediaType) => {
  log('Remote user unpublished:', remoteUser.uid, mediaType);

  // Stop playing video
  if (mediaType === 'video' && remoteUser.videoTrack) {
    remoteUser.videoTrack.stop();
  }

  // Fire callback to Dart
  if (window.agoraWeb.onRemoteUserUnpublished) {
    try {
      window.agoraWeb.onRemoteUserUnpublished({
        uid: remoteUser.uid,
        mediaType: mediaType
      });
    } catch (e) {
      console.error('[BRIDGE] Error in onRemoteUserUnpublished callback:', e);
    }
  }
});
```

#### 1B.2 Wire Remote User Events in Dart
**File:** `lib/services/agora_video_service.dart`
**Action:** Add initialization of JS callbacks for web

```dart
// In initialize() method, after engine setup, add:

if (kIsWeb) {
  _setupWebRemoteUserCallbacks();
}

// Add new method:
void _setupWebRemoteUserCallbacks() {
  try {
    final bridge = js.context['agoraWeb'];
    if (bridge == null) return;

    // On remote user published
    bridge['onRemoteUserPublished'] = js.allowInterop((dynamic event) {
      final uid = event['uid'] as int?;
      final mediaType = event['mediaType'] as String?;

      if (uid != null) {
        DebugLog.info('Remote user published: uid=$uid, mediaType=$mediaType');
        // Update participant state
        _addParticipantToState(uid);
        notifyListeners();
      }
    });

    // On remote user unpublished
    bridge['onRemoteUserUnpublished'] = js.allowInterop((dynamic event) {
      final uid = event['uid'] as int?;

      if (uid != null) {
        DebugLog.info('Remote user unpublished: uid=$uid');
        _remoteUsers.remove(uid);
        ref?.read(agoraParticipantsProvider.notifier).removeParticipant(uid);
        notifyListeners();
      }
    });

    DebugLog.info('Web remote user callbacks configured');
  } catch (e) {
    DebugLog.info('Error setting up web callbacks: $e');
  }
}
```

#### 1B.3 Test Remote User Flow
**Test Steps:**
1. Open two browsers to same room
2. First joins successfully
3. Second joins
4. Verify first browser sees second user
5. Verify vice versa
6. Verify leave/rejoin works

---

### Sprint 2: Firestore Schema & Rules
**ETA:** 2-3 hours

#### 2B.1 Create FIRESTORE_SCHEMA.md
**File:** `FIRESTORE_SCHEMA.md`
**Content:** Document all collections, fields, validation rules

```markdown
# Firestore Schema Documentation

## Collections

### users/
Stores user profile data.

**Primary Key:** userId (Firebase Auth UID)

**Fields:**
- displayName: string (required, indexed)
- email: string (required, indexed)
- photoURL: string (optional)
- bio: string (optional, max 500 chars)
- createdAt: timestamp (required)
- updatedAt: timestamp (required)
- isOnline: boolean (computed)
- recentActivity: array (computed)

**Sub-collections:**
- blocked/{blockedUserId} - Users this user has blocked

**Rules:**
- Only the user can read/write their own document
- Only the user can manage their blocked list
- displayName must be 1-50 characters
- email must be valid
- bioDescription must be < 500 characters

---

### rooms/
Stores video chat room metadata.

**Primary Key:** roomId (auto-generated)

**Fields:**
- hostId: string (required, indexed)
- title: string (required)
- description: string (optional)
- createdAt: timestamp (required)
- isActive: boolean (required, indexed)
- participantCount: int (computed)
- maxParticipants: int (optional, default 100)
- tags: array (optional)

**Sub-collections:**
- participants/{userId} - Participants currently in room
  - joinedAt: timestamp
  - displayName: string
  - photoUrl: string

- messages/{messageId} - Chat messages in room
  - senderId: string
  - content: string
  - createdAt: timestamp
  - reactions: map

**Rules:**
- Anyone can read active rooms
- Only host can write room metadata
- Authenticated users can create rooms
- Only room host can delete
- Participants can read their own records
- Messages can be read by room participants
- Anyone can write messages to active rooms (unless banned)

---

### messages/
Global message log (optional separate collection).

**Primary Key:** messageId (auto-generated)

**Rules:**
- Only host/mods can delete
- Author can edit own messages
- Read-only for room participants

```

**File Location:** Root of project as `FIRESTORE_SCHEMA.md`

#### 2B.2 Create firestore.rules
**File:** `firestore.rules`
**Content:** Implement Firestore security rules

```
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {

    // User documents
    match /users/{userId} {
      // Users can only read/write their own document
      allow read, write: if request.auth.uid == userId;

      // Block sub-collection
      match /blocked/{blockedUserId} {
        allow read, write: if request.auth.uid == userId;
      }
    }

    // Room documents
    match /rooms/{roomId} {
      // Anyone can read active rooms
      allow read: if resource.data.isActive == true;

      // Only authenticated users can create
      allow create: if request.auth != null &&
                       request.resource.data.hostId == request.auth.uid;

      // Only the host can update/delete
      allow update, delete: if request.auth.uid == resource.data.hostId;

      // Participants sub-collection
      match /participants/{userId} {
        // Participants can read their own record
        allow read: if request.auth.uid == userId ||
                       request.auth.uid == get(/databases/$(database)/documents/rooms/$(roomId)).data.hostId;

        // Anyone in room can write their own participant record
        allow write: if request.auth.uid == userId;
      }

      // Messages sub-collection
      match /messages/{messageId} {
        // Anyone can read messages in active rooms
        allow read: if get(/databases/$(database)/documents/rooms/$(roomId)).data.isActive == true;

        // Authenticated users can create messages
        allow create: if request.auth != null &&
                        request.resource.data.senderId == request.auth.uid;

        // Authors can update/delete their own messages
        allow update, delete: if request.auth.uid == resource.data.senderId;
      }
    }

    // Notifications queue
    match /notifications_queue/{notificationId} {
      // Users can read their own notifications
      allow read: if request.auth.uid == resource.data.recipientId;

      // System can write
      allow create: if request.auth == null; // Cloud functions write
    }

    // Config documents (read-only for users)
    match /config/{document=**} {
      allow read: if request.auth != null;
    }
  }
}
```

**Deployment:**
```bash
# Use Firebase CLI:
firebase deploy --only firestore:rules
```

#### 2B.3 Centralize Firestore Collection Names
**File:** Create `lib/core/constants/firestore_collections.dart`

```dart
/// Centralized Firestore collection and field names
/// Single source of truth for database schema

abstract class FirestoreCollections {
  // Collections
  static const String users = 'users';
  static const String rooms = 'rooms';
  static const String messages = 'messages';
  static const String notifications = 'notifications_queue';
  static const String config = 'config';

  // Sub-collection paths
  static String userBlocked(String userId) => '$users/$userId/blocked';
  static String roomParticipants(String roomId) => '$rooms/$roomId/participants';
  static String roomMessages(String roomId) => '$rooms/$roomId/messages';
}

/// User document fields
abstract class UserFields {
  static const String displayName = 'displayName';
  static const String email = 'email';
  static const String photoURL = 'photoURL';
  static const String bio = 'bio';
  static const String createdAt = 'createdAt';
  static const String updatedAt = 'updatedAt';
  static const String isOnline = 'isOnline';
}

/// Room document fields
abstract class RoomFields {
  static const String hostId = 'hostId';
  static const String title = 'title';
  static const String description = 'description';
  static const String createdAt = 'createdAt';
  static const String isActive = 'isActive';
  static const String participantCount = 'participantCount';
  static const String maxParticipants = 'maxParticipants';
}

/// Message document fields
abstract class MessageFields {
  static const String senderId = 'senderId';
  static const String content = 'content';
  static const String createdAt = 'createdAt';
  static const String reactions = 'reactions';
}
```

**Usage in Code:**
```dart
// BEFORE (scattered):
_firestore.collection('users').doc(userId).get();

// AFTER (centralized):
_firestore.collection(FirestoreCollections.users).doc(userId).get();
```

**Action:** Replace all hardcoded collection names with imported constants

---

### Sprint 3: Code Cleanup (Service Layer)
**ETA:** 2-3 hours

#### 3B.1 Archive Deprecated Files
**Action:** Create `lib/services/legacy/` folder and move old files

```bash
mkdir -p lib/services/legacy

# Move deprecated files:
mv lib/services/agora_service.dart.deprecated → lib/services/legacy/
mv lib/services/agora_web_bridge_v2_old.dart → lib/services/legacy/
mv lib/services/agora_web_bridge_v2_simple.dart → lib/services/legacy/
mv lib/services/agora_web_bridge_v2_stub.dart → lib/services/legacy/
mv lib/services/hms_video_service.dart.bak → lib/services/legacy/

# Add README:
echo "# Legacy Services - Archived

These services are deprecated and kept for reference only.
Do not use these in production code.

New implementations:
- agora_web_bridge_v2.dart (replaces all agora_web_bridge variants)
- agora_video_service.dart (replaces agora_service.dart)
" > lib/services/legacy/README.md
```

---

#### 3B.2 Verify No Imports from Legacy
**Action:** Search codebase for imports from legacy files

```bash
grep -r "agora_web_bridge_v2_old\|agora_service\.dart\.deprecated" lib/
# Should return: 0 matches
```

---

## PHASE 2C: PRODUCTION HARDENING (P2) - 5-10 Hours

### Sprint 1: Test Coverage
**ETA:** 3-4 hours

#### 1C.1 Add Web Platform Tests
**File:** `test/services/agora_web_bridge_v2_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mix_and_mingle/services/agora_web_bridge_v2.dart';

void main() {
  group('AgoraWebBridgeV2 Tests', () {
    test('isAvailable returns false when agoraWeb not defined', () {
      // On non-web, should return false
      expect(AgoraWebBridgeV2.isAvailable, false);
    });

    test('init method exists', () {
      // Just verify method can be called without error
      expect(AgoraWebBridgeV2.init, isA<Function>());
    });

    test('joinChannel method exists', () {
      expect(AgoraWebBridgeV2.joinChannel, isA<Function>());
    });
  });
}
```

#### 1C.2 Add Room Flow Integration Test
**File:** `integration_test/agora_room_flow_test.dart`

```dart
import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mix_and_mingle/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Agora Room Flow Tests', () {
    testWidgets('Can join and leave a room', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // TODO: Implement full flow test
      // 1. Sign in
      // 2. Create/join room
      // 3. Verify video initializes
      // 4. Verify can mute/unmute
      // 5. Leave room
      // 6. Verify cleanup
    });
  });
}
```

---

### Sprint 2: Documentation
**ETA:** 1-2 hours

#### 2C.1 Create ARCHITECTURE_OVERVIEW.md
**File:** Located at root

```markdown
# Mix & Mingle Architecture Overview

## Application Structure

### Layers

```
UI Layer (Screens/Widgets)
        ↓
State Management Layer (Riverpod Providers)
        ↓
Service Layer (Business Logic)
        ↓
Adapter Layer (Platform-specific)
        ↓
External Services (Firebase, Agora, etc.)
```

### Key Directories

- **lib/features/** - Feature modules (auth, room, chat, etc.)
  - Each feature has: screens/, widgets/, models/

- **lib/services/** - Business logic services
  - auth_service.dart - Firebase authentication
  - agora_video_service.dart - Video chat logic
  - room_manager_service.dart - Room management
  - etc.

- **lib/providers/** - Riverpod state management
  - One provider file per service domain

- **lib/core/** - Shared utilities
  - **theme/** - Design system (NeonTheme, NeonColors)
  - **constants/** - App constants
  - **utils/** - Helper functions

- **lib/shared/** - Shared widgets and models

- **lib/models/** - Domain models

### Data Flow Example: Joining a Room

```
Room Page (UI)
    ↓ trigger joinRoom()
Room Provider (Riverpod)
    ↓ call service
AgoraVideoService
    ↓ check auth
AuthService
    ↓ fetch token
AgoraTokenService → Cloud Function
    ↓ initialize
AgoraPlatformService (Web/Native router)
    ↓
Web: AgoraWebBridgeV2 → JS Bridge
Native: agora_rtc_engine
    ↓
Firestore: Add to participants
    ↓
Success: Update provider state
Room UI updates
```

## Platform-Specific Implementation

### Web (Flutter Web)
- Uses Agora Web SDK (AgoraRTC.js)
- JavaScript interop via dart:js
- Promise-to-Future conversion
- Browser permissions via browser API

### Native (iOS/Android)
- Uses Agora Flutter SDK (agora_rtc_engine)
- Native permissions via permission_handler
- Event listeners for real-time updates

### Conditional Compilation

```dart
if (kIsWeb) {
  // Web-specific code
  await AgoraWebBridgeV2.joinChannel(...);
} else {
  // Native-specific code
  await _engine!.joinChannel(...);
}
```

## State Management: Riverpod Pattern

### Service Providers (StateNotifierProvider)
```dart
final agoraVideoServiceProvider = StateNotifierProvider((ref) {
  return AgoraVideoService();
});
```

### Data Providers (FutureProvider)
```dart
final userProvider = FutureProvider<User>((ref) async {
  return await userService.getUser();
});
```

### Watchers
```dart
ref.watch(agoraVideoServiceProvider).joinRoom();
```

## Design System

### Theme: NeonTheme
- Dark navy background
- Neon orange (#FF7A3C) - primary
- Neon blue (#00D9FF) - secondary
- Neon purple (#BD00FF) - accent

### Components
- NeonButton - Primary CTAs with glow
- NeonCard - Cards with neon borders
- NeonText - Text with glow effect
- MixMingleLogo - Official branding

### Color Usage
- Orange: Actions, emphasis, energy
- Blue: Secondary actions, trust, connection
- Purple: Premium features, special states

## Testing Strategy

### Unit Tests
- Service logic (token generation, room creation)
- Model serialization (toMap/fromMap)
- Utility functions

### Widget Tests
- Individual screen components
- Button interactions
- Form validation

### Integration Tests
- End-to-end flows (auth → room → video → leave)
- Firebase integration
- Platform-specific code paths

## Security Practices

### Authentication
- Firebase Auth for identity
- ID token refresh before sensitive operations
- Session persistence with remember-me option

### Data Access
- Firestore rules enforce access control
- User can only access own data
- Room participants validated server-side

### API Security
- Agora tokens time-limited
- Token generated server-side only
- No hardcoded secrets in app

## Error Handling

### Error Types
- **AuthException** - Auth failures
- **NetworkException** - Network errors
- **AgoraException** - Video chat failures
- **FirestoreException** - Database errors

### Error Recovery
- Automatic retry with exponential backoff
- User-friendly error messages
- Detailed logging for debugging

## Performance Optimizations

### Lazy Loading
- Providers only initialized when needed
- Images optimized with lazy loading

### Caching
- Firestore query results cached
- User data cached in auth state

### Memory Management
- Proper cleanup in dispose() methods
- Agora track cleanup on leave
- No memory leaks in listeners

[Continued in actual file...]
```

---

## VERIFICATION CHECKLIST

After all Phase 2 fixes are applied, verify:

- [ ] `flutter analyze` returns 0 errors
- [ ] `flutter build web --release` succeeds
- [ ] Web room join flow works end-to-end
- [ ] Remote users appear in video grid
- [ ] Mute/unmute works
- [ ] Tests compile and run
- [ ] Firestore rules deployed
- [ ] No hardcoded collection names remaining
- [ ] All deprecated files archived
- [ ] Documentation complete

---

**Next Phase:** Phase 3 (Testing & Optimization)
