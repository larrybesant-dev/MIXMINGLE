# Quick Reference: Auth Flow Test Guide

## 🚀 Ready to Test? Here's Everything You Need

### Start Here

```powershell
# Terminal 1: Clear and run
flutter clean
flutter run -d chrome --no-hot

# Terminal 2: Monitor backend (separate window)
gcloud functions logs read generateAgoraToken --region us-central1 --follow --limit 30
```

### In Browser

- Open Chrome DevTools: **F12**
- Go to **Console** tab (watch logs)
- Go to **Network** tab, filter for `generateAgoraToken`

### User Actions

1. Sign in with Firebase Auth
2. Go to any room
3. Click "Join Room"

---

## 📊 Success Indicators

### Frontend (Console Log Order)

```
✓ Step 2: Joining room: [roomId]
✓ Verifying authentication state...
✓ Auth verified - User: email@example.com, UID: 12345...
✓ Auth provider: password
✓ Web platform - browser will prompt for permissions
✓ Requesting Agora token...
  roomId: [roomId]
  userId: [userId]
  FirebaseFunctions region: us-central1
  Auth state: VERIFIED
✓ Token response received
✓ Agora token obtained, length: 234
```

### Backend (Real-Time Logs)

```
✓ Callable request verification passed
✓ Auth context - UID: 12345, Token: PRESENT
✓ Request data - roomId: [roomId], userId: 12345
✓ Generated Agora token for user 12345 in room [roomId]
```

### Network Tab

| Field                | Should Be      |
| -------------------- | -------------- |
| Method               | POST           |
| Status               | 200            |
| Authorization Header | Bearer [token] |
| CORS Errors          | None           |

---

## 🔴 Red Flags

| Error                        | Cause                   | Fix                                   |
| ---------------------------- | ----------------------- | ------------------------------------- |
| "ERROR: currentUser is null" | Not signed in           | Sign in first                         |
| "Auth context - UID: NONE"   | Web SDK not initialized | Check web/index.html has getFunctions |
| CORS policy error            | Using HTTP GET          | Run `flutter clean`                   |
| Network shows GET            | Old code path           | Run `flutter clean`                   |
| "Authentication required"    | request.auth missing    | Verify web SDK initialized            |
| Video doesn't start          | Permissions denied      | Click "Allow" in browser prompt       |

---

## 📱 What Each Layer Does

### Layer 1: Web Platform

```html
<!-- web/index.html -->
import { getFunctions } from "firebase-functions.js" const functions = getFunctions(app,
'us-central1')
```

**Job**: Initialize Functions SDK to attach auth headers
**Sign of Success**: Network tab shows POST with Authorization header

### Layer 2: Frontend

```dart
// lib/services/agora_video_service.dart
final user = _auth.currentUser;
final authUser = await _auth.authStateChanges().first.timeout(...)
final result = await _functions.httpsCallable('generateAgoraToken').call(...)
```

**Job**: Verify auth is ready, call with user context
**Sign of Success**: Console shows "Auth verified - User: ..."

### Layer 3: Backend

```typescript
// functions/src/index.ts
if (!request.auth?.uid) throw new Error("Authentication required");
logger.debug(`Auth context - UID: ${request.auth?.uid}`);
```

**Job**: Validate auth context, log it, generate token
**Sign of Success**: Logs show "Auth context - UID: [present]"

---

## 🎯 The Test Result

### Best Outcome

```
Frontend ✅ → Auth verified
Network  ✅ → POST with Authorization
Backend  ✅ → Auth context - UID: present
Result   ✅ → Token generated → Video works
```

### Debugging Path

```
Frontend ❌ "currentUser is null"
→ Sign in first

Frontend ✅ but Backend ❌ "UID: NONE"
→ Web SDK not initialized

Frontend ✅ and Backend ✅ but CORS error
→ flutter clean (old HTTP code path)

Network shows GET (not POST)
→ flutter clean (build cache issue)
```

---

## 📋 Before You Start

- [ ] Browser cache cleared (or Incognito window)
- [ ] Flutter cache cleared (`flutter clean` done)
- [ ] Chrome DevTools open and ready
- [ ] You know your test user credentials
- [ ] Second terminal ready for backend logs

---

## 🔍 How to Read the Logs

### Good Frontend Log

```
Auth verified - User: test@example.com, UID: abc123xyz
FirebaseFunctions region: us-central1
Auth state: VERIFIED
```

✅ This means web SDK received your auth context

### Good Backend Log

```
Auth context - UID: abc123xyz, Token: PRESENT
Generated Agora token for user abc123xyz in room test-room
```

✅ This means request.auth was populated by Firebase SDK

### Bad Frontend Log

```
ERROR: FirebaseAuth.currentUser is null
```

❌ User not signed in yet

### Bad Backend Log

```
Auth context - UID: NONE, Token: MISSING
```

❌ Web SDK didn't attach auth headers (config issue)

---

## 💬 Questions During Test?

**Q: Do I see permission prompts?**
A: Yes, normal. Browser asks for camera/mic. Click "Allow".

**Q: How long should token take?**
A: Usually < 500ms. Up to 2-3s is OK.

**Q: What if I see "request was not authenticated"?**
A: Old issue. Run `flutter clean` and try again. Should be fixed now.

**Q: Can I test multiple rooms?**
A: Yes. Each room join should show same log pattern.

**Q: Should I see any errors?**
A: No errors. If you do, check the red flags section.

---

## 🎬 After Success

Once you see:

- ✅ Frontend: "Auth verified"
- ✅ Backend: "Auth context - UID: [present]"
- ✅ Network: POST 200 with Authorization
- ✅ Video: Camera preview appears

**You're done. The auth pipeline is working correctly.**

Document:

1. Screenshot of frontend logs
2. Screenshot of backend logs
3. Screenshot of network tab
4. Note: Token generation time

This confirms the integration is production-ready.

---

**Ready? Run `flutter clean` then `flutter run -d chrome --no-hot`**
