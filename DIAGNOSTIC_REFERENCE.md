# Diagnostic Reference - If Something Unexpected Happens

This guide helps you decode any errors that appear during the test and what they mean.

## Frontend Errors (Console)

### Error: "ERROR: FirebaseAuth.currentUser is null"

```
What it means: You clicked "Join Room" before signing in
How to fix: Sign in first with your test credentials
Root cause: Frontend auth verification guard working as intended
```

### Error: "Error state unstable - user is null"

```
What it means: authStateChanges() completed but user was null
How to fix: Sign in again, wait for full auth initialization
Root cause: Very rare race condition, try again
Status: This error prevents bad calls from reaching backend
```

### Error: "Agora token generation failed: [firebase_functions/internal] internal"

```
What it means: Backend callable failed with generic error
Debug steps:
  1. Check backend logs for specific error
  2. Verify web/index.html has getFunctions import
  3. Verify region is us-central1 everywhere
Root cause: Usually missing Firebase Functions JS SDK on web
Fix: flutter clean, rebuild, check web/index.html
```

### Error: "CORS policy: Cross-Origin Request Blocked"

```
What it means: Browser blocked cross-origin request
Root cause: Still using old HTTP GET code path
Fix: Run flutter clean, rebuild
Verify: Network tab should show POST not GET
Prevention: No direct http.get() calls in codebase now
```

### Error: "Cannot read properties of undefined (reading 'createIrisApiEngine')"

```
What it means: Agora SDK initialization failed
Root cause: Agora app ID not loaded or permissions issue
Not related to: Auth flow (this is platform-specific)
What to do: Check Agora SDK initialization logs earlier in console
```

---

## Backend Errors (Cloud Functions Logs)

### Log: "Auth context - UID: NONE, Token: MISSING"

```
What it means: request.auth was null/undefined on backend
Root cause: Firebase Functions JS SDK not initialized on web
Debug:
  1. Check network tab - request should have Authorization header
  2. Check web/index.html - must have getFunctions import
  3. Check web/index.html - must have region us-central1
Fix: Ensure web/index.html properly imports and initializes Functions
```

### Log: "Error: Authentication required. Please ensure you are signed in."

```
What it means: Backend caught missing request.auth.uid and threw error
Root cause: Same as above - web SDK not attaching auth
This error is: Good - backend is validating correctly
Fix: Fix the web SDK initialization
```

### Log: "Auth mismatch: request.auth.uid=X but data.userId=Y"

```
What it means: User asking for token for different user
Root cause: Usually shouldn't happen - indicates user passed wrong userId
Severity: Warning only (not error)
What to do: Verify frontend is passing user.uid correctly
Check: Line in agora_video_service.dart where userId is passed
```

### Log: "Room not found"

```
What it means: You tried to join a room that doesn't exist
Root cause: Room ID invalid or room was deleted
Fix: Use an existing room ID from Firebase
Verify: Room must exist in Firestore with isLive: true
```

### Log: "User is banned from this room"

```
What it means: User's UID is in room.bannedUsers array
Root cause: User was banned by room host
Fix: Create new account or ask host to unban
Verify: Check Firestore room document for bannedUsers field
```

### Log: "User was removed from this room"

```
What it means: User's UID is in room.kickedUsers array
Root cause: User was kicked by room host
Fix: Create new account or ask host to allow re-entry
Verify: Check Firestore room document for kickedUsers field
```

### Log: "Room has ended"

```
What it means: Room isLive is false or status is 'ended'
Root cause: Host ended the broadcast
Fix: Create new room or ask host to restart
Verify: Room document shows isLive: false
```

### Log: "Agora credentials missing"

```
What it means: AGORA_APP_ID or AGORA_APP_CERTIFICATE secrets not set
Root cause: Secrets not configured in Cloud Functions
Fix: Set secrets in Firebase:
  firebase functions:secrets:set AGORA_APP_ID
  firebase functions:secrets:set AGORA_APP_CERTIFICATE
Deploy: firebase deploy --only functions:generateAgoraToken
```

---

## Network Tab Anomalies (Chrome DevTools)

### Request Method is GET (not POST)

```
Problem: Old HTTP code path still active
Root cause: flutter clean didn't work or stale browser cache
Fix:
  1. Run: flutter clean
  2. Close browser completely
  3. Run: flutter run -d chrome --no-hot
  4. Open new browser window
```

### Status 400 Bad Request

```
Problem: Invalid request format
Root cause: Usually wrong region or malformed payload
Check:
  1. Is region us-central1?
  2. Is payload valid JSON?
  3. Are roomId and userId both present?
Fix: Rebuild and verify region configuration
```

### Status 401 Unauthorized

```
Problem: Authorization header missing or invalid
Root cause: Web SDK not attaching auth token
Fix: Check web/index.html has complete Firebase setup
Verify: Request headers should show: Authorization: Bearer [token]
```

### Status 403 Forbidden

```
Problem: Cloud Run IAM permissions issue
Root cause: Unlikely if backend deployed correctly
Fix: Check function IAM settings
Verify: Function should allow Cloud Functions Invoker
Deploy: firebase deploy --only functions:generateAgoraToken
```

### Status 500 Internal Server Error

```
Problem: Backend exception (not [firebase_functions/internal])
Root cause: Bug in token generation logic
Fix: Check backend logs for specific error
Example: "Agora credentials missing"
Debug: Most common cause is missing secrets
```

### No Authorization Header in Request

```
Problem: Web SDK didn't attach auth context
Root cause: Web platform Firebase SDK not initialized
Fix:
  1. Check web/index.html has getFunctions import
  2. Check getFunctions(app, 'us-central1') called
  3. Check Functions exposed to window.firebase.functions
Action: flutter clean and rebuild
```

### Request Takes >3 Seconds

```
Problem: Slow response (not necessarily bad)
Normal range: 200-800ms
Acceptable: Up to 2-3 seconds
Slow: Over 3 seconds
Root cause: Cold start, Firestore queries, or network
What to do: Nothing - will warm up with repeated calls
Future improvement: Consider caching room data
```

---

## Combined Error Scenarios

### Frontend "Auth verified" + Backend "UID: NONE"

```
Signal: Mixed success/failure
Root cause: Web SDK issue specifically
Not: Frontend auth problem
Not: Backend logic problem
What it means: Frontend is authenticated but web platform isn't passing auth
Fix: Focus on web/index.html Firebase Functions initialization
Check:
  1. Is getFunctions imported?
  2. Is region us-central1?
  3. Is functions on window.firebase?
```

### Frontend "Auth verified" + Network shows GET

```
Signal: Frontend worked but wrong API being called
Root cause: Old HTTP code path still in build
What it means: flutter clean didn't fully clear
Fix: Complete flutter clean, clear browser cache, rebuild
Verify: No http.get() to cloudfunctions URLs in codebase
```

### Everything looks good but video doesn't appear

```
Not an auth problem (auth succeeded)
Likely cause: Permissions denied or Agora initialization
What to do: Check browser console for permission errors
Expected: Browser should prompt "Allow camera/microphone"
If denied: Click "Allow" and try again
```

---

## Quick Diagnostic Checklist

If you see an error, use this to narrow it down:

```
[] Is user signed in?
   NO → Sign in first
   YES → Continue

[] Frontend shows "Auth verified"?
   NO → User not signed in or auth unstable
   YES → Continue

[] Backend shows "Auth context - UID: [present]"?
   NO → Web SDK not attached auth, check web/index.html
   YES → Continue

[] Network tab shows POST (not GET)?
   NO → Old code path active, flutter clean
   YES → Continue

[] Network tab shows Authorization header?
   NO → Web SDK issue, check web/index.html
   YES → Continue

[] Status code is 200?
   NO → Check status code in error table above
   YES → Continue

[] Response has 'token' field?
   NO → Backend error, check logs
   YES → Success - token generated

[] Video preview appears?
   NO → Permissions denied, click Allow
   YES → ✅ Auth pipeline working!
```

---

## Debug Commands Reference

```powershell
# See real-time backend logs
gcloud functions logs read generateAgoraToken --region us-central1 --follow

# Check last 50 lines of backend logs
gcloud functions logs read generateAgoraToken --region us-central1 --limit 50

# Check if functions SDK is in web/index.html
Select-String -Path web/index.html -Pattern "firebase-functions"

# Check for any HTTP calls to cloudfunctions
Select-String -Path lib -Filter "*.dart" -Recurse -Pattern "cloudfunctions.*http"

# Clear all Flutter build artifacts
flutter clean

# Show device logs during app run
flutter run -d chrome 2>&1 | Tee-Object -FilePath debug_run.log

# Extract just error lines from run log
Select-String -Path debug_run.log -Pattern "error|ERROR|Error|exception|EXCEPTION"
```

---

## Success Confirmation

You've successfully diagnosed and fixed the auth pipeline when:

1. **Frontend logs**

   ```
   ✅ Auth verified - User: [email], UID: [uid]
   ✅ Auth state: VERIFIED
   ✅ Token response received
   ```

2. **Backend logs**

   ```
   ✅ Auth context - UID: [uid], Token: PRESENT
   ✅ Generated Agora token for user [uid]
   ```

3. **Network tab**

   ```
   ✅ Method: POST
   ✅ Status: 200
   ✅ Authorization: Bearer [token]
   ```

4. **User experience**
   ```
   ✅ Video preview appears
   ✅ Permissions accepted
   ✅ Room joined successfully
   ```

Once all four are confirmed, the auth integration is production-ready.

---

**Remember**: Each layer validates its piece. If one fails, the error tells you which layer has the problem.
