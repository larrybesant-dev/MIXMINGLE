# Security Rules Tests

Tests every known write path and attack vector against the Firestore security rules using the Firebase Emulator Suite.

## Prerequisites

```bash
# 1. Install Firebase CLI
npm install -g firebase-tools

# 2. Install test dependencies
cd test/
npm install
```

## Run Locally

```bash
# Start the emulator in one terminal
firebase emulators:start --only firestore

# Run tests in another terminal
cd test/
npm run test:rules
```

Or let the test runner handle the emulator lifecycle:

```bash
cd test/
firebase emulators:exec --only firestore --project mix-and-mingle-v2 "npm run test:rules"
```

## Test Coverage

| Suite | Tests |
|---|---|
| Default deny | Unknown collections blocked for auth + unauth users |
| `users/` | Read (any auth), write (owner only) |
| `profiles_public/` | Read (any auth), write (owner only), unauth blocked |
| `profiles_private/` | Owner-only read/write, non-owner blocked |
| `matches/` | Create requires UID in participants, fake UIDs blocked |
| `withdrawals/` | UID match enforced, amount > 0, non-owner read blocked, update blocked |
| `moderation_logs` | Read/write blocked for non-admin |
| `admin/` | Blocked for non-admin |
| `notificationQueue` | Fully server-locked |
| `reports/` | Self-report blocked, spoofed reporterId blocked, reads blocked |
| `chats/messages` | Non-participant blocked, senderId spoof blocked |

## What This Proves

Before every merge, CI confirms that:
- No user can modify another user's profile
- No user can submit a withdrawal as another user
- No user can create a match between two strangers
- Private profiles are invisible to non-owners
- Admin/moderation data is server-only
- Default deny is intact

## Adding New Tests

Add a `describe` block to `firestore.rules.test.js`. Each test should:
1. Try a permission that **should succeed** → wrap in `assertSucceeds()`
2. Try a permission that **should fail** → wrap in `assertFails()`
