# Video Chat Rooms - Production Readiness Checklist

## ✅ 6-Point Verification System

Your video chat implementation now follows the bulletproof 6-checkpoint sequence. Use this checklist to verify everything works on **Web and Mobile**.

---

## 🎯 Pre-Test Requirements

### Firestore Configuration

Ensure `/config/agora` document exists:

```json
{
  "appId": "your-agora-app-id",
  "certificate": "your-agora-certificate"
}
```

### User Profile Requirements

Every user document must have:

- `displayName`: string
- `photoURL`: string (optional)
- `isActive`: boolean = true

### Room Document Requirements

Room must exist and be marked live:

```json
{
  "id": "room-123",
  "name": "Test Room",
  "isLive": true,
  "createdBy": "user-id",
  "createdAt": Timestamp
}
```

---

## 📊 Join Sequence - What You'll See in Logs

When a user joins, you should see **exactly these 6 checkpoints** in order:

### Checkpoint 1: Authentication ✅

```
🔒 [1/6] Verifying authentication state...
   ├─ User: user@example.com
   ├─ UID: abc123...
   └─ Provider: google.com
✅ [1/6] Auth verified
```

### Checkpoint 2: Token Generation ✅

```
🎫 [2/6] Requesting Agora token...
   ├─ Refreshing Firebase ID token...
   ├─ Invoking generateAgoraToken callable...
   └─ Token response received
✅ [2/6] Token obtained
   ├─ Length: 847
   └─ Channel: room-123
```

### Checkpoint 3: Permissions ✅

**Web:**

```
🌐 [3/6] Web platform - browser will prompt for permissions on join
```

**Mobile:**

```
📱 [3/6] Requesting native permissions...
✅ [3/6] Permissions granted
```

### Checkpoint 4: Local Video Setup ✅

**Web:**

```
📹 [4/6] Setting up local video...
✅ [4/6] Web - local video will start on join
```

**Mobile:**

```
📹 [4/6] Setting up local video...
   ├─ enableLocalVideo(true)
   ├─ setupLocalVideo
   ├─ startPreview
   └─ muteLocalVideoStream(false)
✅ [4/6] Local video preview started
```

### Checkpoint 5: Firestore Participant ✅

```
📝 [5/6] Adding user to Firestore participants...
✅ [5/6] Participant added to Firestore
```

### Checkpoint 6: Join Channel ✅

**Web:**

```
═══════════════════════════════════
🔗 [6/6] Joining Agora channel...
   ├─ SDK: Web JS
   ├─ Channel: room-123
   ├─ UID: 0 (auto-assign)
   └─ Token length: 847

[AgoraPlatform] 🌐 Using WEB SDK (JS)
[AgoraWeb] ════════════════════════
[AgoraWeb] Attempting to join via JS SDK...
[AgoraWeb] window.agoraWeb available: true
[AgoraWeb] Calling window.agoraWeb.joinChannel...
[AgoraWeb]   └─ appId: 1a2b3c4d...
[AgoraWeb]   └─ channel: room-123
[AgoraWeb]   └─ uid: 0
[AgoraWeb]   └─ token: 0061a2b3c4d...
[AgoraWeb] ✅ JS SDK joinChannel returned SUCCESS
[AgoraWeb] ✅ Local tracks should be created and published
[AgoraWeb] ✅ Waiting for remote user events...
[AgoraWeb] ════════════════════════

═══════════════════════════════════
✅ [6/6] JOIN COMPLETE
✅ Successfully in channel: room-123
✅ Waiting for remote users...
═══════════════════════════════════
```

**Mobile:**

```
═══════════════════════════════════
🔗 [6/6] Joining Agora channel...
   ├─ SDK: Native Flutter
   ├─ Channel: room-123
   ├─ UID: 0 (auto-assign)
   └─ Token length: 847

[AgoraPlatform] 📱 Using NATIVE SDK (Flutter)
[AgoraPlatform] Calling native joinChannel...
[AgoraPlatform] ✅ Native joinChannel called successfully

═══════════════════════════════════
✅ [6/6] JOIN COMPLETE
✅ Successfully in channel: room-123
✅ Waiting for remote users...
═══════════════════════════════════
```

---

## 🧪 Test Scenarios

### Test 1: Single User (Smoke Test)

**Web:**

1. Open room on Chrome
2. Grant camera/mic permissions when prompted
3. Verify you see your own video preview
4. Check console for all 6 checkpoints

**Mobile:**

1. Open room on iOS/Android
2. Grant permissions
3. Verify local video preview
4. Check logs for all 6 checkpoints

**Expected:**

- All 6 checkpoints log successfully
- Local video visible
- No errors in console/logs

---

### Test 2: Two Users (Cross-Platform)

**Setup:**

1. User A: Web (Chrome)
2. User B: Mobile (iOS/Android)

**Steps:**

1. User A joins room
2. User B joins same room
3. Wait 3-5 seconds

**Expected:**

- User A sees User B's video
- User B sees User A's video
- Both see themselves
- Console shows: `User joined: [remoteUid]`
- Remote video state changes log

**What You'll See:**

```
User joined: 12345
Remote video state: uid=12345, state=remoteVideoStateDecoding
Remote audio state: uid=12345, state=remoteAudioStateDecoding
```

---

### Test 3: Mute/Unmute Verification

**Steps:**

1. User A: Click mute mic button
2. User B: Should see User A's mic indicator turn OFF
3. User A: Click unmute
4. User B: Should see mic indicator turn ON

**Expected Logs (User A):**

```
[AgoraWeb] Calling muteLocalAudio(true)
```

**Expected Behavior (User B):**

```
Remote audio state: uid=12345, state=remoteAudioStateStopped
```

---

### Test 4: User Leave/Rejoin

**Steps:**

1. User A and B in room
2. User A closes tab/leaves room
3. User B should see User A disappear
4. User A rejoins
5. User B should see User A reappear

**Expected Logs (User B):**

```
User left: 12345 (reason: UserOfflineReasonTypeQuit)
```

Then on rejoin:

```
User joined: 12345
```

---

### Test 5: Three+ Users (Scalability)

**Setup:**

1. User A: Web
2. User B: Mobile
3. User C: Web (different browser/incognito)

**Expected:**

- All see all other users
- Total: 3 local + 2 remote videos each
- Performance: Smooth, no lag
- Network: Check quality indicators

---

## 🔍 Troubleshooting Guide

### ❌ If you DON'T see Checkpoint 1

**Problem:** Auth not ready
**Solution:**

- Ensure Firebase Auth is initialized
- Check `_auth.currentUser` is not null
- Verify user is signed in before joining

---

### ❌ If you DON'T see Checkpoint 2

**Problem:** Token generation failed
**Solution:**

- Check `generateAgoraToken` Cloud Function is deployed
- Verify Agora App ID and Certificate in Firestore `/config/agora`
- Check Firebase Functions logs for errors
- Ensure user has valid Firebase Auth token

---

### ❌ If you DON'T see Checkpoint 3

**Problem:** Permissions blocked
**Solution:**

- **Web:** Browser blocked camera/mic (check address bar icon)
- **Mobile:** App permissions denied in Settings
- Reset browser permissions and try again

---

### ❌ If you DON'T see Checkpoint 4

**Problem:** Local video setup failed
**Solution:**

- Verify camera is not used by another app
- Check permissions granted
- On web, ensure HTTPS (not HTTP)

---

### ❌ If you DON'T see Checkpoint 5

**Problem:** Firestore write failed
**Solution:**

- Check Firestore rules allow write to `/rooms/{roomId}/participants/{userId}`
- Verify room document exists
- Check user is authenticated

---

### ❌ If you DON'T see Checkpoint 6

**Problem:** Join failed
**Solution:**

- **Web:** Check `window.agoraWeb` exists in console
- **Web:** Verify index.html loads AgoraRTC_N.js
- **Mobile:** Verify agora_rtc_engine initialized
- Check token is valid (matches channel and uid)

---

### ❌ Joined but NO remote video

**Problem:** User joined but you don't see them
**Diagnosis:**

1. Check if you see `User joined: [uid]` log
2. Check if you see `Remote video state: ...decoding` log
3. Check network quality logs

**Solutions:**

- Verify both users use correct SDK (web = JS, mobile = native)
- Check Agora App ID matches for both users
- Verify tokens generated with same channel name
- Check Firestore Security Rules allow both users to read participants

---

### ❌ Web: "agoraWeb not available"

**Problem:** JS SDK not loaded
**Solution:**

1. Open `web/index.html`
2. Verify script tag exists:
   ```html
   <script src="https://download.agora.io/sdk/release/AgoraRTC_N.js"></script>
   ```
3. Verify `window.agoraWeb` object created in index.html
4. Check browser console for JS errors

---

### ❌ Mobile: Join succeeds but crashes

**Problem:** Platform service routing issue
**Solution:**

- Check `kIsWeb` correctly identifies platform
- Verify native SDK initialized before join
- Check logs show "[AgoraPlatform] 📱 Using NATIVE SDK"

---

## 🎯 Success Criteria

✅ **All 6 checkpoints log in sequence**
✅ **Local video visible immediately**
✅ **Remote users appear within 3-5 seconds**
✅ **Mute/unmute reflects on remote side**
✅ **User leave removes video instantly**
✅ **Works on Web (Chrome, Firefox, Safari)**
✅ **Works on Mobile (iOS, Android)**
✅ **Cross-platform (Web ↔ Mobile) works**

---

## 📱 Platform-Specific Verification

### Web-Specific

- [ ] `window.agoraWeb` exists in browser console
- [ ] Browser prompts for camera/mic permissions
- [ ] Local video appears in preview div
- [ ] Console shows: `[AgoraWeb] ✅ JS SDK joinChannel returned SUCCESS`
- [ ] Remote videos render in DOM

### Mobile-Specific

- [ ] Native permissions dialog appears
- [ ] Local preview shows before join
- [ ] Console shows: `[AgoraPlatform] ✅ Native joinChannel called successfully`
- [ ] Remote videos render in AgoraVideoView widgets

---

## 🚀 Performance Benchmarks

### Join Time

- **Web:** < 3 seconds (auth → video visible)
- **Mobile:** < 2 seconds

### Remote User Appearance

- **Both:** < 5 seconds after second user joins

### Mute Toggle Response

- **Both:** < 500ms reflected on remote side

### Network Quality

- **Good:** Green indicator, smooth video
- **Poor:** Yellow/red indicator, possible lag

---

## 📊 Monitoring

### What to Monitor in Production

1. **Join success rate** (% of users who complete all 6 checkpoints)
2. **Average join time** (checkpoint 1 → checkpoint 6)
3. **Remote user discovery time** (join → first remote video)
4. **Error rate by checkpoint** (which checkpoint fails most)
5. **Platform distribution** (Web vs Mobile)
6. **Network quality distribution** (Good/Poor/Bad)

### Firebase Analytics Events to Log

```dart
// On join success
analytics.logEvent('video_room_join_success', parameters: {
  'room_id': roomId,
  'platform': kIsWeb ? 'web' : 'mobile',
  'join_time_ms': joinDuration.inMilliseconds,
});

// On join failure
analytics.logEvent('video_room_join_failure', parameters: {
  'room_id': roomId,
  'checkpoint': failedCheckpoint,
  'error': errorMessage,
});

// On remote user seen
analytics.logEvent('video_room_remote_user', parameters: {
  'room_id': roomId,
  'discovery_time_ms': discoveryDuration.inMilliseconds,
});
```

---

## 🔧 Quick Fixes

### Clear Browser Permissions (Web)

```
chrome://settings/content/camera
chrome://settings/content/microphone
```

### Reset App Permissions (iOS)

```
Settings → Privacy → Camera/Microphone → [Your App] → Toggle OFF/ON
```

### Reset App Permissions (Android)

```
Settings → Apps → [Your App] → Permissions → Camera/Microphone → Toggle OFF/ON
```

### Verify Agora Token

```bash
# In Firebase Console → Functions → Logs
# Search for: generateAgoraToken
# Should see successful invocations
```

---

## 📝 Test Completion Checklist

- [ ] All 6 checkpoints logged successfully (Web)
- [ ] All 6 checkpoints logged successfully (Mobile)
- [ ] Local video visible (Web)
- [ ] Local video visible (Mobile)
- [ ] Remote user visible (Web → Web)
- [ ] Remote user visible (Mobile → Mobile)
- [ ] Remote user visible (Web → Mobile)
- [ ] Remote user visible (Mobile → Web)
- [ ] Mute/unmute works (Web)
- [ ] Mute/unmute works (Mobile)
- [ ] User leave removes video (Web)
- [ ] User leave removes video (Mobile)
- [ ] 3+ users in same room works
- [ ] Network quality indicators work
- [ ] No console/log errors
- [ ] Performance acceptable (< 3s join)

---

## 🎉 When All Tests Pass

**Your video chat is PRODUCTION READY!**

Next steps:

1. Enable analytics tracking
2. Set up monitoring dashboards
3. Document known issues
4. Train support team on troubleshooting
5. Roll out to beta users
6. Monitor join success rate
7. Iterate based on user feedback

---

## 🆘 Still Having Issues?

If tests fail after following this checklist:

1. **Copy the EXACT logs** from console/terminal
2. Note which **checkpoint fails** (1-6)
3. Note the **platform** (Web/Mobile)
4. Note the **error message** (if any)
5. Use the **FULL PROJECT AUTO-REPAIR PROMPT** with logs

The logs will tell you exactly where the chain breaks.
