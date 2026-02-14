# SAFE TEST PIPELINE — FLUTTER WEB + GEN2 CALLABLE

## Terminal 1: Flutter Web Build & Run

Execute these commands in order:

```bash
flutter clean
flutter pub get
flutter run -d chrome --no-hot
```

**What each command does:**
- `flutter clean` — Removes all build artifacts, .dart_tool, and ephemeral files
- `flutter pub get` — Downloads and resolves all pub dependencies
- `flutter run -d chrome --no-hot` — Launches app in Chrome, disables hot reload for clean state

**Expected output:**
- After ~30-40 seconds: "Waiting for connection from debug service on Chrome..."
- After ~50-60 seconds total: App loads in Chrome, console starts showing logs
- You should see: "Step 1: Initializing Agora SDK..."

---

## Terminal 2: Stream Gen 2 Cloud Functions Logs

**Option A (Recommended - Firebase CLI):**

```bash
firebase functions:log --only generateAgoraToken
```

**Option B (Google Cloud alternative):**

```bash
gcloud run services logs tail generateAgoraToken --region us-central1
```

**Why these commands:**
- `firebase functions:log` — Works with Gen 2 functions, streaming mode
- `gcloud run services logs tail` — Alternative if Firebase CLI not available
- `--only generateAgoraToken` — Filters to only your function logs
- `--region us-central1` — Specifies where function is deployed

**Expected output:**
- Function logs appear in real-time as calls are made
- You should see: "Callable request verification passed"
- You should see: "Auth context - UID: [value], Token: PRESENT"
- You should see: "Generated Agora token for user [uid]"

---

## Test Execution Sequence

### Step 1: Prepare (5 minutes before test)
```bash
# Verify Flutter is ready
flutter --version

# Verify Chrome is available
where chrome

# Verify Firebase credentials
firebase projects:list
```

### Step 2: Open Two Terminals

**Terminal 1 (Flutter Web App):**
```bash
cd c:\Users\LARRY\MIXMINGLE
flutter clean
flutter pub get
flutter run -d chrome --no-hot
```

**Terminal 2 (Function Logs - separate window):**
```bash
cd c:\Users\LARRY\MIXMINGLE
firebase functions:log --only generateAgoraToken
```

### Step 3: Browser Setup
- Chrome will auto-open at `http://localhost:5000`
- Open DevTools: **F12**
- Go to **Console** tab (watch for auth and token logs)
- Go to **Network** tab, filter for "generateAgoraToken"

### Step 4: User Flow
1. Sign in with test credentials
2. Navigate to a room
3. Click "Join Room"
4. Watch both terminals and browser console

### Step 5: Observe

**Frontend Console (Terminal 1 output):**
```
✓ Step 2: Joining room: [roomId]
✓ Verifying authentication state...
✓ Auth verified - User: [email], UID: [uid]
✓ Requesting Agora token...
✓ FirebaseFunctions region: us-central1
✓ Auth state: VERIFIED
✓ Token response received
```

**Backend Logs (Terminal 2 output):**
```
✓ Callable request verification passed
✓ Auth context - UID: [value], Token: PRESENT
✓ Request data - roomId: [roomId], userId: [userId]
✓ Generated Agora token for user [uid] in room [roomId]
```

**Network Tab (Chrome DevTools):**
```
Method: POST
Status: 200
Headers: Authorization: Bearer [token]
CORS: No errors
```

---

## Safety Verification

**Commands are safe because they:**
- ✅ Use only official Flutter commands
- ✅ Use only official Firebase/gcloud commands
- ✅ Do not modify configuration files
- ✅ Do not change environment variables
- ✅ Do not delete or replace files (only artifacts in .dart_tool)
- ✅ Are read-only for log streaming
- ✅ Can be interrupted with Ctrl+C without side effects
- ✅ Can be re-run multiple times without issues

**No configuration changes:**
- ✅ web/index.html not touched
- ✅ lib files not touched
- ✅ functions/src not touched
- ✅ Firebase credentials not touched
- ✅ .env files not touched

---

## Quick Troubleshooting

| Issue | Solution |
|-------|----------|
| Chrome doesn't open | Open manually at `http://localhost:5000` |
| "Waiting for connection" > 2 min | Ctrl+C, run `flutter clean` again |
| No logs in Terminal 2 | Try `gcloud run services logs tail` alternative |
| "currentUser is null" | Sign in first in browser |
| CORS error | Ctrl+C all, `flutter clean`, rebuild |

---

## Abort Procedure

If anything goes wrong, stop immediately:

**Terminal 1:**
```bash
Ctrl+C
```

**Terminal 2:**
```bash
Ctrl+C
```

**Browser:**
- Close Chrome tab or window

Then run `flutter clean` and restart.

---

## Success Criteria

Test passes when you see:
1. ✅ Frontend: "Auth verified - User: [email]"
2. ✅ Backend: "Auth context - UID: [value]"
3. ✅ Network: POST 200 with Authorization header
4. ✅ No CORS, internal, or authentication errors

---

## Command Reference (Copy-Paste Ready)

### Flutter Build (Terminal 1)
```
flutter clean
flutter pub get
flutter run -d chrome --no-hot
```

### Function Logs (Terminal 2)
```
firebase functions:log --only generateAgoraToken
```

### Fallback Logs Command (if above fails)
```
gcloud run services logs tail generateAgoraToken --region us-central1
```

---

**Ready. Execute Terminal 1 first, then Terminal 2 in a new window.**
