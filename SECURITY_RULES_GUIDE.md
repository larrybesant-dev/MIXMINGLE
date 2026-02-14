# Mix & Mingle - Firestore Security Rules Deployment Guide

**Version:** 2.0
**Last Updated:** January 24, 2026
**Status:** ✅ Production Ready

---

## Overview

This document provides comprehensive guidance for deploying and managing Firestore security rules for Mix & Mingle. The rules enforce strict access control, ownership validation, and data integrity across all collections.

---

## Table of Contents

1. [Pre-Deployment Checklist](#pre-deployment-checklist)
2. [Deployment Steps](#deployment-steps)
3. [Testing Security Rules](#testing-security-rules)
4. [Admin Role Setup](#admin-role-setup)
5. [Common Scenarios](#common-scenarios)
6. [Troubleshooting](#troubleshooting)
7. [Rule Updates](#rule-updates)

---

## Pre-Deployment Checklist

### ✅ Before Deployment

- [ ] Backup existing Firestore rules
- [ ] Review all changes in `firestore.rules`
- [ ] Verify Firebase CLI is installed and authenticated
- [ ] Test rules in Firebase Console Rules Playground
- [ ] Ensure all indexes are deployed (`firestore.indexes.json`)
- [ ] Coordinate with team on deployment window
- [ ] Have rollback plan ready

### 📋 Required Files

```
/MIXMINGLE
├── firestore.rules          # Main security rules file (v2.0)
├── firestore.indexes.json   # Composite indexes
└── FIRESTORE_SCHEMA.md      # Schema documentation
```

---

## Deployment Steps

### Step 1: Backup Current Rules

```bash
# Save current production rules
firebase firestore:rules:get > firestore.rules.backup

# Save with timestamp
firebase firestore:rules:get > "firestore.rules.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
```

### Step 2: Validate Rules Syntax

```bash
# Validate rules syntax locally
firebase deploy --only firestore:rules --dry-run

# Expected output: "Firestore rules syntax is valid"
```

### Step 3: Test Rules (Recommended)

```bash
# Run rules unit tests if available
firebase emulators:start --only firestore
npm run test:rules
```

### Step 4: Deploy Indexes First

**IMPORTANT**: Always deploy indexes before rules to prevent query failures.

```bash
# Deploy composite indexes
firebase deploy --only firestore:indexes

# Wait for indexes to build (check Firebase Console)
# Status: Building -> Enabled (may take 5-30 minutes)
```

### Step 5: Deploy Security Rules

```bash
# Deploy to production
firebase deploy --only firestore:rules

# Verify deployment
firebase firestore:rules:get
```

### Step 6: Verify Deployment

1. **Check Firebase Console**
   - Navigate to Firestore > Rules
   - Verify rules version updated
   - Check deployment timestamp

2. **Test Key Operations**
   - User profile read/write
   - Room creation and joining
   - Message sending
   - Match-based DM sending
   - Event capacity enforcement

---

## Testing Security Rules

### Using Firebase Rules Playground

1. **Navigate to Console**
   ```
   Firebase Console > Firestore Database > Rules > Rules Playground
   ```

2. **Test Scenarios**

   #### Test 1: User Can Read Own Profile
   ```
   Operation: get
   Location: /users/{uid}
   Authenticated: Yes (set uid in auth)
   Expected: ✅ Allow
   ```

   #### Test 2: User Cannot Read Another User Without Completed Profile
   ```
   Operation: get
   Location: /users/other_user_id
   Authenticated: Yes (user without displayName)
   Expected: ❌ Deny
   ```

   #### Test 3: Non-Matched Users Cannot Send DMs (Free Users)
   ```
   Operation: create
   Location: /direct_messages/msg_id
   Authenticated: Yes (free tier, not matched)
   Expected: ❌ Deny
   ```

   #### Test 4: Premium Users Can Send DMs to Anyone
   ```
   Operation: create
   Location: /direct_messages/msg_id
   Authenticated: Yes (membershipTier: 'premium')
   Expected: ✅ Allow
   ```

   #### Test 5: Event Capacity Enforcement
   ```
   Operation: update
   Location: /events/event_id
   Authenticated: Yes (adding self to attendees)
   Current attendees: 9/10
   Expected: ✅ Allow

   Current attendees: 10/10
   Expected: ❌ Deny
   ```

   #### Test 6: Admin-Only Event Creation
   ```
   Operation: create
   Location: /events/new_event_id
   Authenticated: Yes (role: 'admin')
   Expected: ✅ Allow

   Authenticated: Yes (role: null)
   Expected: ❌ Deny
   ```

### Automated Testing Script

```powershell
# test-security-rules.ps1

Write-Host "Testing Firestore Security Rules..." -ForegroundColor Cyan

# Start Firebase emulators
firebase emulators:start --only firestore &
Start-Sleep -Seconds 10

# Run test suite
npm run test:security-rules

# Results
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ All security rules tests passed!" -ForegroundColor Green
} else {
    Write-Host "❌ Security rules tests failed!" -ForegroundColor Red
    exit 1
}

# Cleanup
Stop-Process -Name "firebase" -Force
```

---

## Admin Role Setup

### Initial Admin User Creation

**CRITICAL**: The first admin must be created manually via Firebase Console.

#### Step 1: Create Admin User in Authentication

1. Navigate to Firebase Console > Authentication > Users
2. Click "Add User"
3. Enter email and password
4. Copy the generated UID

#### Step 2: Create Admin Profile in Firestore

```javascript
// Run in Firebase Console > Firestore > Add Document
// Collection: users
// Document ID: {copied_uid}

{
  "id": "{copied_uid}",
  "email": "admin@mixmingle.com",
  "displayName": "Admin User",
  "username": "admin",
  "role": "admin",  // ⚠️ CRITICAL FIELD
  "membershipTier": "vip",
  "avatarUrl": "",
  "bio": "",
  "location": "",
  "interests": [],
  "statusMessage": "Admin",
  "isOnline": false,
  "lastSeen": null,
  "badges": ["admin"],
  "coinBalance": 0,
  "followersCount": 0,
  "followingCount": 0,
  "totalTipsReceived": 0,
  "liveSessionsHosted": 0,
  "socialLinks": {},
  "topGifts": [],
  "recentMediaUrls": [],
  "recentActivity": [],
  "createdAt": "2026-01-24T20:00:00Z"
}
```

#### Step 3: Verify Admin Access

```javascript
// Test in app or via API
const user = firebase.auth().currentUser;
const userDoc = await firebase.firestore().collection('users').doc(user.uid).get();
console.log('User role:', userDoc.data().role); // Should be 'admin'
```

### Admin Panel Route Protection

Add to your app's routing logic:

```dart
// lib/app_routes.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AppRoutes {
  static Future<bool> isAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    return doc.data()?['role'] == 'admin';
  }

  static Future<void> navigateToAdminDashboard(BuildContext context) async {
    if (await isAdmin()) {
      Navigator.pushNamed(context, '/admin');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Admin access required')),
      );
    }
  }
}
```

### Promoting Users to Admin

**Security Function** (Cloud Functions):

```javascript
// functions/src/admin.ts

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

export const promoteToAdmin = functions.https.onCall(async (data, context) => {
  // Only existing admins can promote others
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Must be authenticated');
  }

  const callerDoc = await admin.firestore().collection('users').doc(context.auth.uid).get();
  if (callerDoc.data()?.role !== 'admin') {
    throw new functions.https.HttpsError('permission-denied', 'Must be admin');
  }

  const { userId, role } = data; // role: 'admin' | 'moderator'

  await admin.firestore().collection('users').doc(userId).update({
    role: role,
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  });

  return { success: true, message: `User promoted to ${role}` };
});
```

---

## Common Scenarios

### Scenario 1: User Signup Flow

```dart
// 1. Create auth account
final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
  email: email,
  password: password,
);

// 2. Reserve username
await FirebaseFirestore.instance.collection('usernames').doc(username.toLowerCase()).set({
  'uid': userCredential.user!.uid,
  'createdAt': FieldValue.serverTimestamp(),
});

// 3. Create user profile (rules enforce validation)
await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
  'id': userCredential.user!.uid,
  'email': email,
  'displayName': displayName,
  'username': username,
  'membershipTier': 'free',
  'coinBalance': 0,
  // ... other required fields
});
```

### Scenario 2: Joining a Room

```dart
// Rules automatically enforce:
// - User is authenticated
// - User is not banned
// - User can only add themselves to participantIds/listeners

await FirebaseFirestore.instance.collection('rooms').doc(roomId).update({
  'participantIds': FieldValue.arrayUnion([currentUserId]),
  'listeners': FieldValue.arrayUnion([currentUserId]),
  'viewerCount': FieldValue.increment(1),
});
```

### Scenario 3: Sending a Direct Message

```dart
// Rules enforce:
// - Users are matched OR sender is premium
// - Neither user has blocked the other
// - Content length and type validation

final isMatched = await checkIfMatched(receiverId);
final isPremium = await checkIfPremium();

if (!isMatched && !isPremium) {
  throw Exception('Must be matched or premium to send DM');
}

await FirebaseFirestore.instance.collection('direct_messages').add({
  'senderId': currentUserId,
  'receiverId': receiverId,
  'conversationId': conversationId,
  'type': 'text',
  'content': message,
  'status': 'sent',
  'timestamp': FieldValue.serverTimestamp(),
  'isEdited': false,
  'reactions': {},
});
```

### Scenario 4: Creating an Event (Admin Only)

```dart
// Check admin role first (client-side)
final userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUserId).get();
if (userDoc.data()?['role'] != 'admin') {
  throw Exception('Admin access required to create events');
}

// Create event (rules enforce admin role server-side)
await FirebaseFirestore.instance.collection('events').doc(eventId).set({
  'id': eventId,
  'hostId': currentUserId,
  'title': title,
  'description': description,
  'startTime': startTime,
  'endTime': endTime,
  'maxAttendees': maxAttendees,
  'attendees': [currentUserId],
  'isPublic': true,
  // ... other required fields
});
```

### Scenario 5: Joining Event with Capacity Check

```dart
// Rules enforce capacity automatically
try {
  await FirebaseFirestore.instance.collection('events').doc(eventId).update({
    'attendees': FieldValue.arrayUnion([currentUserId]),
  });
} catch (e) {
  if (e.toString().contains('permission-denied')) {
    showSnackBar('Event is full');
  }
}
```

---

## Troubleshooting

### Issue 1: "permission-denied" on User Creation

**Symptom**: Cannot create user profile after signup.

**Causes**:
- Missing required fields (`id`, `email`, `displayName`, `username`)
- Email doesn't match auth token email
- Username doesn't meet validation (3-20 chars, alphanumeric + underscore)
- `coinBalance` not set to 0
- `membershipTier` not set to 'free'

**Solution**:
```dart
// Ensure all required fields are present and valid
await FirebaseFirestore.instance.collection('users').doc(uid).set({
  'id': uid,                          // ✅ Must equal document ID
  'email': authEmail,                 // ✅ Must match auth.token.email
  'displayName': displayName,         // ✅ 1-50 chars
  'username': username,               // ✅ 3-20 chars, validated
  'membershipTier': 'free',          // ✅ Must be 'free' initially
  'coinBalance': 0,                  // ✅ Must be 0 initially
  // ... other fields
});
```

### Issue 2: Cannot Send Direct Messages

**Symptom**: "permission-denied" when sending DM.

**Causes**:
- Users are not matched
- User is not premium
- Sender has blocked receiver
- Receiver has blocked sender

**Solution**:
```dart
// Check prerequisites
final isMatched = await checkMatch(receiverId);
final isPremium = currentUser.membershipTier in ['premium', 'vip'];
final isBlocked = await checkBlockStatus(receiverId);

if (!isMatched && !isPremium) {
  showError('Must be matched or have premium to send DM');
  return;
}

if (isBlocked) {
  showError('Cannot send message to blocked user');
  return;
}
```

### Issue 3: Event Capacity Not Enforced

**Symptom**: Users can join event when at max capacity.

**Causes**:
- Client-side not checking capacity before update
- Race condition with multiple simultaneous joins

**Solution**:
```dart
// Use Firestore transaction for atomic capacity check
await FirebaseFirestore.instance.runTransaction((transaction) async {
  final eventDoc = await transaction.get(eventRef);
  final attendees = List<String>.from(eventDoc.data()!['attendees'] ?? []);
  final maxAttendees = eventDoc.data()!['maxAttendees'] as int;

  if (attendees.length >= maxAttendees) {
    throw Exception('Event is full');
  }

  attendees.add(currentUserId);
  transaction.update(eventRef, {'attendees': attendees});
});
```

### Issue 4: Admin Dashboard Access Denied

**Symptom**: Admin user cannot access admin dashboard.

**Causes**:
- User document missing `role: 'admin'` field
- Client-side check not implemented
- Incorrect role value (typo)

**Solution**:
```dart
// Verify user document in Firestore Console
{
  "role": "admin"  // Must be exactly "admin", case-sensitive
}

// Implement proper client-side check
final userDoc = await FirebaseFirestore.instance
    .collection('users')
    .doc(currentUserId)
    .get();

final role = userDoc.data()?['role'];
if (role != 'admin') {
  Navigator.pushReplacementNamed(context, '/home');
  return;
}
```

### Issue 5: Speed Dating Session Access Denied

**Symptom**: Users cannot update speed dating decisions.

**Causes**:
- User is not one of the session participants
- Session document doesn't exist
- Trying to update wrong user's decision

**Solution**:
```dart
// Verify user is participant
final sessionDoc = await FirebaseFirestore.instance
    .collection('speed_dating_sessions')
    .doc(sessionId)
    .get();

final userId1 = sessionDoc.data()!['userId1'];
final userId2 = sessionDoc.data()!['userId2'];

if (currentUserId != userId1 && currentUserId != userId2) {
  throw Exception('Not a participant in this session');
}

// Update correct decision field
final fieldToUpdate = currentUserId == userId1 ? 'user1Decision' : 'user2Decision';
await FirebaseFirestore.instance
    .collection('speed_dating_sessions')
    .doc(sessionId)
    .update({fieldToUpdate: decision}); // 'like' or 'pass'
```

---

## Rule Updates

### Making Changes to Security Rules

1. **Update `firestore.rules`**
   ```bash
   # Edit the file
   code firestore.rules
   ```

2. **Test Locally**
   ```bash
   firebase emulators:start --only firestore
   npm run test:rules
   ```

3. **Deploy with Version Comment**
   ```bash
   # Add version comment in firestore.rules
   // Version: 2.1 - Added XYZ feature - 2026-01-25

   firebase deploy --only firestore:rules --message "v2.1: Added XYZ feature"
   ```

4. **Document Changes**
   - Update FIRESTORE_SCHEMA.md security rules section
   - Update this guide if deployment process changes
   - Add entry to CHANGELOG.md

### Emergency Rollback

```bash
# Restore from backup
firebase deploy --only firestore:rules --file firestore.rules.backup

# Or restore specific version from Firebase Console
# Firebase Console > Firestore > Rules > History > Restore
```

---

## Monitoring & Alerts

### Key Metrics to Monitor

1. **Permission Denied Errors**
   ```bash
   # View in Firebase Console
   Firestore > Usage > Errors
   ```

2. **Failed Operations by Collection**
   - Track spikes in permission-denied errors
   - Identify misconfigured rules

3. **Admin Operations**
   - Monitor event creation frequency
   - Track report moderation activity

### Setting Up Alerts

```javascript
// Cloud Function for monitoring
export const monitorSecurityDenials = functions.firestore
  .document('{collection}/{docId}')
  .onWrite(async (change, context) => {
    // Track failed operations
    // Send alerts if threshold exceeded
  });
```

---

## Best Practices

### ✅ Do's

- Always deploy indexes before rules
- Test rules in emulator before production
- Keep backup of working rules
- Document all rule changes
- Use helper functions for complex logic
- Validate data on client AND server
- Implement proper error handling
- Monitor permission-denied errors

### ❌ Don'ts

- Never deploy untested rules to production
- Never remove security without replacement
- Don't rely solely on client-side validation
- Don't hardcode user IDs in rules
- Don't create overly complex rules (performance impact)
- Don't skip index deployment
- Don't delete rules without backup

---

## Support & Resources

- **Firebase Documentation**: https://firebase.google.com/docs/firestore/security/get-started
- **Schema Documentation**: [FIRESTORE_SCHEMA.md](FIRESTORE_SCHEMA.md)
- **Deployment Log**: [DEPLOYMENT_COMPLETE_20260124_190937.md](DEPLOYMENT_COMPLETE_20260124_190937.md)

---

**Security Rules Status:** ✅ Production Ready
**Last Tested:** January 24, 2026
**Next Review:** February 24, 2026
