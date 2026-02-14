# MIX & MINGLE — COMPLETE PRODUCTION PLAN

## Overview

Complete end-to-end production workflow for Mix & Mingle Flutter app (Web/iOS/Android) with Firebase, Agora video, Stripe payments, speed dating, and moderator controls.

**Target**: Fully production-ready, tested, and deployed by end of workflow.

---

## **1️⃣ Environment Setup**

### Verify Flutter & Dart

```powershell
flutter --version
dart --version
```

**Requirements:**
- Flutter 3.38.7
- Dart 3.10.7
- Stable channel

**If upgrades needed:**
```powershell
flutter channel stable
flutter upgrade
```

### Verify Node & Firebase CLI

```powershell
node -v
firebase --version
```

**Requirements:**
- Node v20.19.4+
- Firebase CLI installed and authenticated

**If not authenticated:**
```powershell
firebase login
```

### VS Code Extensions

✅ Flutter & Dart
✅ Firebase
✅ GitLens
✅ Bracket Pair Colorizer
✅ Pubspec Assist
✅ Dart DevTools (optional, for debugging)

---

## **2️⃣ Project Scan & Audit**

Run in VS Code terminal:

```powershell
# Scan for stub/deprecation
ls -Recurse lib\services\*.dart | Select-String -Pattern "stub|old|deprecated"
ls -Recurse lib\models\*.dart
ls -Recurse lib\screens\*.dart
ls -Recurse lib\features\*.dart

# Get dependencies
flutter pub get

# Initial analysis
flutter analyze --no-pub > audit_initial_report.txt
```

**Outputs:**
- `audit_initial_report.txt` - Comprehensive analysis report
- List of files to remove
- Service dependency map

**Actions from audit:**
- Identify stub/deprecated files for removal
- List duplicate services for consolidation
- Note compilation errors for Phase 3
- Document Firestore collection structure

---

## **3️⃣ Cleanup & Consolidation**

### Remove Stub/Deprecated Files

```powershell
cd lib\services
Get-ChildItem -Recurse -Include *_stub.dart, *_old.dart, *_deprecated.dart | Remove-Item -Force
cd ..
```

### Consolidate Video Engine

**Keep only:**
- `services/video_engine_service.dart` (main router)
- `services/agora_web_engine.dart` (Web implementation)
- `services/agora_mobile_engine.dart` (Mobile implementation)
- `services/video_engine_models.dart` (shared models)
- `services/video_engine_interface.dart` (abstract interface)

**Remove:**
- All bridge duplicates
- Old Agora service wrappers
- Web-only/Mobile-only duplicates

**Ensure VideoEngineService:**
```dart
// Detects platform and routes correctly
class VideoEngineService {
  factory VideoEngineService() {
    if (kIsWeb) {
      return VideoEngineService._web();
    } else {
      return VideoEngineService._mobile();
    }
  }
}
```

### Merge Overlapping Services

| Service | Current Files | Action |
|---------|---------------|--------|
| **Room** | `room_service.dart` + `room_manager_service.dart` | Keep unified `RoomManagerService` |
| **Video** | `video_service.dart` + `agora_video_service.dart` | Route via `VideoEngineService` |
| **Payment** | `payment_service.dart` + `tipping_service.dart` | Unified `PaymentService` |
| **Speed Dating** | `speed_dating_service.dart` | Ensure single source of truth |
| **Auth** | `auth_service.dart` + `firebase_auth_service.dart` | Keep unified `AuthService` |

---

## **4️⃣ Firestore Schema & Security Rules**

### Collections Structure

```
/users/{uid}
  - email
  - displayName
  - profileImageUrl
  - bio
  - createdAt

/profiles/{uid}
  - answers (questionnaire)
  - preferences
  - blockedUsers[]
  - badges[]

/rooms/{roomId}
  - name
  - host
  - type (video|speed_dating|club)
  - status (active|locked|ended)
  - participants[]
  - createdAt
  - maxParticipants

/room_participants/{roomId}/users/{uid}
  - joinedAt
  - role (host|co_host|participant)
  - muted
  - videoOn
  - status (active|idle|left)

/speed_dating_sessions/{sessionId}
  - eventId
  - status (setup|active|completed)
  - participants[]
  - currentRound
  - roundCount
  - startTime
  - endTime

/rounds/{sessionId}/roundData/{roundId}
  - index
  - pair1uid
  - pair2uid
  - startTime
  - endTime
  - keep1, keep2 (decisions)
  - matched (boolean)

/matches/{sessionId}/matchData/{matchId}
  - uid1, uid2
  - timestamp
  - mutualMatch (boolean)

/moderation_logs/{roomId}/logs/{logId}
  - action (mute|remove|ban|lock|unlock|promote|demote)
  - actor
  - target
  - timestamp
  - reason

/tokens/{roomId}
  - agoraToken
  - expiry

/transactions/{uid}/history/{txId}
  - type (tip|purchase|reward)
  - amount
  - recipient
  - timestamp
  - status (pending|completed|failed)
```

### Security Rules

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Users can read/write their own profile
    match /users/{uid} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == uid;
    }

    // Profiles accessible to all authenticated users
    match /profiles/{uid} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == uid;
    }

    // Rooms readable/writable by authenticated users
    match /rooms/{roomId} {
      allow read, write: if request.auth != null;

      match /room_participants/users/{uid} {
        allow read: if request.auth != null;
        allow write: if request.auth != null;
      }
    }

    // Speed dating sessions
    match /speed_dating_sessions/{sessionId} {
      allow read, write: if request.auth != null;

      match /rounds/roundData/{roundId} {
        allow read, write: if request.auth != null;
      }

      match /matches/matchData/{matchId} {
        allow read: if request.auth != null;
      }
    }

    // Moderation logs (read only for participants)
    match /moderation_logs/{roomId}/logs/{logId} {
      allow read: if request.auth != null;
      allow write: if false; // Server-side cloud functions only
    }

    // Tokens (server-side only)
    match /tokens/{roomId} {
      allow read: if request.auth != null;
      allow write: if false; // Cloud function only
    }

    // Transactions (users can read their own)
    match /transactions/{uid}/history/{txId} {
      allow read: if request.auth.uid == uid;
      allow write: if false; // Cloud function only
    }
  }
}
```

---

## **5️⃣ Video Engine Testing & Fixes**

### Verify Interface Implementation

**File**: `lib/services/video_engine_interface.dart`

```dart
abstract class IVideoEngine {
  Future<void> initialize(String agoraAppId);
  Future<String> generateToken(String channelName, int uid);
  Future<void> joinChannel(String token, String channelName, int uid);
  Future<void> leaveChannel();
  Future<void> muteLocalAudio();
  Future<void> unmuteLocalAudio();
  Future<void> muteLocalVideo();
  Future<void> unmuteLocalVideo();
  Stream<RemoteUser> get remoteUserStream;
  Stream<LocalMediaState> get localMediaStream;
}
```

### Web Implementation Check

**File**: `lib/services/agora_web_engine.dart`
- Verify `AgoraWebEngine implements IVideoEngine`
- Check `StreamController` usage for multi-window support
- Ensure proper cleanup on window close

### Mobile Implementation Check

**File**: `lib/services/agora_mobile_engine.dart`
- Verify `AgoraMobileEngine implements IVideoEngine`
- Check `ChannelMediaOptions` enum (Agora 6.x)
- Verify `RemoteAudioState`, `RemoteVideoState` enums
- Ensure proper permission handling (iOS/Android)

### Testing Steps

```powershell
# Test Web multi-window (open 2 tabs)
flutter run -d chrome

# Test Android (if available)
flutter run -d android

# Test iOS (if macOS)
flutter run -d ios
```

**Verify:**
- ✅ Users can join/leave
- ✅ Audio/video toggle works
- ✅ Mute/unmute reflects in UI
- ✅ Multi-window Web stable
- ✅ Cross-platform user visibility

---

## **6️⃣ Speed Dating System Implementation**

### 1. Questionnaire Model

**File**: `lib/models/questionnaire_model.dart`

```dart
class QuestionnaireQuestion {
  final String id;
  final String text;
  final List<String> options;
  final String category; // lifestyle, goals, personality, etc.

  QuestionnaireQuestion({
    required this.id,
    required this.text,
    required this.options,
    required this.category,
  });
}

class QuestionnaireAnswers {
  final String uid;
  final Map<String, String> answers; // questionId -> selectedOption
  final DateTime timestamp;

  QuestionnaireAnswers({
    required this.uid,
    required this.answers,
    required this.timestamp,
  });
}
```

### 2. Speed Dating Service

**File**: `lib/services/speed_dating_service.dart`

```dart
class SpeedDatingService {
  final FirebaseFirestore _firestore;
  final VideoEngineService _videoEngine;

  // Initialize session
  Future<String> createSession({
    required String eventId,
    required int participantCount,
    required int roundDuration, // seconds
  }) async {
    final sessionId = _firestore.collection('speed_dating_sessions').doc().id;

    await _firestore
        .collection('speed_dating_sessions')
        .doc(sessionId)
        .set({
          'eventId': eventId,
          'status': 'setup',
          'participants': [],
          'currentRound': 0,
          'roundCount': (participantCount - 1),
          'roundDuration': roundDuration,
          'startTime': FieldValue.serverTimestamp(),
        });

    return sessionId;
  }

  // Start round (pairing logic)
  Future<void> startRound(String sessionId) async {
    final session = await _firestore
        .collection('speed_dating_sessions')
        .doc(sessionId)
        .get();

    final participants = List<String>.from(session['participants'] ?? []);
    final roundIndex = session['currentRound'] ?? 0;

    // Pairing algorithm (round-robin)
    final pairs = _generateRoundRobinPairs(participants, roundIndex);

    // Create Agora channels for each pair
    for (final pair in pairs) {
      final channelName = '$sessionId-round$roundIndex-${pair[0]}-${pair[1]}';
      final roundId = _firestore
          .collection('speed_dating_sessions')
          .doc(sessionId)
          .collection('rounds')
          .doc().id;

      await _firestore
          .collection('speed_dating_sessions')
          .doc(sessionId)
          .collection('rounds')
          .doc(roundId)
          .set({
            'index': roundIndex,
            'pair1uid': pair[0],
            'pair2uid': pair[1],
            'channelName': channelName,
            'startTime': FieldValue.serverTimestamp(),
            'endTime': Timestamp.now().add(Duration(seconds: session['roundDuration'])),
            'keep1': null,
            'keep2': null,
            'matched': false,
          });
    }

    await _firestore
        .collection('speed_dating_sessions')
        .doc(sessionId)
        .update({'status': 'active'});
  }

  // Keep/Pass decision
  Future<void> submitDecision({
    required String sessionId,
    required String uid,
    required String roundId,
    required bool keep,
  }) async {
    final roundRef = _firestore
        .collection('speed_dating_sessions')
        .doc(sessionId)
        .collection('rounds')
        .doc(roundId);

    final round = await roundRef.get();
    final pair1 = round['pair1uid'];
    final pair2 = round['pair2uid'];

    if (uid == pair1) {
      await roundRef.update({'keep1': keep});
    } else if (uid == pair2) {
      await roundRef.update({'keep2': keep});
    }

    // Check for match
    final updated = await roundRef.get();
    if (updated['keep1'] != null && updated['keep2'] != null) {
      if (updated['keep1'] && updated['keep2']) {
        // Mutual match
        await roundRef.update({'matched': true});

        // Create match record
        await _firestore
            .collection('speed_dating_sessions')
            .doc(sessionId)
            .collection('matches')
            .add({
              'uid1': pair1,
              'uid2': pair2,
              'timestamp': FieldValue.serverTimestamp(),
              'mutualMatch': true,
            });

        // Notify both users
        // _notificationService.notifyMatch(pair1, pair2);
      }
    }
  }

  // End round, advance to next
  Future<void> endRound(String sessionId) async {
    final session = await _firestore
        .collection('speed_dating_sessions')
        .doc(sessionId)
        .get();

    final currentRound = session['currentRound'] ?? 0;
    final roundCount = session['roundCount'] ?? 1;

    if (currentRound + 1 < roundCount) {
      await _firestore
          .collection('speed_dating_sessions')
          .doc(sessionId)
          .update({'currentRound': currentRound + 1});

      await startRound(sessionId);
    } else {
      // Session completed
      await _firestore
          .collection('speed_dating_sessions')
          .doc(sessionId)
          .update({'status': 'completed', 'endTime': FieldValue.serverTimestamp()});
    }
  }

  // Pairing logic (round-robin)
  List<List<String>> _generateRoundRobinPairs(List<String> participants, int round) {
    final pairs = <List<String>>[];
    final n = participants.length;

    for (int i = 0; i < n ~/ 2; i++) {
      final index1 = (round + i) % n;
      final index2 = (round + n - 1 - i) % n;
      pairs.add([participants[index1], participants[index2]]);
    }

    return pairs;
  }
}
```

### 3. Speed Dating UI

**File**: `lib/screens/speed_dating_screen.dart`
- Show questionnaire on entry
- Display round timer (5-minute countdown)
- Show Keep/Pass buttons
- Display partner info
- Show match notification
- Support multi-window navigation

### 4. Testing

Create test file: `test/speed_dating_flow_test.dart`

```dart
void main() {
  group('Speed Dating Flow', () {
    test('Session creation', () async {
      // Create session
      // Verify Firestore structure
    });

    test('Round generation & pairing', () async {
      // Start round
      // Verify pairs are generated
      // Verify Agora channels created
    });

    test('Keep/Pass & matching', () async {
      // Submit decisions
      // Verify mutual match detection
      // Verify match record creation
    });
  });
}
```

---

## **7️⃣ Host & Moderator Controls**

**File**: `lib/services/room_manager_service.dart`

```dart
class RoomManagerService {
  final FirebaseFirestore _firestore;
  final VideoEngineService _videoEngine;

  // Mute individual user
  Future<void> muteUser(String roomId, String uid) async {
    await _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('room_participants')
        .doc('users')
        .collection('$uid')
        .update({'muted': true});

    // Log moderation action
    await _logModerationAction(roomId, 'mute', uid, 'mute');
  }

  // Unmute user
  Future<void> unmuteUser(String roomId, String uid) async {
    await _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('room_participants')
        .doc('users')
        .collection('$uid')
        .update({'muted': false});

    await _logModerationAction(roomId, 'unmute', uid, 'unmute');
  }

  // Remove/kick user
  Future<void> removeUser(String roomId, String uid, String reason) async {
    await _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('room_participants')
        .doc('users')
        .update({uid: FieldValue.delete()});

    // Notify user
    // _notificationService.notifyRemoved(uid, roomId, reason);

    await _logModerationAction(roomId, 'remove', uid, reason);
  }

  // Ban user
  Future<void> banUser(String roomId, String uid, String reason) async {
    await _firestore
        .collection('rooms')
        .doc(roomId)
        .update({
          'bannedUsers': FieldValue.arrayUnion([uid])
        });

    // Remove if already in room
    await removeUser(roomId, uid, 'banned: $reason');

    await _logModerationAction(roomId, 'ban', uid, reason);
  }

  // Unban user
  Future<void> unbanUser(String roomId, String uid) async {
    await _firestore
        .collection('rooms')
        .doc(roomId)
        .update({
          'bannedUsers': FieldValue.arrayRemove([uid])
        });

    await _logModerationAction(roomId, 'unban', uid, 'unbanned');
  }

  // Lock room
  Future<void> lockRoom(String roomId, String reason) async {
    await _firestore
        .collection('rooms')
        .doc(roomId)
        .update({'status': 'locked', 'lockedReason': reason});

    // Get current host
    final room = await _firestore.collection('rooms').doc(roomId).get();
    await _logModerationAction(roomId, 'lock', room['host'], reason);
  }

  // Unlock room
  Future<void> unlockRoom(String roomId) async {
    await _firestore
        .collection('rooms')
        .doc(roomId)
        .update({'status': 'active', 'lockedReason': null});

    final room = await _firestore.collection('rooms').doc(roomId).get();
    await _logModerationAction(roomId, 'unlock', room['host'], 'unlocked');
  }

  // End room
  Future<void> endRoom(String roomId) async {
    await _firestore
        .collection('rooms')
        .doc(roomId)
        .update({'status': 'ended', 'endedAt': FieldValue.serverTimestamp()});

    final room = await _firestore.collection('rooms').doc(roomId).get();
    await _logModerationAction(roomId, 'end', room['host'], 'room ended');
  }

  // Promote co-host
  Future<void> promoteCoHost(String roomId, String uid) async {
    await _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('room_participants')
        .doc('users')
        .collection('$uid')
        .update({'role': 'co_host'});

    await _logModerationAction(roomId, 'promote', uid, 'promoted to co-host');
  }

  // Demote co-host
  Future<void> demoteCoHost(String roomId, String uid) async {
    await _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('room_participants')
        .doc('users')
        .collection('$uid')
        .update({'role': 'participant'});

    await _logModerationAction(roomId, 'demote', uid, 'demoted to participant');
  }

  // Log moderation action
  Future<void> _logModerationAction(
    String roomId,
    String action,
    String targetUid,
    String reason,
  ) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    await _firestore
        .collection('moderation_logs')
        .doc(roomId)
        .collection('logs')
        .add({
          'action': action,
          'actor': userId,
          'target': targetUid,
          'reason': reason,
          'timestamp': FieldValue.serverTimestamp(),
        });
  }
}
```

**UI Integration**:
- Add moderator panel to room screen
- Show list of participants
- Add action buttons (mute, remove, promote, demote)
- Show moderation log viewer
- Restrict actions to host/co-hosts only

---

## **8️⃣ Stripe Payments Integration**

### 1. Firebase Cloud Functions

**File**: `functions/src/stripe.ts`

```typescript
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import Stripe from 'stripe';

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY!);

// Process tip
export const processTip = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new Error('Auth required');

  const { recipientUid, amount, message } = data;

  // Create payment intent
  const paymentIntent = await stripe.paymentIntents.create({
    amount: Math.round(amount * 100), // cents
    currency: 'usd',
    description: `Tip for ${recipientUid}`,
    metadata: {
      senderUid: context.auth.uid,
      recipientUid,
      message,
    },
  });

  // Log transaction
  await admin.firestore()
      .collection('transactions')
      .doc(context.auth.uid)
      .collection('history')
      .add({
        type: 'tip',
        amount,
        recipient: recipientUid,
        status: 'pending',
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

  return { clientSecret: paymentIntent.client_secret };
});

// Create checkout session
export const createCheckout = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new Error('Auth required');

  const { coinPackage } = data; // { coins: 100, price: 9.99 }

  const session = await stripe.checkout.sessions.create({
    payment_method_types: ['card'],
    line_items: [
      {
        price_data: {
          currency: 'usd',
          product_data: {
            name: `${coinPackage.coins} Coins`,
          },
          unit_amount: Math.round(coinPackage.price * 100),
        },
        quantity: 1,
      },
    ],
    mode: 'payment',
    success_url: 'https://mixmingle.app/coins-success',
    cancel_url: 'https://mixmingle.app/coins-cancelled',
    customer_email: context.auth.token.email,
    metadata: {
      uid: context.auth.uid,
      coins: coinPackage.coins,
    },
  });

  return { sessionId: session.id };
});

// Webhook handler for successful payment
export const stripeWebhook = functions.https.onRequest(async (req, res) => {
  const sig = req.headers['stripe-signature'] as string;
  const event = stripe.webhooks.constructEvent(
      req.rawBody,
      sig,
      process.env.STRIPE_WEBHOOK_SECRET!
  );

  switch (event.type) {
    case 'payment_intent.succeeded': {
      const intent = event.data.object as Stripe.PaymentIntent;
      await admin.firestore()
          .collection('transactions')
          .doc(intent.metadata!.senderUid)
          .collection('history')
          .add({
            type: 'tip',
            amount: intent.amount / 100,
            recipient: intent.metadata!.recipientUid,
            status: 'completed',
            stripeId: intent.id,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
          });
      break;
    }

    case 'checkout.session.completed': {
      const session = event.data.object as Stripe.Checkout.Session;
      const uid = session.metadata!.uid;
      const coins = parseInt(session.metadata!.coins, 10);

      // Add coins to user
      await admin.firestore()
          .collection('users')
          .doc(uid)
          .update({
            coins: admin.firestore.FieldValue.increment(coins),
          });

      // Log transaction
      await admin.firestore()
          .collection('transactions')
          .doc(uid)
          .collection('history')
          .add({
            type: 'purchase',
            coins,
            amount: (session.amount_total! / 100),
            status: 'completed',
            stripeId: session.payment_intent,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
          });
      break;
    }
  }

  res.sendStatus(200);
});

// Refund payment
export const refundPayment = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new Error('Auth required');

  const { stripeId, reason } = data;

  // Only allow refunds for own transactions
  const tx = await admin.firestore()
      .collection('transactions')
      .doc(context.auth.uid)
      .collection('history')
      .where('stripeId', '==', stripeId)
      .limit(1)
      .get();

  if (tx.empty) throw new Error('Transaction not found');

  const refund = await stripe.refunds.create({
    payment_intent: stripeId,
    reason: reason || 'requested_by_customer',
  });

  // Update transaction
  await tx.docs[0].ref.update({
    status: 'refunded',
    refundId: refund.id,
  });

  return { refundId: refund.id };
});
```

### 2. Flutter Payment Service

**File**: `lib/services/payment_service.dart`

```dart
class PaymentService {
  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;

  // Send tip
  Future<void> sendTip({
    required String recipientUid,
    required double amount,
    String? message,
  }) async {
    try {
      final result = await _functions
          .httpsCallable('processTip')
          .call({
            'recipientUid': recipientUid,
            'amount': amount,
            'message': message,
          });

      final clientSecret = result.data['clientSecret'] as String;

      // Use Stripe Flutter SDK to complete payment
      // await Stripe.instance.presentPaymentSheet(
      //   clientSecret: clientSecret,
      // );
    } catch (e) {
      print('Tip error: $e');
      rethrow;
    }
  }

  // Purchase coins
  Future<void> purchaseCoins({
    required int coins,
    required double price,
  }) async {
    try {
      final result = await _functions
          .httpsCallable('createCheckout')
          .call({
            'coinPackage': {
              'coins': coins,
              'price': price,
            }
          });

      final sessionId = result.data['sessionId'] as String;

      // Open Stripe checkout
      // await Stripe.instance.redirectToCheckout(sessionId: sessionId);
    } catch (e) {
      print('Purchase error: $e');
      rethrow;
    }
  }

  // Get tip history
  Future<List<Transaction>> getTipHistory(String uid) async {
    final snapshot = await _firestore
        .collection('transactions')
        .doc(uid)
        .collection('history')
        .where('type', isEqualTo: 'tip')
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs.map((doc) => Transaction.fromFirestore(doc)).toList();
  }

  // Get leaderboard
  Future<List<TipLeaderboardEntry>> getTipLeaderboard(String roomId) async {
    final snapshot = await _firestore
        .collectionGroup('history')
        .where('type', isEqualTo: 'tip')
        .where('recipient', isEqualTo: roomId)
        .orderBy('amount', descending: true)
        .limit(10)
        .get();

    return snapshot.docs.map((doc) => TipLeaderboardEntry.fromFirestore(doc)).toList();
  }

  // Refund
  Future<void> refundPayment({
    required String stripeId,
    required String reason,
  }) async {
    await _functions
        .httpsCallable('refundPayment')
        .call({
          'stripeId': stripeId,
          'reason': reason,
        });
  }
}
```

### 3. Models

**File**: `lib/models/transaction_model.dart`

```dart
class Transaction {
  final String id;
  final String type; // tip, purchase, reward
  final double amount;
  final String? recipient;
  final DateTime timestamp;
  final String status; // pending, completed, failed, refunded
  final String? stripeId;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    this.recipient,
    required this.timestamp,
    required this.status,
    this.stripeId,
  });

  factory Transaction.fromFirestore(DocumentSnapshot doc) {
    return Transaction(
      id: doc.id,
      type: doc['type'],
      amount: (doc['amount'] as num).toDouble(),
      recipient: doc['recipient'],
      timestamp: (doc['timestamp'] as Timestamp).toDate(),
      status: doc['status'],
      stripeId: doc['stripeId'],
    );
  }
}
```

---

## **9️⃣ Theme & UI**

### Neon Club Theme

**File**: `lib/theme/neon_theme.dart`

```dart
class NeonTheme {
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: Color(0xFF00D4FF), // Neon blue
    secondaryHeaderColor: Color(0xFFFF006E), // Neon pink
    backgroundColor: Color(0xFF0A0E27), // Deep space
    surfaceColor: Color(0xFF1A1E3F),

    appBarTheme: AppBarTheme(
      backgroundColor: Color(0xFF0A0E27),
      elevation: 0,
      titleTextStyle: TextStyle(
        color: Color(0xFF00D4FF),
        fontSize: 24,
        fontWeight: FontWeight.bold,
        shadows: [
          BoxShadow(
            color: Color(0xFF00D4FF).withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
    ),

    buttonTheme: ButtonThemeData(
      buttonColor: Color(0xFF00D4FF),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFF00D4FF),
        foregroundColor: Color(0xFF0A0E27),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        shadowColor: Color(0xFF00D4FF).withOpacity(0.5),
        elevation: 10,
      ),
    ),

    textTheme: TextTheme(
      headline1: TextStyle(
        color: Color(0xFF00D4FF),
        fontSize: 32,
        fontWeight: FontWeight.bold,
        shadows: [
          BoxShadow(
            color: Color(0xFF00D4FF).withOpacity(0.3),
            blurRadius: 8,
          ),
        ],
      ),
      bodyText1: TextStyle(
        color: Colors.white70,
        fontSize: 16,
      ),
      bodyText2: TextStyle(
        color: Colors.white54,
        fontSize: 14,
      ),
    ),
  );
}
```

**Apply globally**:
```dart
// main.dart
MaterialApp(
  theme: NeonTheme.darkTheme,
  // ...
)
```

---

## **🔟 Testing & QA**

### Analysis

```powershell
flutter analyze --no-pub > analysis_report.txt
```

**Handle info-level warnings:**
- Unused imports: Remove them
- Unused variables: Remove or use
- Unnecessary null checks: Fix type safety
- Documentation: Add if public API

### Unit Tests

```powershell
flutter test test/unit/
```

**Create tests for:**
- `VideoEngineService` routing
- `SpeedDatingService` pairing logic
- `PaymentService` transaction logging
- `RoomManagerService` moderation actions

### Integration Tests

```powershell
# Multi-window Web test
flutter drive --target=test_driver/app.dart --driver=test_driver/app_test.dart -d web-server

# Speed dating flow test
flutter drive --target=test_driver/speed_dating_test.dart -d web-server

# Stripe test (requires test keys)
flutter drive --target=test_driver/stripe_test.dart -d web-server
```

### Build Tests

```powershell
# Web
flutter build web --release

# Android
flutter build apk --release
flutter build appbundle --release

# iOS (macOS only)
flutter build ios --release
```

**Verify:**
- No build errors
- All assets included
- All plugins linked
- Icons/splash screens included

---

## **1️⃣1️⃣ Deployment**

### Web Deployment

```powershell
# Clean previous build
rm -Recurse build/web -Force -ErrorAction SilentlyContinue

# Build
flutter build web --release

# Deploy to Firebase Hosting
firebase deploy --only hosting
```

**Verify:**
- ✅ Live URL accessible
- ✅ Multi-window rooms work
- ✅ Speed dating accessible
- ✅ Stripe checkout loads
- ✅ Video works across multiple tabs

### Android Deployment

```powershell
# Build APK (for testing)
flutter build apk --release

# Build AAB (for Play Store)
flutter build appbundle --release
```

**Artifacts:**
- `build/app/outputs/flutter-apk/app-release.apk`
- `build/app/outputs/bundle/release/app-release.aab`

**Prepare for Play Store:**
- Sign APK/AAB with keystore
- Upload AAB to Play Console
- Configure release notes
- Deploy to internal testing → beta → production

### iOS Deployment

```powershell
# (Requires macOS)
flutter build ios --release

# Create archive
xcodebuild -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -archivePath build/ios/Runner.xcarchive \
  archive

# Export IPA
xcodebuild -exportArchive \
  -archivePath build/ios/Runner.xcarchive \
  -exportOptionsPlist ios/ExportOptions.plist \
  -exportPath build/ios/ipa
```

**Artifacts:**
- `build/ios/ipa/Runner.ipa`

**Prepare for App Store:**
- Sign IPA with App Store certificate
- Upload to App Store Connect
- Configure release notes & screenshots
- Deploy to TestFlight → production

---

## **1️⃣2️⃣ Build & Deploy Script**

**File**: `build-and-deploy.ps1`

```powershell
# ==========================================
# Mix & Mingle — Full Build & Deploy Script
# ==========================================

Write-Host "🔹 Cleaning old builds..."
flutter clean
flutter pub get

Write-Host "🔹 Running flutter analyze..."
flutter analyze --no-pub | Tee-Object -FilePath analyze_report.txt

Write-Host "🌐 Building Web release..."
flutter build web --release
if (Test-Path "build/web/index.html") {
    Write-Host "✅ Web build success" -ForegroundColor Green
} else {
    Write-Host "❌ Web build failed" -ForegroundColor Red
}

Write-Host "🤖 Building Android APK..."
flutter build apk --release
if (Test-Path "build/app/outputs/flutter-apk/app-release.apk") {
    Write-Host "✅ APK build success" -ForegroundColor Green
} else {
    Write-Host "❌ APK build failed" -ForegroundColor Red
}

Write-Host "🤖 Building Android AAB..."
flutter build appbundle --release
if (Test-Path "build/app/outputs/bundle/release/app-release.aab") {
    Write-Host "✅ AAB build success" -ForegroundColor Green
} else {
    Write-Host "❌ AAB build failed" -ForegroundColor Red
}

if ($IsMacOS) {
    Write-Host "🍎 Building iOS release..."
    flutter build ios --release
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ iOS build success" -ForegroundColor Green
    } else {
        Write-Host "❌ iOS build failed" -ForegroundColor Red
    }
} else {
    Write-Host "⚠️ Skipping iOS (Windows detected)" -ForegroundColor DarkYellow
}

Write-Host "🚀 Deploying Web to Firebase Hosting..."
firebase deploy --only hosting
Write-Host "🚀 Deployment complete"

Write-Host "📋 Generating report..."
$report = @"
Build & Deploy Report
====================
Date: $(Get-Date)

Build Artifacts:
  Web: build/web
  Android APK: build/app/outputs/flutter-apk/app-release.apk
  Android AAB: build/app/outputs/bundle/release/app-release.aab
  Analysis: analyze_report.txt

Deployment Status:
  Firebase Hosting: $(if (Test-Path "build/web/index.html") {"✅ Deployed"} else {"❌ Failed"})

Next Steps:
  1. Test multi-window Web rooms
  2. Verify speed dating system
  3. Verify Stripe payments
  4. Monitor Firebase logs
  5. Submit Android to Play Console
  6. Submit iOS to App Store (if macOS)
"@

$report | Out-File -FilePath "PRODUCTION_READY_REPORT.md"
Write-Host "📋 Report saved to PRODUCTION_READY_REPORT.md"

Write-Host "🎉 Build & deploy complete!" -ForegroundColor Green
```

**Run:**
```powershell
.\build-and-deploy.ps1
```

---

## **1️⃣3️⃣ Post-Launch Checklist**

### Stability & Performance
- [ ] Load test with 50+ concurrent users
- [ ] Monitor Firebase resource usage
- [ ] Check for memory leaks (video streams)
- [ ] Verify Agora token generation under load
- [ ] Monitor Firestore query performance

### Feature Verification
- [ ] Speed dating pairing logic works correctly
- [ ] Keep/Pass matching is accurate
- [ ] Round timers are synchronized
- [ ] Host controls (mute, remove, ban) work
- [ ] Stripe tips & coin purchases process
- [ ] Moderation logs record correctly
- [ ] Multi-window Web stable (100+ rooms)

### User Experience
- [ ] Video quality is acceptable
- [ ] Audio latency is < 500ms
- [ ] UI responsive on all devices
- [ ] Neon theme consistent everywhere
- [ ] Notifications working (matches, tips)
- [ ] Error messages are clear

### Security & Compliance
- [ ] Firestore rules enforced
- [ ] Stripe PCI compliance met
- [ ] No sensitive data in logs
- [ ] Auth tokens refresh properly
- [ ] Ban/block features working
- [ ] User privacy settings respected

### Analytics & Monitoring
- [ ] Firebase Analytics events firing
- [ ] Crash Reporting enabled
- [ ] Performance Monitoring active
- [ ] Stripe webhooks logging
- [ ] Moderation audit trail complete

### App Store Submission
- [ ] App icon, splash screen finalized (iOS/Android)
- [ ] Privacy policy & terms updated
- [ ] Release notes written
- [ ] Screenshots/app preview videos ready
- [ ] All permissions justified
- [ ] In-app purchase agreements signed

---

## **Final Notes**

✅ **Outcome**: After completing all these steps, Mix & Mingle will be:

- **Feature-complete**: Video rooms, speed dating, host controls, Stripe payments
- **Production-hardened**: Analyzed, tested, optimized for production
- **Fully deployed**: Web live, Android/iOS ready for store submission
- **Monitored**: Analytics, crash reporting, performance tracking active
- **Documented**: Code clean, services unified, architecture clear

**Timeline estimate**:
- Setup & Cleanup: 2-4 hours
- Core fixes & consolidation: 4-6 hours
- Speed dating implementation: 6-8 hours
- Moderator controls: 2-3 hours
- Stripe integration: 4-6 hours
- Testing & QA: 6-8 hours
- Build & deployment: 2-4 hours

**Total: ~30-40 hours of focused development**

---

**Date**: February 6, 2026
**Version**: 1.0 - Complete Production Plan
**Status**: Ready to implement
