# Auth Flow Test Checklist
# Use this during the next test run to verify all layers are working

## Pre-Test Verification

- [ ] Backend function deployed (firebase deploy completed successfully)
- [ ] web/index.html has getFunctions import
- [ ] web/index.html initializes Functions with region 'us-central1'
- [ ] agora_video_service.dart has authStateChanges().first timeout
- [ ] Firebase Auth and Firebase Functions use same app instance

## During Test Run

### Frontend (Flutter Web Console)

As you navigate to join a room, watch for these logs in order:

```
 Step 2: Joining room: [roomId]
 Verifying authentication state...
 Auth verified - User: [email], UID: [uid]
 Auth provider: [provider]
 Web platform - browser will prompt for permissions
 Requesting Agora token...
   roomId: [roomId]
   userId: [userId]
   FirebaseFunctions region: us-central1
   Auth state: VERIFIED
 Token response received
 Agora token obtained, length: [200+]
```

### Backend (Cloud Functions Logs)

Watch for these in gcloud logs:

```
Callable request verification passed
Auth context - UID: [value], Token: PRESENT
Request data - roomId: [roomId], userId: [userId]
Generated Agora token for user [userId] in room [roomId]
```

### Chrome DevTools - Network Tab

Filter for `generateAgoraToken`:

- [ ] Method should be **POST** (not GET)
- [ ] Status should be **200** (success)
- [ ] Headers should include **Authorization: Bearer [token]**
- [ ] No CORS errors
- [ ] Response should contain **token**, **uid**, **appId**, **channelName**, **role**, **expiresAt**

### Chrome DevTools - Console

**Watch for these to NOT appear:**

- [ ] ❌ CORS policy errors
- [ ] ❌ [firebase_functions/internal] internal
- [ ] ❌ "The request was not authenticated"
- [ ] ❌ 401/403 errors
- [ ] ❌ GET requests to cloudfunctions.net

## Expected Outcomes

### ✅ Success Flow

1. Frontend logs show "Auth verified - User: ..."
2. Frontend logs show "Auth state: VERIFIED"
3. Backend logs show "Auth context - UID: [present]"
4. Network request is POST with Authorization header
5. Token response received without errors
6. Video preview appears (if permissions granted)

### ❌ If Auth Fails

1. Frontend logs show "ERROR: FirebaseAuth.currentUser is null"
   → User not signed in, app redirects to login

2. Backend logs show "Auth context - UID: NONE"
   → Web Functions SDK not initialized or not attaching auth

3. Chrome console shows CORS error
   → Callable API not being used, app falling back to HTTP GET

4. Network tab shows GET request
   → Old HTTP code path still active, do `flutter clean`

5. Backend logs show "request was not authenticated"
   → Auth context missing from callable, web index.html not loaded

## Debugging Commands

If something fails, use these to investigate:

```powershell
# Check backend logs in real-time
gcloud functions logs read generateAgoraToken --region us-central1 --follow --limit 30

# Check if Functions SDK was deployed
gcloud functions describe generateAgoraToken --region us-central1 --gen2

# Verify web/index.html has Functions SDK
Select-String -Path web/index.html -Pattern "firebase-functions"

# Check if agora_video_service.dart has auth verification
Select-String -Path lib/services/agora_video_service.dart -Pattern "authStateChanges"

# Capture full network logs
flutter run -d chrome 2>&1 | Tee-Object -FilePath flutter_debug.log
```

## Signal Values

| Signal | What It Means |
|--------|--------------|
| Frontend: "Auth verified" + Backend: "UID: [present]" | ✅ All three layers working |
| Frontend: "Auth verified" + Backend: "UID: NONE" | ⚠️ Web SDK not initialized |
| Frontend: "ERROR: currentUser is null" | ⚠️ User not authenticated |
| CORS error in console | ⚠️ HTTP GET being used instead of callable |
| Backend: "Authentication required" | ⚠️ request.auth.uid missing |
| Network: POST with Authorization header | ✅ Callable API working |
| Network: GET request | ❌ Old HTTP path, run flutter clean |

## Next Steps After Success

1. [ ] Capture full console logs
2. [ ] Screenshot network tab showing POST request with Authorization header
3. [ ] Verify token generation completes in < 2 seconds
4. [ ] Test with multiple users (different UIDs)
5. [ ] Test across different browser tabs
6. [ ] Document any edge cases found

---

**Remember**: All three layers must be present and working together:
- ✅ Frontend: Auth state verified before callable
- ✅ Backend: Auth context validated in handler
- ✅ Web: Firebase Functions JS SDK initialized with region

If any layer is missing or misconfigured, the error will be caught at that point.
