# Complete Auth Flow - Ready for Test

## ✅ All Three Layers Verified and Configured

### Layer 1: Web Platform (web/index.html)
✅ Firebase Functions JS SDK imported
✅ `getFunctions(app, 'us-central1')` initialized
✅ Functions exposed as `window.firebase.functions`
✅ Same app instance used for Auth, Firestore, Functions

```javascript
import { getFunctions, connectFunctionsEmulator } from "firebase-functions.js";
const functions = getFunctions(app, 'us-central1');
window.firebase.functions = functions;
```

### Layer 2: Frontend Auth (lib/services/agora_video_service.dart)
✅ Auth state verified before callable
✅ `authStateChanges().first` with 3-second timeout
✅ Detailed logging of user email, UID, provider
✅ FirebaseAuth.instance (default app)
✅ FirebaseFunctions.instanceFor(region: 'us-central1')

```dart
// Verify auth state is ready
final authUser = await _auth.authStateChanges().first.timeout(
  const Duration(seconds: 3),
  onTimeout: () => user,
);

// Only proceed if auth is stable
if (authUser == null) {
  throw Exception('Authentication state not ready');
}

// Call callable with full logging
final result = await _functions.httpsCallable('generateAgoraToken').call({
  'roomId': roomId,
  'userId': user.uid,
});
```

### Layer 3: Backend Auth (functions/src/index.ts)
✅ Logs request.auth.uid and request.auth.token
✅ Validates request.auth exists
✅ Warns on user ID mismatch
✅ Clear error if auth context missing

```typescript
// Log auth context
logger.debug(`Auth context - UID: ${request.auth?.uid || 'NONE'}, Token: ${request.auth?.token ? 'PRESENT' : 'MISSING'}`);

// Validate auth
if (!request.auth?.uid) {
  logger.error('Request missing auth context - user not authenticated via Firebase SDK');
  throw new Error('Authentication required. Please ensure you are signed in.');
}
```

## 🚀 Ready for Test

### Build Cache
✅ Cleared (flutter clean completed)

### Backend Deployment
✅ Deployed successfully on 2026-01-27 04:33 UTC

### Configuration Consistency
✅ All services use same Firebase app (mix-and-mingle-v2)
✅ All services use same region (us-central1)
✅ No direct HTTP calls to Cloud Functions

### HTTP Bypass Prevention
✅ Verified: No stray GET/POST to cloudfunctions.net URLs
✅ Verified: No manual Authorization header injection
✅ Verified: Callable API is the only path to generateAgoraToken

## 📋 Test Procedure

### Terminal 1: Start App
```powershell
flutter run -d chrome --no-hot
```

### Terminal 2: Monitor Backend (in another PowerShell window)
```powershell
gcloud functions logs read generateAgoraToken --region us-central1 --follow --limit 30
```

### Browser: Chrome DevTools
- Open F12 → Console (watch for auth/token logs)
- Network tab (filter for "generateAgoraToken", verify POST with Authorization header)

### User Flow
1. Sign in with Firebase Auth
2. Navigate to a room
3. Click "Join Room"

## 🔍 What to Watch For

### Frontend Console (should appear in order)
```
✓ Step 2: Joining room: [roomId]
✓ Verifying authentication state...
✓ Auth verified - User: [email], UID: [uid]
✓ Requesting Agora token...
✓ FirebaseFunctions region: us-central1
✓ Auth state: VERIFIED
✓ Token response received
✓ Agora token obtained
```

### Backend Logs (should appear immediately after frontend request)
```
✓ Callable request verification passed
✓ Auth context - UID: [value], Token: PRESENT
✓ Request data - roomId: [roomId], userId: [userId]
✓ Generated Agora token for user [userId] in room [roomId]
```

### Network Tab (Chrome DevTools)
- Filter: `generateAgoraToken`
- Method: **POST** ✅
- Status: **200** ✅
- Headers: **Authorization: Bearer [token]** ✅
- No CORS errors ✅

## 🎯 Success Criteria

✅ Frontend logs show "Auth verified"
✅ Backend logs show "Auth context - UID: [present]"
✅ Network request is POST with Authorization header
✅ Token response received
✅ No errors in console
✅ Video preview appears (if permissions granted)

## ⚠️ Troubleshooting Quick Reference

| Symptom | Likely Cause | Fix |
|---------|--------------|-----|
| Frontend: "ERROR: currentUser is null" | User not signed in | Sign in first |
| Backend: "UID: NONE" | Web SDK not initialized | Check web/index.html has getFunctions |
| CORS error in console | HTTP GET being used | flutter clean + rebuild |
| Network shows GET request | Old code path active | flutter clean |
| Backend: "Authentication required" | request.auth missing | Verify web SDK initialized |

## 📊 Layer Alignment Check

All three must be true for success:

```
Frontend: Auth state verified before callable
  ↓
Backend: request.auth.uid present in handler
  ↓
Web: Firebase Functions JS SDK initialized with region
  ↓
✅ Token generated successfully
```

If any layer fails:
- Frontend null → user not signed in
- Backend uid null → web SDK issue
- Web sdk missing → no auth context available

---

**System is ready for comprehensive end-to-end test. All three auth layers are aligned and configured correctly.**

Proceed with: `flutter run -d chrome --no-hot`
