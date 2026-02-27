# 🔐 Agora Token Server Setup Guide

This guide walks you through setting up the Agora token server for Mix & Mingle.

## ✅ What's Been Created

1. **Cloud Functions** (`functions/`)
   - `index.js` - Token generation endpoint
   - `package.json` - Dependencies
   - `.gitignore`

2. **Flutter Service** (`lib/services/agora_token_service.dart`)
   - Fetches tokens from Cloud Function
   - Authenticates with Firebase ID token
   - Handles token expiration

3. **Security Features**
   - Firebase Auth verification
   - Private room access control
   - Automatic participant cleanup
   - Join/leave system messages

## 🚀 Deployment Steps

### 1. Install Firebase CLI (if not already installed)

```bash
npm install -g firebase-tools
firebase login
```

### 2. Initialize Firebase Functions (if not already done)

```bash
firebase init functions
# Select: Use existing project
# Select: mix-and-mingle-v2
# Language: JavaScript
# ESLint: No (or Yes, up to you)
# Install dependencies: Yes
```

### 3. Copy Function Files

The files are already created in `functions/` directory:

- ✅ `functions/package.json`
- ✅ `functions/index.js`
- ✅ `functions/.gitignore`

### 4. Install Dependencies

```bash
cd functions
npm install
cd ..
```

### 5. Configure Agora Credentials

**Get your credentials from Agora Console:**

1. Go to https://console.agora.io/
2. Select your project (or create one)
3. Copy **App ID**
4. Enable **App Certificate** and copy it

**Set credentials in Firebase:**

```bash
firebase functions:config:set agora.app_id="YOUR_AGORA_APP_ID"
firebase functions:config:set agora.app_certificate="YOUR_AGORA_APP_CERTIFICATE"
```

**Verify configuration:**

```bash
firebase functions:config:get
```

Should show:

```json
{
  "agora": {
    "app_id": "your_app_id",
    "app_certificate": "your_certificate"
  }
}
```

### 6. Deploy Functions

```bash
firebase deploy --only functions
```

This deploys:

- ✅ `getAgoraToken` - HTTP endpoint for token generation
- ✅ `cleanupRoomParticipants` - Scheduled cleanup (every 5 minutes)
- ✅ `onParticipantChange` - Firestore trigger for join/leave events

### 7. Update Cloud Function URL in Flutter

After deployment, you'll see the function URL:

```
https://us-central1-mix-and-mingle-v2.cloudfunctions.net/generateAgoraToken
```

Update in `lib/services/agora_token_service.dart` if different:

```dart
AgoraTokenService({
  cloudFunctionUrl: 'YOUR_ACTUAL_FUNCTION_URL',
})
```

## 🔧 Testing the Token Server

### Test with curl:

```bash
# Get Firebase ID token first
firebase auth:export users.json
# Or get from browser console: await firebase.auth().currentUser.getIdToken()

# Test token endpoint
curl -X GET \
  "https://us-central1-mix-and-mingle-v2.cloudfunctions.net/generateAgoraToken?channelName=test-room&uid=12345&role=broadcaster" \
  -H "Authorization: Bearer YOUR_ID_TOKEN"
```

Expected response:

```json
{
  "token": "00685f...",
  "appId": "your_app_id",
  "channelName": "test-room",
  "uid": 12345,
  "role": 1,
  "expiresAt": 1706342400000
}
```

## 🎯 Using in Flutter

The service is ready to use in your room joining flow:

```dart
import 'package:mixmingle/services/agora_token_service.dart';

// In your room service or provider:
final tokenService = AgoraTokenService();

Future<void> joinRoom(String roomId, String userRole) async {
  final uid = AgoraTokenService.uidFromString(currentUserId);

  // Fetch token
  final tokenResponse = await tokenService.getToken(
    channelName: roomId,
    uid: uid,
    role: userRole == 'host' || userRole == 'speaker' ? 'broadcaster' : 'audience',
  );

  // Initialize Agora with token
  await agoraEngine.joinChannel(
    token: tokenResponse.token,
    channelId: roomId,
    uid: uid,
    options: ChannelMediaOptions(
      clientRoleType: userRole == 'host' || userRole == 'speaker'
        ? ClientRoleType.clientRoleBroadcaster
        : ClientRoleType.clientRoleAudience,
    ),
  );
}
```

## 🔒 Security Rules Update

Update `firestore.rules` to allow Cloud Functions to write system messages:

```javascript
match /rooms/{roomId}/messages/{messageId} {
  allow read: if request.auth != null;
  allow create: if request.auth != null || request.auth.token.firebase.sign_in_provider == 'custom';
}
```

## 📊 Monitoring

**View function logs:**

```bash
firebase functions:log
```

**View specific function:**

```bash
firebase functions:log --only getAgoraToken
```

**Real-time logs:**

```bash
firebase functions:log --only getAgoraToken --follow
```

## 🐛 Troubleshooting

### "Agora credentials not configured"

Run:

```bash
firebase functions:config:set agora.app_id="YOUR_APP_ID"
firebase functions:config:set agora.app_certificate="YOUR_CERTIFICATE"
firebase deploy --only functions
```

### "401 Unauthorized"

- Ensure user is logged in
- Check Firebase ID token is valid
- Verify Authorization header format: `Bearer TOKEN`

### "404 Room not found"

- Room must exist in Firestore first
- Check room ID matches exactly

### "403 Access denied: Private room"

- User must be in participants subcollection
- Or be the room host

## ⚡ Next Steps

1. ✅ Deploy token server
2. 🔄 Update `agora_service.dart` to use token service
3. 🔄 Update room joining flow to fetch tokens
4. 🔄 Test video/audio in browser
5. 🎨 Add UI for speaker requests
6. 🛡️ Add moderation controls

---

**Need help?** Check Firebase Console → Functions for deployment status and logs.
