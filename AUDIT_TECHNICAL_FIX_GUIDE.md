# 🔧 MixMingle Production Audit - TECHNICAL FIX GUIDE

**Target Audience**: Development Team
**Difficulty**: Medium
**Est. Time**: 6-12 hours for all fixes

---

## P0 CRITICAL FIXES (2-4 Hours - DO FIRST)

### P0.1: Fix Auth Mismatch in Agora Token Generation

**Issue**: Users can request tokens for other users (security vulnerability)

**File**: `functions/lib/index.js`

**Step 1**: Locate the vulnerable code

```javascript
// Find this around line 49:
exports.generateAgoraToken = functions.https.onCall(async (data, context) => {
  const userId = data.userId;
  const roomId = data.roomId;

  // This is the vulnerable check:
  if (request.auth.uid !== userId) {
    console.warn('⚠️ Auth mismatch: caller uid differs from requested userId');
    // ❌ ONLY WARNS - DOES NOT REJECT
  }
```

**Step 2**: Replace with secure version

```javascript
exports.generateAgoraToken = functions.https.onCall(async (data, context) => {
  const userId = data.userId;
  const roomId = data.roomId;

  // Enforce strict authentication
  if (context.auth.uid !== userId) {
    console.error(`[SECURITY] Auth mismatch detected:`);
    console.error(`  Caller UID: ${context.auth.uid}`);
    console.error(`  Requested UID: ${userId}`);
    console.error(`  Room ID: ${roomId}`);
    console.error(`  Timestamp: ${new Date().toISOString()}`);

    // 🔴 REJECT - Don't just warn
    throw new functions.https.HttpsError(
      "permission-denied",
      "Cannot generate token for different user. Authentication mismatch detected.",
    );
  }

  // If we get here, auth check passed
  console.log(`✅ Auth check passed for user ${userId} in room ${roomId}`);

  // ... rest of token generation code continues ...
});
```

**Step 3**: Test the fix locally

```bash
cd functions
npm run serve
```

Then in another terminal, test with:

```bash
# Test 1: Same user (should work)
curl -X POST http://localhost:5001/YOUR_PROJECT/us-central1/generateAgoraToken \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer USER_A_TOKEN" \
  -d '{"userId": "USER_A_UID", "roomId": "room123"}'
# Expected: 200 OK with token

# Test 2: Different user (should fail)
curl -X POST http://localhost:5001/YOUR_PROJECT/us-central1/generateAgoraToken \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer USER_A_TOKEN" \
  -d '{"userId": "USER_B_UID", "roomId": "room123"}'
# Expected: 403 Forbidden
```

**Step 4**: Deploy to production

```bash
cd functions
npm run build
firebase deploy --only functions:generateAgoraToken
```

**Verification**:

```bash
# Check deployment
firebase functions:list

# Monitor logs
firebase functions:log --only generateAgoraToken
```

**Time**: ~30 minutes

---

### P0.2: Move Agora App ID Out of Firestore

**Issue**: Agora App ID readable by all authenticated users (security vulnerability)

**File**: `lib/services/agora_video_service.dart`

**Step 1**: Identify current vulnerable code

```dart
// Around line 112 in agora_video_service.dart
class AgoraVideoService {
  Future<void> initialize() async {
    // ❌ VULNERABLE: App ID is fetchable by any user
    final configDoc = await _firestore
        .collection('config')
        .doc('agora')
        .get();

    final appId = configDoc.data()?['appId'] ?? '';

    // App is now exposed - any user with Firestore access can read this
    await RtcEngine.create(appId);
  }

  Future<String> getAgoraToken(String userId, String roomId) async {
    // Currently might be getting token directly with exposed App ID
  }
}
```

**Step 2**: Update to use Cloud Function instead

```dart
import 'package:cloud_functions/cloud_functions.dart';

class AgoraVideoService {
  static const String _functionRegion = 'us-central1';

  Future<void> initialize() async {
    // ✅ App ID is now backend-only
    // No need to fetch it here anymore
    _logger.info('Agora service initialized (app ID stored on backend)');
  }

  /// Get Agora token from Cloud Function (never exposes App ID to client)
  Future<String> getAgoraToken(String userId, String roomId) async {
    try {
      final callable = FirebaseFunctions.instanceFor(region: _functionRegion)
          .httpsCallable('generateAgoraToken');

      final result = await callable.call({
        'userId': userId,
        'roomId': roomId,
      });

      // Result should contain:
      // { token: '...', channelName: 'roomId', uid: userId }
      final token = result.data['token'] as String?;

      if (token == null || token.isEmpty) {
        throw Exception('Failed to generate Agora token - no token in response');
      }

      return token;
    } catch (e) {
      _logger.error('Failed to get Agora token: $e');
      rethrow;
    }
  }

  /// (Optional) Renew token periodically during long calls
  Future<void> renewToken(String userId, String roomId) async {
    try {
      final newToken = await getAgoraToken(userId, roomId);
      // Use renewToken method from Agora SDK
      await RtcEngine.instance.renewToken(newToken);
    } catch (e) {
      _logger.error('Failed to renew token: $e');
    }
  }
}
```

**Step 3**: Update Cloud Function to NOT return App ID

```javascript
// functions/lib/index.js - in generateAgoraToken function
// Make sure this code ONLY returns the token, never the App ID:

const agoraAppId = process.env.AGORA_APP_ID;
const agoraCertificate = process.env.AGORA_APP_CERTIFICATE;

// ✅ CORRECT - Only returns token and metadata
return {
  token: token,
  channelName: roomId,
  uid: parseInt(userId),
  expirationTimeInSeconds: 3600,
};

// ❌ WRONG - Never do this:
// return { appId: agoraAppId, token: token }; // DON'T DO THIS
```

**Step 4**: Delete Agora config from Firestore

```dart
// Run this once to clean up the exposed config
void main() async {
  await Firebase.initializeApp();

  final firestore = FirebaseFirestore.instance;

  // Delete the exposed config document
  await firestore.collection('config').doc('agora').delete();

  print('✅ Removed Agora config from Firestore');
}
```

Or in Firebase Console:

1. Go to Firestore Database
2. Collection: `config`
3. Document: `agora`
4. Click "Delete document"

**Step 5**: Update environment variables

```bash
# In functions/.env (Firebase Functions emulator)
AGORA_APP_ID=your_app_id_here
AGORA_APP_CERTIFICATE=your_certificate_here

# Make sure these are NOT in Firestore anymore
```

**Step 6**: Test the changes

```bash
# Test 1: Verify Cloud Function returns token (no App ID)
curl -X POST https://YOUR_REGION-YOUR_PROJECT.cloudfunctions.net/generateAgoraToken \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"userId": "USER_UID", "roomId": "test_room"}' \
  | jq '.data'
# Should see: { token: "...", channelName: "test_room", uid: 123 }
# Should NOT see: { appId: "..." }

# Test 2: Verify Firestore config is deleted
firebase firestore:get config/agora
# Should return: "No document found"

# Test 3: Call getAgoraToken from app
final token = await agoraService.getAgoraToken(uid, roomId);
print(token); // Should print token, not App ID
```

**Step 7**: Deploy

```bash
# Deploy app
flutter build web --release
firebase deploy --only hosting

# Deploy functions (already updated)
firebase deploy --only functions

# Verify
firebase functions:list
firebase functions:log --only generateAgoraToken
```

**Time**: ~45 minutes

---

### P0.3: Remove All 50+ Debug Prints

**Issue**: Debug prints spam production logs and may expose sensitive data

**Files**: Multiple (auth_service.dart, agora_video_service.dart, etc.)

**Step 1**: Find all debug prints

```bash
# PowerShell
Get-ChildItem -Recurse -Filter "*.dart" -Path "lib" |
  Select-String "debugPrint|print\(" |
  Group-Object FileName

# Or use VS Code Find:
# Ctrl+Shift+F, search for: debugPrint\(
```

**Step 2**: Create a filter utility

```dart
// lib/core/logging/debug_log.dart (create this file)
import 'dart:developer' as developer;

/// Production-safe logging
class DebugLog {
  static void info(String message) {
    developer.log(message, level: 800, name: 'MixMingle');
  }

  static void debug(String message) {
    if (shouldLog) {
      developer.log(message, level: 500, name: 'MixMingle.Debug');
    }
  }

  static void error(String message) {
    developer.log(message, level: 1000, name: 'MixMingle.Error');
  }

  static bool get shouldLog {
    // Only log in debug mode
    return kDebugMode;
  }
}
```

**Step 3**: Replace debugPrints systematically

```dart
// BEFORE:
import 'package:flutter/foundation.dart';

Future<void> signIn(String email, String password) async {
  try {
    debugPrint('🔴 Firebase Auth Error: ${e.code}');
    debugPrint('🔴 Message: ${e.message}');
  } catch (e) {
    debugPrint('Error: $e');
  }
}

// AFTER:
import 'package:mix_and_mingle/core/logging/debug_log.dart';

Future<void> signIn(String email, String password) async {
  try {
    DebugLog.error('Auth error: ${e.code}');
    // Don't log message directly - might expose sensitive data
    _errorTracking.recordError(e, stack);
  } catch (e) {
    DebugLog.error('Unexpected sign in error');
    _errorTracking.recordError(e, stack);
  }
}
```

**Step 4**: Script to replace all instances

```bash
# PowerShell script to replace debugPrint
$files = Get-ChildItem -Recurse -Filter "*.dart" -Path "lib"

foreach ($file in $files) {
  $content = Get-Content $file.FullName -Raw

  # Replace simple debugPrint patterns
  $content = $content -replace 'debugPrint\([^)]*\);', ''

  # Add import if using DebugLog
  if ($content -match 'DebugLog\.') {
    if ($content -notmatch "import 'package:mix_and_mingle/core/logging/debug_log.dart';") {
      $content = "import 'package:mix_and_mingle/core/logging/debug_log.dart';" + "`n" + $content
    }
  }

  Set-Content $file.FullName $content
}

Write-Host "✅ Replaced all debugPrints"
```

**Step 5**: Verify removal

```bash
flutter analyze
flutter pub get
flutter build web --release
```

**Time**: ~45 minutes

---

### P0.4: Replace 8 Force Unwraps (!)

**Issue**: Force unwraps crash app if null values occur

**Locations**:

- `lib/app_routes.dart:589`
- `lib/services/camera_service.dart:122`
- `lib/services/auto_moderation_service.dart` (6 locations)

**Step 1**: Find all force unwraps

```bash
# PowerShell
Get-ChildItem -Recurse -Filter "*.dart" -Path "lib" |
  Select-String "!\s*[,;)]" |
  Where-Object { $_ -notmatch "// !" }  # Exclude comments
```

**Step 2**: Fix each one

**Example 1: app_routes.dart:589**

```dart
// BEFORE (CRASH RISK):
final arguments = settings.arguments as Map<String, dynamic>!;
final roomId = arguments['roomId'] as String!;

// AFTER (SAFE):
final arguments = settings.arguments as Map<String, dynamic>?;
if (arguments == null) {
  _logger.error('Route ${settings.name} received no arguments');
  return MaterialPage(builder: (_) => const ErrorPage());
}

final roomId = arguments['roomId'] as String?;
if (roomId == null) {
  _logger.error('roomId missing from route arguments');
  return MaterialPage(builder: (_) => const ErrorPage());
}
```

**Example 2: camera_service.dart:122**

```dart
// BEFORE (CRASH RISK):
final permission = await Permission.camera.request()!;
if (permission.isGranted) { ... }

// AFTER (SAFE):
final permission = await Permission.camera.request();
if (permission == null) {
  _logger.error('Camera permission request returned null');
  return false;
}
if (permission.isGranted) { ... }
```

**Example 3: auto_moderation_service.dart (multiple)**

```dart
// BEFORE (CRASH RISK):
final user = users.firstWhere((u) => u.id == userId)!;
final message = room.messages.last!;

// AFTER (SAFE):
final user = users.firstWhereOrNull((u) => u.id == userId);
if (user == null) {
  _logger.error('User $userId not found in moderation check');
  return;
}

final message = room.messages.isNotEmpty ? room.messages.last : null;
if (message == null) {
  _logger.error('No messages in room ${room.id}');
  return;
}
```

**Step 3**: Add null-coalescing operator helper

```dart
// Add this utility in lib/core/extensions.dart
extension ListExtension<T> on List<T>? {
  T? get safeFirst => this?.isNotEmpty == true ? this!.first : null;
  T? get safeLast => this?.isNotEmpty == true ? this!.last : null;
}

// Usage:
final firstUser = users.safeFirst; // Never crashes
final lastMessage = messages.safeLast;
```

**Step 4**: Test thoroughly

```bash
flutter test lib/app_routes_test.dart
flutter build web
```

**Time**: ~30 minutes

---

### P0.5: Update Firestore Room Read Rules

**Issue**: All authenticated users can read ALL rooms (privacy violation)

**File**: `firestore.rules`

**Current Rule (VULNERABLE)**:

```firestore
match /rooms/{roomId} {
  allow read: if isSignedIn(); // ❌ ALL ROOMS VISIBLE TO EVERYONE
  allow write: if isSignedIn() && resource.data.hostId == request.auth.uid;
}
```

**Fixed Rule (SECURE)**:

```firestore
match /rooms/{roomId} {
  // Room host can always read/write
  allow read, write: if isSignedIn() &&
    resource.data.hostId == request.auth.uid;

  // Participants can read room (but not delete)
  allow read: if isSignedIn() &&
    request.auth.uid in resource.data.participants;

  // Public rooms can be read by anyone signed in
  allow read: if isSignedIn() &&
    resource.data.isPublic == true;

  // Participants can update room (mute, raise hand, etc.)
  allow update: if isSignedIn() &&
    request.auth.uid in resource.data.participants &&
    // Can only update certain fields
    request.resource.data.keys().hasOnly(['muted', 'raisedHand', 'screenSharing']);
}
```

**Step 1**: Open `firestore.rules`

**Step 2**: Replace room rules

```bash
# Find the 'match /rooms/{roomId}' section
# Replace with the fixed rule above
```

**Step 3**: Test with Firestore Emulator

```bash
firebase emulators:start --only firestore
```

Then in another terminal:

```bash
# Test case 1: User cannot read private room they're not in
firebase emulator:exec \
  "db.collection('rooms').where('isPublic', '==', false).get()" \
  --import=./test-data
# Expected: Access denied or empty results

# Test case 2: User CAN read room they're hosting
firebase emulator:exec \
  "db.collection('rooms').where('hostId', '==', currentUser.uid).get()"
# Expected: Returns rooms user hosts
```

**Step 4**: Deploy

```bash
firebase deploy --only firestore:rules
```

**Verification**:

```bash
# Check deployed rules
firebase firestore:indexes
firebase rules:list
```

**Time**: ~20 minutes

---

## P1 HIGH-PRIORITY FIXES (4-8 Hours - DO NEXT)

### P1.1: Add Message Rate Limiting

**File**: `firestore.rules`

```firestore
function notTooFrequent() {
  let lastMessageTime = resource.data.get('lastMessageTime', 0);
  return request.time.toMillis() - lastMessageTime > 1000; // 1 second between messages
}

match /rooms/{roomId}/messages/{messageId} {
  allow create: if isSignedIn() && notTooFrequent();
}
```

### P1.2: Add Pagination to User Discovery

**File**: `lib/providers/users_provider.dart`

```dart
// Add pagination
Future<List<User>> getUsers({int limit = 20, String? lastUserId}) async {
  var query = _firestore
      .collection('users')
      .limit(limit + 1);

  if (lastUserId != null) {
    final lastDoc = await _firestore.collection('users').doc(lastUserId).get();
    query = query.startAfterDocument(lastDoc);
  }

  final snapshot = await query.get();
  return snapshot.docs.map((doc) => User.fromFirestore(doc)).toList();
}
```

### P1.3-P1.8: Remaining P1 Fixes

See full audit report for details on JWT validation, CSP headers, web error UI, test data removal, SDK validation, env vars.

**Time**: 4-8 hours total

---

## VERIFICATION CHECKLIST

After all P0 fixes:

- [ ] Auth mismatch rejects same-user tokens ✅
- [ ] App ID not in Firestore ✅
- [ ] No debugPrints in console ✅
- [ ] No force unwraps in code ✅
- [ ] Firestore rules check room privacy ✅
- [ ] Web build < 50 MB ✅
- [ ] Agora token generation works ✅
- [ ] Error tracking still functional ✅
- [ ] All tests pass ✅

---

**Document Version**: 1.0
**Last Updated**: January 31, 2026
**Status**: READY FOR IMPLEMENTATION
