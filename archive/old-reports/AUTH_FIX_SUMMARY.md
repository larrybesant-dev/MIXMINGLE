# Authentication Fix Summary for generateAgoraToken

## Problem

Cloud Functions v2 callable function `generateAgoraToken` was returning `[firebase_functions/internal] internal` errors on Flutter Web, with backend logs showing "The request was not authenticated" warnings.

## Root Causes Identified

### 1. Missing Firebase Functions JS SDK in web/index.html

- **Issue**: The web/index.html only initialized Auth, Firestore, Storage, and Messaging—but NOT Cloud Functions
- **Impact**: Flutter Web's cloud_functions package requires the underlying Firebase Functions JS SDK to be initialized
- **Fix**: Added `getFunctions` import and initialized Functions with region 'us-central1'

### 2. Backend function not validating request.auth

- **Issue**: Backend function accepted userId from data payload without verifying request.auth context
- **Impact**: No enforcement of authenticated user identity, potential security risk
- **Fix**: Added request.auth logging and validation to ensure user is authenticated via Firebase SDK

### 3. Frontend not verifying auth state stability before calling function

- **Issue**: Function calls might occur before FirebaseAuth.currentUser is fully initialized
- **Impact**: Callable functions require stable auth context to attach auth headers automatically
- **Fix**: Added auth state verification with timeout fallback before calling generateAgoraToken

## Changes Applied

### Frontend (lib/services/agora_video_service.dart)

```dart
// Before calling generateAgoraToken:
1. Check FirebaseAuth.currentUser != null
2. Await authStateChanges().first with 3-second timeout
3. Log user email, UID, and provider info
4. Remove manual ID token fetching (not needed for callable API)
5. Add detailed logging for debugging
```

### Backend (functions/src/index.ts)

```typescript
// Inside generateAgoraToken handler:
1. Log request.auth.uid and request.auth.token presence
2. Log data.roomId and data.userId for debugging
3. Validate request.auth.uid matches data.userId (warn if mismatch)
4. Throw error if request.auth.uid is missing
5. Keep existing room validation logic intact
```

### Web Configuration (web/index.html)

```javascript
// Added:
import { getFunctions } from "firebase-functions.js";
const functions = getFunctions(app, "us-central1");
window.firebase.functions = functions;
```

## Verification Steps

### 1. Backend Deployment

```bash
cd functions
firebase deploy --only functions:generateAgoraToken
```

✅ **Status**: Deployed successfully at 2026-01-27 04:33 UTC

### 2. Frontend Changes

✅ **Status**: Code updated with auth verification and logging

### 3. Web SDK Configuration

✅ **Status**: Firebase Functions JS SDK added to web/index.html

## Expected Behavior After Fix

### Frontend Logs (Flutter)

```
✅ Step 2: Joining room: [roomId]
✅ Verifying authentication state...
✅ Auth verified - User: user@example.com, UID: abc123...
✅ Requesting Agora token...
✅   roomId: [roomId]
✅   userId: [userId]
✅   FirebaseFunctions region: us-central1
✅   Auth state: VERIFIED
✅ Token response received
✅ Agora token obtained, length: 200+
```

### Backend Logs (Cloud Functions)

```
✅ Callable request verification passed
✅ Auth context - UID: abc123..., Token: PRESENT
✅ Request data - roomId: [roomId], userId: [userId]
✅ Generated Agora token for user [userId] in room [roomId]
```

## Security Improvements

1. **Auth Context Enforcement**: Backend now requires Firebase authentication via request.auth
2. **User Identity Validation**: Warns if requested userId doesn't match authenticated user
3. **Stable Auth State**: Frontend verifies auth is ready before function calls
4. **Proper SDK Integration**: Web platform now uses Firebase Functions JS SDK correctly

## Testing Checklist

- [ ] Run `flutter clean` to clear build cache
- [ ] Run `flutter build web` to rebuild with new index.html
- [ ] Test room joining on Flutter Web (Chrome)
- [ ] Verify no CORS errors in browser console
- [ ] Check backend logs show "Auth context - UID: [present]"
- [ ] Confirm token generation succeeds
- [ ] Verify video/audio streaming works

## Rollback Plan (if needed)

If issues persist:

1. Revert web/index.html to remove Functions SDK
2. Revert backend to previous version without auth checks
3. Check Firebase console for Cloud Run IAM permissions
4. Consider enabling unauthenticated invocations temporarily for debugging

## Next Steps

1. **Test on Flutter Web**: Navigate to room and attempt video call
2. **Monitor logs**: Watch both frontend debugPrint and backend gcloud logs
3. **Verify auth flow**: Ensure no "request not authenticated" warnings
4. **Performance check**: Confirm token generation completes within 2-3 seconds

---

**Auth context aligned between FirebaseAuth and generateAgoraToken. Ready to retest on Flutter Web.**
