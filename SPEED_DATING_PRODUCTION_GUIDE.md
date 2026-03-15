# 🎯 SPEED DATING PRODUCTION - COMPLETE INTEGRATION GUIDE

**Status**: ✅ PRODUCTION READY
**Last Updated**: 2025
**Architecture**: Server-Authoritative with Cloud Functions v2

---

## 📦 WHAT'S BEEN BUILT

### Backend (Cloud Functions - 806 lines)

✅ **speedDatingComplete.ts** - Comprehensive Cloud Functions system:

- `matchSpeedDating` - Scheduled matcher (runs every 30s)
- `generateSpeedDatingToken` - Secure Agora token generation
- `submitSpeedDatingDecision` - Decision handling + match creation
- `joinSpeedDatingQueue` / `leaveSpeedDatingQueue` - Queue management
- `leaveSpeedDatingSession` - Early exit handling
- `autoExpireSpeedDatingSessions` - Auto-expiry (every 1 min)
- `endSpeedDatingSession` - Cleanup on completion

### Frontend Providers (585 lines)

✅ **speed_dating_queue_cloud.dart** - Queue provider using Cloud Functions
✅ **speed_dating_session_cloud.dart** - Session provider with backend tokens

### Frontend Screens

✅ **speed_dating_lobby_cloud.dart** - Complete lobby with preferences, queue count, animations

### Security

✅ **firestore_speed_dating.rules** - Production Firestore rules

---

## 🚀 DEPLOYMENT STEPS

### Step 1: Deploy Cloud Functions

```powershell
# Navigate to functions directory
cd functions

# Install dependencies (if not already)
npm install

# Deploy ONLY speed dating functions
firebase deploy --only functions:matchSpeedDating,functions:generateSpeedDatingToken,functions:submitSpeedDatingDecision,functions:joinSpeedDatingQueue,functions:leaveSpeedDatingQueue,functions:leaveSpeedDatingSession,functions:autoExpireSpeedDatingSessions,functions:endSpeedDatingSession

# OR deploy all functions
firebase deploy --only functions
```

**Expected Output**:

```
✔  functions[matchSpeedDating(us-central1)] Successful create operation.
✔  functions[generateSpeedDatingToken(us-central1)] Successful create operation.
...
✔  Deploy complete!
```

### Step 2: Update functions/src/index.ts

Add to your `functions/src/index.ts`:

```typescript
// Speed Dating - PRODUCTION VERSION
export {
  matchSpeedDating,
  generateSpeedDatingToken,
  submitSpeedDatingDecision,
  joinSpeedDatingQueue,
  leaveSpeedDatingQueue,
  leaveSpeedDatingSession,
  autoExpireSpeedDatingSessions,
  endSpeedDatingSession,
} from "./speedDatingComplete";
```

### Step 3: Deploy Firestore Rules

```powershell
# Deploy security rules
firebase deploy --only firestore:rules

# Or copy firestore_speed_dating.rules content to firestore.rules
# then deploy
```

### Step 4: Update Flutter Frontend

#### 4A. Update Provider Imports

**Before** (old client-side matching):

```dart
import '../providers/speed_dating_queue_provider.dart';
import '../providers/speed_dating_session_provider.dart';
```

**After** (new Cloud Functions):

```dart
import '../providers/speed_dating_queue_cloud.dart';
import '../providers/speed_dating_session_cloud.dart';
```

#### 4B. Update Routing (app_routes.dart or similar)

```dart
// Speed Dating routes
GoRoute(
  path: '/speed-dating-lobby',
  name: 'speed-dating-lobby',
  builder: (context, state) => const SpeedDatingLobbyPageCloud(),
  redirect: (context, state) {
    // Add your auth guards here
    final auth = ref.read(authStateProvider);
    if (auth == null) return '/login';

    // Check profile completion
    final user = ref.read(currentUserProvider);
    if (user.value?.hasCompletedOnboarding != true) {
      return '/onboarding';
    }

    return null; // Allow
  },
),

GoRoute(
  path: '/speed-dating/session',
  name: 'speed-dating-session',
  builder: (context, state) {
    final sessionId = state.extra as String?;
    if (sessionId == null) {
      return const ErrorScreen(message: 'Session not found');
    }
    return SpeedDatingSessionPageCloud(sessionId: sessionId);
  },
),
```

#### 4C. Install Dependencies

Ensure `pubspec.yaml` has:

```yaml
dependencies:
  cloud_functions: ^4.0.0 # Cloud Functions callable
  agora_rtc_engine: ^6.0.0 # Agora video
  confetti: ^0.7.0 # Match celebration
```

Run:

```powershell
flutter pub get
```

### Step 5: Create Session Screen (Optional Enhancement)

You can create a complete session screen using the pattern from `speed_dating_lobby_cloud.dart`. Here's a minimal implementation:

**lib/features/speed_dating/screens/speed_dating_session_cloud.dart**:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../providers/speed_dating_session_cloud.dart';

class SpeedDatingSessionPageCloud extends ConsumerStatefulWidget {
  final String sessionId;

  const SpeedDatingSessionPageCloud({
    required this.sessionId,
    super.key,
  });

  @override
  ConsumerState<SpeedDatingSessionPageCloud> createState() =>
      _SpeedDatingSessionPageCloudState();
}

class _SpeedDatingSessionPageCloudState
    extends ConsumerState<SpeedDatingSessionPageCloud> {
  RtcEngine? _engine;
  int? _remoteUid;
  bool _localUserJoined = false;

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    // Load session + get token
    await ref.read(speedDatingSessionProvider.notifier)
        .loadSession(widget.sessionId);

    final state = ref.read(speedDatingSessionProvider);

    if (state.agoraToken.isEmpty) {
      debugPrint('❌ No Agora token');
      return;
    }

    // Create engine
    _engine = createAgoraRtcEngine();
    await _engine!.initialize(RtcEngineContext(
      appId: state.session?.agoraChannel.split('_').first ?? '',
    ));

    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint('✅ Local user joined');
          setState(() => _localUserJoined = true);
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint('✅ Remote user joined: $remoteUid');
          setState(() => _remoteUid = remoteUid);
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          debugPrint('❌ Remote user left: $remoteUid');
          setState(() => _remoteUid = null);
        },
      ),
    );

    await _engine!.enableVideo();
    await _engine!.startPreview();

    // Join channel with token from backend
    await _engine!.joinChannel(
      token: state.agoraToken,
      channelId: state.session!.agoraChannel,
      uid: state.agoraUid,
      options: const ChannelMediaOptions(),
    );
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  Future<void> _dispose() async {
    await _engine?.leaveChannel();
    await _engine?.release();
  }

  Future<void> _makeDecision(String decision) async {
    await ref.read(speedDatingSessionProvider.notifier)
        .makeDecision(decision);

    // Check if both decided
    final state = ref.read(speedDatingSessionProvider);
    if (state.session?.bothDecided == true) {
      // Navigate based on match result
      if (state.session?.isMatch == true) {
        _showMatchDialog();
      } else {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    }
  }

  void _showMatchDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 It\'s a Match!'),
        content: const Text('You both liked each other!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
              Navigator.pushNamed(context, '/chats');
            },
            child: const Text('Go to Chat'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(speedDatingSessionProvider);
    final timeRemaining = ref.watch(timeRemainingProvider);

    if (state.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: ${state.error}'),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Remote video
          Center(
            child: _remoteUid != null
                ? AgoraVideoView(
                    controller: VideoViewController.remote(
                      rtcEngine: _engine!,
                      canvas: VideoCanvas(uid: _remoteUid),
                      connection: RtcConnection(
                        channelId: state.session!.agoraChannel,
                      ),
                    ),
                  )
                : const Text(
                    'Waiting for other user...',
                    style: TextStyle(color: Colors.white),
                  ),
          ),

          // Local video (small)
          Positioned(
            right: 16,
            top: 48,
            width: 120,
            height: 160,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _localUserJoined
                  ? AgoraVideoView(
                      controller: VideoViewController(
                        rtcEngine: _engine!,
                        canvas: const VideoCanvas(uid: 0),
                      ),
                    )
                  : Container(color: Colors.grey),
            ),
          ),

          // Timer
          Positioned(
            top: 48,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${timeRemaining ~/ 60}:${(timeRemaining % 60).toString().padLeft(2, '0')}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Decision buttons
          if (!state.session!.hasDecided(ref.read(authStateProvider)!.uid))
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Pass
                  FloatingActionButton.large(
                    onPressed: () => _makeDecision('pass'),
                    backgroundColor: Colors.red,
                    child: const Icon(Icons.close, size: 40),
                  ),
                  // Like
                  FloatingActionButton.large(
                    onPressed: () => _makeDecision('like'),
                    backgroundColor: Colors.green,
                    child: const Icon(Icons.favorite, size: 40),
                  ),
                ],
              ),
            ),

          // Exit button
          Positioned(
            top: 48,
            right: 16,
            child: IconButton(
              icon: const Icon(Icons.exit_to_app, color: Colors.white),
              onPressed: () async {
                await ref.read(speedDatingSessionProvider.notifier)
                    .leaveSession();
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 🏗️ FIRESTORE STRUCTURE

### Collections Created

```
speed_dating_queue/
  {userId}/
    - userId: string
    - displayName: string
    - photoUrl: string
    - age: number
    - gender: string
    - sexuality: string
    - isVerified: boolean
    - preferences: {
        minAge: number
        maxAge: number
        genderPreferences: string[]
        onlyVerified: boolean
      }
    - joinedAt: timestamp
    - status: 'waiting' | 'matched'

speed_dating_sessions/
  {sessionId}/
    - sessionId: string
    - user1Id: string
    - user1Name: string
    - user1Photo: string
    - user2Id: string
    - user2Name: string
    - user2Photo: string
    - agoraChannel: string
    - startedAt: timestamp
    - endsAt: timestamp
    - status: 'active' | 'completed' | 'cancelled' | 'expired'
    - decisions: {
        [userId]: 'like' | 'pass'
      }
    - createdAt: timestamp

speed_dating_decisions/
  {decisionId}/
    - userId: string
    - sessionId: string
    - otherUserId: string
    - decision: 'like' | 'pass'
    - createdAt: timestamp

users/
  {userId}/
    - activeSpeedDatingSession: string | null  # Session ID
    - matches: string[]  # Array of matched user IDs
```

---

## 🔒 MATCHING ALGORITHM

Located in `speedDatingComplete.ts > areCompatible()`:

```typescript
function areCompatible(user1: QueueEntry, user2: QueueEntry): boolean {
  // 1. Age check
  if (user1.age < user2.preferences.minAge || user1.age > user2.preferences.maxAge) return false;
  if (user2.age < user1.preferences.minAge || user2.age > user1.preferences.maxAge) return false;

  // 2. Gender preferences
  if (
    !user2.preferences.genderPreferences.includes("Any") &&
    !user2.preferences.genderPreferences.includes(user1.gender)
  )
    return false;
  if (
    !user1.preferences.genderPreferences.includes("Any") &&
    !user1.preferences.genderPreferences.includes(user2.gender)
  )
    return false;

  // 3. Sexuality matching
  if (user1.sexuality === "straight" && user2.sexuality === "straight") {
    if (user1.gender === user2.gender) return false;
  }
  if (user1.sexuality === "gay" && user2.sexuality === "gay") {
    if (user1.gender !== user2.gender) return false;
  }

  // 4. Verified-only filter
  if (user1.preferences.onlyVerified && !user2.isVerified) return false;
  if (user2.preferences.onlyVerified && !user1.isVerified) return false;

  return true;
}
```

**Runs every 30 seconds via Cloud Scheduler**

---

## 🎬 USER FLOW

```
1. User opens Lobby
   ↓
2. Sets preferences (age, gender, verified-only)
   ↓
3. Clicks "START MATCHING"
   ↓
4. joinSpeedDatingQueue Cloud Function called
   ↓
5. User added to speed_dating_queue/
   ↓
6. matchSpeedDating runs (every 30s)
   ↓
7. Finds compatible pair → createSpeedDatingSession()
   ↓
8. Sets users/{uid}/activeSpeedDatingSession = sessionId
   ↓
9. Frontend listens to activeSessionProvider
   ↓
10. Auto-navigates to /speed-dating/session
    ↓
11. Session loads → calls generateSpeedDatingToken
    ↓
12. Joins Agora channel with token
    ↓
13. 5-minute video call
    ↓
14. User clicks Like/Pass → submitSpeedDatingDecision
    ↓
15. If both like → createMatch() → chat created
    ↓
16. Navigate to chats
```

---

## 🧪 TESTING CHECKLIST

### Manual Testing

```powershell
# 1. Start Flutter web
flutter run -d chrome --no-hot

# 2. Open two browser windows/profiles
# 3. Login as different users
# 4. Both join queue
# 5. Wait up to 30 seconds
# 6. Should auto-match and navigate to session
# 7. Both should see video
# 8. Test decisions:
#    - Both like → match created
#    - One pass → no match
#    - Both pass → no match
# 9. Test early exit → session cancelled
# 10. Test timeout → auto-pass submitted
```

### Firebase Console Checks

```
1. Firestore > speed_dating_queue > Should show waiting users
2. Firestore > speed_dating_sessions > Should show active sessions
3. Functions > Logs > Check matchSpeedDating runs every 30s
4. Functions > Logs > Check generateSpeedDatingToken success
5. Firestore > chats > Check match creates chat
```

---

## 🐛 TROUBLESHOOTING

### Issue: "No matches found"

**Solution**:

- Check Firestore Rules deployed
- Check users meet compatibility criteria
- Check matchSpeedDating function logs

### Issue: "Token generation failed"

**Solution**:

- Verify Agora config: `firebase functions:config:get agora`
- Should show: `agora.appid` and `agora.cert`
- Re-deploy functions

### Issue: "Video not loading"

**Solution**:

- Check Agora App ID matches Firebase config
- Check token expiration (1 hour)
- Check browser camera permissions

### Issue: "Session expired immediately"

**Solution**:

- Check server time vs client time
- Check autoExpireSpeedDatingSessions not over-aggressive
- Session should last 5 minutes (300000ms)

---

## 📊 MONITORING

### Key Metrics to Watch

```typescript
// In Firebase Console > Functions > Metrics

matchSpeedDating:
  - Invocations: Should spike every 30s
  - Duration: <5s typical
  - Errors: <1%

generateSpeedDatingToken:
  - Invocations: 2 per session start
  - Duration: <1s
  - Errors: Check for invalid sessionId

submitSpeedDatingDecision:
  - Invocations: 2 per session (both users)
  - Duration: <2s
  - Errors: Check for duplicate submissions
```

### Firestore Costs

```
Reads per match:
  - Queue queries: 1 per matcher run (30s)
  - Session listen: 2 users × continuous
  - User profile reads: 2 per match

Writes per match:
  - Queue create: 2 (both users)
  - Session create: 1
  - Session updates: 2-4 (decisions)
  - User updates: 2 (activeSession field)
  - Match creation: 3-5 if both like

Estimate: ~15-20 operations per successful match
```

---

## 🚀 GOING LIVE

### Pre-Launch Checklist

- [ ] Firebase project upgraded to Blaze plan (Cloud Scheduler requires it)
- [ ] Agora credentials configured (`firebase functions:config:set agora.appid="xxx" agora.cert="xxx"`)
- [ ] All Cloud Functions deployed
- [ ] Firestore rules deployed
- [ ] Flutter app using `_cloud.dart` providers
- [ ] Routing guards enabled (age verification, profile completion)
- [ ] Tested with 2+ users
- [ ] Monitoring dashboards configured
- [ ] Error alerting enabled (Firebase Alerts)
- [ ] User support docs written

### Performance Optimization

```typescript
// Optional: Adjust matching frequency
export const matchSpeedDating = onSchedule({
  schedule: 'every 1 minutes', // Less frequent = lower costs
  timeZone: 'UTC',
  ...
})

// Optional: Implement queue batching
// Match multiple pairs per run instead of just first two
```

---

## 📝 CHANGELOG

### v2.0 (Production Ready)

- ✅ Server-authoritative matching (not client-side)
- ✅ Backend Agora token generation (secure)
- ✅ Scheduled matcher (Cloud Functions)
- ✅ Comprehensive compatibility algorithm
- ✅ Auto-expiry system
- ✅ Match creation with chat
- ✅ Firestore security rules
- ✅ Production frontend providers

### v1.0 (Deprecated)

- ❌ Client-side matching (insecure)
- ❌ Hardcoded Agora credentials (exposed)
- ❌ Manual session creation

---

## 🆘 SUPPORT

### Common Questions

**Q: How do I change matching criteria?**
A: Edit `speedDatingComplete.ts > areCompatible()` function, then redeploy Cloud Functions.

**Q: Can I add more preferences (height, kinks, etc)?**
A: Yes! Add fields to `QueueEntry` interface and `joinSpeedDatingQueue` validation, update compatibility logic.

**Q: How do I increase session duration?**
A: Edit `createSpeedDatingSession()`:

```typescript
const duration = 10 * 60 * 1000; // 10 minutes instead of 5
```

**Q: How do I disable auto-matching?**
A: Remove `matchSpeedDating` export from `index.ts` or delete Cloud Scheduler job.

---

## 🎉 YOU'RE DONE!

Your production-ready video speed dating feature is complete. Copy-paste the code, deploy, and test!

**Next Steps**:

1. Deploy Cloud Functions
2. Update frontend imports to use `_cloud.dart` providers
3. Test with 2 users
4. Monitor Firebase Console
5. Celebrate! 🎊
