# 🎯 Agora Integration Test Guide

## ✅ Backend Status
- **Cloud Function**: `getAgoraToken` deployed and working
- **Test Results**: Both test rooms return valid tokens
  - `DoWJnySEtTtEZsaB80RR` ✅
  - `test-room-001` ✅

## ✅ Flutter Integration Status
Your Flutter app is **already wired correctly**:

### 1. Token Service (`agora_token_service.dart`)
```dart
✅ Uses Firebase ID token for auth
✅ Calls HTTP endpoint (not callable function)
✅ Endpoint: https://us-central1-mix-and-mingle-v2.cloudfunctions.net/getAgoraToken
✅ Returns: token, appId, channelName, uid, role, expiresAt
```

### 2. Agora Service (`agora_service.dart`)
```dart
✅ Uses AgoraTokenService to fetch tokens
✅ Initializes Agora RTC engine with appId from token response
✅ Joins channel with token
✅ Handles broadcaster vs audience roles
```

### 3. Room Page (`room_page.dart`)
```dart
✅ Calls agoraService.joinChannel() on initialization
✅ Passes room ID as channelName
✅ Passes user ID
✅ Sets isBroadcaster based on host status
```

---

## 🧪 Test Procedure

### Option 1: Test with Existing Room from Firestore

1. **Start Flutter app**:
   ```powershell
   flutter run -d chrome
   ```

2. **Sign in** with your account (larrybesant@gmail.com)

3. **Join one of these rooms**:
   - `DoWJnySEtTtEZsaB80RR`
   - `test-room-001`

4. **Watch for logs** in Flutter console:
   ```
   ✅ "Successfully joined channel: test-room-001"
   ✅ "Joined Agora channel: test-room-001"
   ```

5. **Expected behavior**:
   - No errors about token generation
   - Local video/audio should initialize
   - Console shows successful channel join

---

### Option 2: Quick Console Test

Run this in the Flutter app's browser console to verify token fetch:

```javascript
// This will show if the token endpoint is being called
console.log('Testing token fetch from Flutter...');
```

Then watch the Network tab for:
- Request to `getAgoraToken?channelName=...`
- Status: 200 OK
- Response includes `token`, `appId`, etc.

---

## 🔍 What to Look For

### Success Indicators:
- ✅ No "Room not found" errors
- ✅ Token successfully fetched
- ✅ Agora engine initialized
- ✅ Channel joined
- ✅ Local user joined event fires

### Common Issues:
- ❌ "Room not found" → Room doesn't exist in Firestore
- ❌ "User not authenticated" → Sign in first
- ❌ "Failed to get ID token" → Token expired, refresh page
- ❌ "Error fetching Agora token" → Check Cloud Function logs

---

## 🎬 Next Steps After Successful Test

Once you confirm the join flow works:

1. **Test with 2 devices** (multi-user)
2. **Test mute/unmute controls**
3. **Test camera toggle**
4. **Test leave/rejoin flow**
5. **Add error handling UI**
6. **Test token expiration handling**

---

## 📊 Current Architecture

```
Flutter App
  └─ Sign In (Firebase Auth)
       └─ Join Room UI
            └─ AgoraService.joinChannel()
                 └─ AgoraTokenService.getToken()
                      └─ HTTP GET with Bearer token
                           └─ Cloud Function: getAgoraToken
                                └─ Validates Firebase auth
                                └─ Checks room exists in Firestore
                                └─ Generates Agora RTC token
                                └─ Returns token + appId
                 └─ Initialize Agora Engine
                 └─ Join Agora Channel
                      └─ SUCCESS! 🎉
```

---

## 🚀 Ready to Test!

Run the app and join `test-room-001` to verify the full pipeline works end-to-end.

Let me know what you see in the console when you join a room!
