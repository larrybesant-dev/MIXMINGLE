/**
 * firestore.rules.test.js
 *
 * Security rule tests for Mix & Mingle Firestore rules.
 * Uses @firebase/rules-unit-testing with the Firebase Emulator Suite.
 *
 * Run with:
 *   npm run test:rules
 *   (or: npx jest test/firestore.rules.test.js)
 *
 * Prerequisites:
 *   firebase emulators:start --only firestore
 */

const { readFileSync } = require('fs');
const { resolve } = require('path');
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');

const PROJECT_ID = 'mix-and-mingle-v2';
const RULES_FILE = resolve(__dirname, '../firestore.rules');

let testEnv;

// ─── Setup / Teardown ──────────────────────────────────────────────────────

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: readFileSync(RULES_FILE, 'utf8'),
      host: '127.0.0.1',
      port: 9080,
    },
  });
});

afterAll(async () => {
  await testEnv.cleanup();
});

afterEach(async () => {
  await testEnv.clearFirestore();
});

// ─── Helpers ───────────────────────────────────────────────────────────────

function authed(uid) {
  return testEnv.authenticatedContext(uid);
}

function unauthed() {
  return testEnv.unauthenticatedContext();
}

async function seedDoc(collection, docId, data) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await ctx.firestore().collection(collection).doc(docId).set(data);
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// TEST SUITE 1: DEFAULT DENY
// ═══════════════════════════════════════════════════════════════════════════

describe('Default deny', () => {
  test('Unauthenticated user cannot read any unknown collection', async () => {
    const db = unauthed().firestore();
    await assertFails(db.collection('unknown_secret_collection').doc('x').get());
  });

  test('Authenticated user cannot read unknown collection', async () => {
    const db = authed('user1').firestore();
    await assertFails(db.collection('unknown_secret_collection').doc('x').get());
  });

  test('Authenticated user cannot write to unknown collection', async () => {
    const db = authed('user1').firestore();
    await assertFails(db.collection('unknown_secret_collection').doc('x').set({ foo: 'bar' }));
  });
});

// ═══════════════════════════════════════════════════════════════════════════
// TEST SUITE 2: USERS COLLECTION
// ═══════════════════════════════════════════════════════════════════════════

describe('users collection', () => {
  test('Unauthenticated user cannot read any user profile', async () => {
    await seedDoc('users', 'alice', { displayName: 'Alice' });
    const db = unauthed().firestore();
    await assertFails(db.collection('users').doc('alice').get());
  });

  test('Authenticated user can read any user profile', async () => {
    await seedDoc('users', 'alice', { displayName: 'Alice' });
    const db = authed('bob').firestore();
    await assertSucceeds(db.collection('users').doc('alice').get());
  });

  test('User can create their own profile', async () => {
    const db = authed('alice').firestore();
    await assertSucceeds(
      db.collection('users').doc('alice').set({ displayName: 'Alice', email: 'alice@test.com' })
    );
  });

  test('User cannot create a profile for another user', async () => {
    const db = authed('alice').firestore();
    await assertFails(
      db.collection('users').doc('bob').set({ displayName: 'Bob' })
    );
  });

  test('User can update their own profile', async () => {
    await seedDoc('users', 'alice', { displayName: 'Alice' });
    const db = authed('alice').firestore();
    await assertSucceeds(
      db.collection('users').doc('alice').update({ displayName: 'Alice Updated' })
    );
  });

  test('User cannot update another users profile', async () => {
    await seedDoc('users', 'alice', { displayName: 'Alice' });
    const db = authed('mallory').firestore();
    await assertFails(
      db.collection('users').doc('alice').update({ displayName: 'Hacked' })
    );
  });
});

// ═══════════════════════════════════════════════════════════════════════════
// TEST SUITE 3: PROFILES_PUBLIC COLLECTION
// ═══════════════════════════════════════════════════════════════════════════

describe('profiles_public collection', () => {
  test('Authenticated user can read any public profile', async () => {
    await seedDoc('profiles_public', 'alice', { displayName: 'Alice' });
    const db = authed('bob').firestore();
    await assertSucceeds(db.collection('profiles_public').doc('alice').get());
  });

  test('Unauthenticated user cannot read public profiles', async () => {
    await seedDoc('profiles_public', 'alice', { displayName: 'Alice' });
    const db = unauthed().firestore();
    await assertFails(db.collection('profiles_public').doc('alice').get());
  });

  test('Owner can write their own public profile', async () => {
    const db = authed('alice').firestore();
    await assertSucceeds(
      db.collection('profiles_public').doc('alice').set({ displayName: 'Alice' })
    );
  });

  test('Non-owner cannot write to another users public profile', async () => {
    const db = authed('mallory').firestore();
    await assertFails(
      db.collection('profiles_public').doc('alice').set({ displayName: 'Hacked' })
    );
  });
});

// ═══════════════════════════════════════════════════════════════════════════
// TEST SUITE 4: PROFILES_PRIVATE COLLECTION
// ═══════════════════════════════════════════════════════════════════════════

describe('profiles_private collection', () => {
  test('Owner can read their own private profile', async () => {
    await seedDoc('profiles_private', 'alice', { email: 'alice@test.com' });
    const db = authed('alice').firestore();
    await assertSucceeds(db.collection('profiles_private').doc('alice').get());
  });

  test('Non-owner CANNOT read someone elses private profile', async () => {
    await seedDoc('profiles_private', 'alice', { email: 'alice@test.com' });
    const db = authed('mallory').firestore();
    await assertFails(db.collection('profiles_private').doc('alice').get());
  });

  test('Unauthenticated user CANNOT read any private profile', async () => {
    await seedDoc('profiles_private', 'alice', { email: 'alice@test.com' });
    const db = unauthed().firestore();
    await assertFails(db.collection('profiles_private').doc('alice').get());
  });

  test('Non-owner CANNOT write to someone elses private profile', async () => {
    const db = authed('mallory').firestore();
    await assertFails(
      db.collection('profiles_private').doc('alice').set({ isAdultContentEnabled: true })
    );
  });

  test('Owner can write their own private profile', async () => {
    const db = authed('alice').firestore();
    await assertSucceeds(
      db.collection('profiles_private').doc('alice').set({ isAdultContentEnabled: false })
    );
  });
});

// ═══════════════════════════════════════════════════════════════════════════
// TEST SUITE 5: MATCHES COLLECTION
// ═══════════════════════════════════════════════════════════════════════════

describe('matches collection', () => {
  test('User can create a match where they are userId1', async () => {
    const db = authed('alice').firestore();
    await assertSucceeds(
      db.collection('matches').add({
        userId1: 'alice',
        userId2: 'bob',
        status: 'pending',
      })
    );
  });

  test('User can create a match where they are userId2', async () => {
    const db = authed('bob').firestore();
    await assertSucceeds(
      db.collection('matches').add({
        userId1: 'alice',
        userId2: 'bob',
        status: 'pending',
      })
    );
  });

  test('User CANNOT create a match between two other users', async () => {
    const db = authed('mallory').firestore();
    await assertFails(
      db.collection('matches').add({
        userId1: 'alice',
        userId2: 'bob',
        status: 'pending',
      })
    );
  });

  test('Unauthenticated user cannot create matches', async () => {
    const db = unauthed().firestore();
    await assertFails(
      db.collection('matches').add({
        userId1: 'alice',
        userId2: 'bob',
        status: 'pending',
      })
    );
  });
});

// ═══════════════════════════════════════════════════════════════════════════
// TEST SUITE 6: WITHDRAWALS COLLECTION
// ═══════════════════════════════════════════════════════════════════════════

describe('withdrawals collection — security critical', () => {
  test('User can submit a withdrawal for themselves', async () => {
    const db = authed('alice').firestore();
    await assertSucceeds(
      db.collection('withdrawals').add({
        userId: 'alice',
        amount: 100,
        email: 'alice@test.com',
        status: 'pending',
      })
    );
  });

  test('User CANNOT submit a withdrawal with a mismatched userId', async () => {
    const db = authed('mallory').firestore();
    await assertFails(
      db.collection('withdrawals').add({
        userId: 'alice',  // Not mallory's UID
        amount: 100,
        email: 'mallory@test.com',
        status: 'pending',
      })
    );
  });

  test('User CANNOT submit a withdrawal with amount <= 0', async () => {
    const db = authed('alice').firestore();
    await assertFails(
      db.collection('withdrawals').add({
        userId: 'alice',
        amount: 0,
        email: 'alice@test.com',
        status: 'pending',
      })
    );
  });

  test('User CANNOT read another users withdrawal', async () => {
    await seedDoc('withdrawals', 'wd1', { userId: 'alice', amount: 100, status: 'pending' });
    const db = authed('mallory').firestore();
    await assertFails(db.collection('withdrawals').doc('wd1').get());
  });

  test('User CAN read their own withdrawal', async () => {
    await seedDoc('withdrawals', 'wd1', { userId: 'alice', amount: 100, status: 'pending' });
    const db = authed('alice').firestore();
    await assertSucceeds(db.collection('withdrawals').doc('wd1').get());
  });

  test('User CANNOT approve their own withdrawal', async () => {
    await seedDoc('withdrawals', 'wd1', { userId: 'alice', amount: 100, status: 'pending' });
    const db = authed('alice').firestore();
    await assertFails(
      db.collection('withdrawals').doc('wd1').update({ status: 'approved' })
    );
  });

  test('Unauthenticated user cannot submit or read withdrawals', async () => {
    const db = unauthed().firestore();
    await assertFails(
      db.collection('withdrawals').add({ userId: 'alice', amount: 100 })
    );
  });
});

// ═══════════════════════════════════════════════════════════════════════════
// TEST SUITE 7: MODERATION / ADMIN COLLECTIONS
// ═══════════════════════════════════════════════════════════════════════════

describe('moderation and admin collections', () => {
  test('Regular user cannot read moderation_logs', async () => {
    await seedDoc('moderation_logs', 'log1', { action: 'ban', targetId: 'bob' });
    const db = authed('alice').firestore();
    await assertFails(db.collection('moderation_logs').doc('log1').get());
  });

  test('Regular user cannot write to moderation_logs', async () => {
    const db = authed('alice').firestore();
    await assertFails(
      db.collection('moderation_logs').doc('fake_log').set({ action: 'ban' })
    );
  });

  test('Regular user cannot write to admin collection', async () => {
    const db = authed('alice').firestore();
    await assertFails(
      db.collection('admin').doc('config').set({ masterKey: 'stolen' })
    );
  });

  test('notificationQueue is write-locked (server only)', async () => {
    const db = authed('alice').firestore();
    await assertFails(
      db.collection('notificationQueue').add({ to: 'alice', message: 'test' })
    );
  });
});

// ═══════════════════════════════════════════════════════════════════════════
// TEST SUITE 8: REPORTS COLLECTION
// ═══════════════════════════════════════════════════════════════════════════

describe('reports collection', () => {
  test('Authenticated user can file a report against someone else', async () => {
    const db = authed('alice').firestore();
    await assertSucceeds(
      db.collection('reports').add({
        reporterId: 'alice',
        reportedId: 'bob',
        reason: 'Harassment in the chat room.',
      })
    );
  });

  test('User CANNOT file a report against themselves', async () => {
    const db = authed('alice').firestore();
    await assertFails(
      db.collection('reports').add({
        reporterId: 'alice',
        reportedId: 'alice',  // Same as reporter
        reason: 'Self-report abuse.',
      })
    );
  });

  test('User CANNOT spoof the reporterId', async () => {
    const db = authed('mallory').firestore();
    await assertFails(
      db.collection('reports').add({
        reporterId: 'alice',  // Not mallory
        reportedId: 'bob',
        reason: 'Framing alice.',
      })
    );
  });

  test('Reports are NOT readable by regular users', async () => {
    await seedDoc('reports', 'report1', { reporterId: 'alice', reportedId: 'bob', reason: 'spam' });
    const db = authed('alice').firestore();
    await assertFails(db.collection('reports').doc('report1').get());
  });
});

// ═══════════════════════════════════════════════════════════════════════════
// TEST SUITE 9: CHATS / MESSAGES
// ═══════════════════════════════════════════════════════════════════════════

describe('chats collection', () => {
  test('Participant can read chat', async () => {
    await seedDoc('chats', 'chat1', { participants: ['alice', 'bob'] });
    const db = authed('alice').firestore();
    await assertSucceeds(db.collection('chats').doc('chat1').get());
  });

  test('Non-participant CANNOT read chat', async () => {
    await seedDoc('chats', 'chat1', { participants: ['alice', 'bob'] });
    const db = authed('mallory').firestore();
    await assertFails(db.collection('chats').doc('chat1').get());
  });

  test('Non-participant CANNOT send messages to a chat', async () => {
    await seedDoc('chats', 'chat1', { participants: ['alice', 'bob'] });
    const db = authed('mallory').firestore();
    await assertFails(
      db.collection('chats').doc('chat1').collection('messages').add({
        senderId: 'mallory',
        text: 'Injected message',
      })
    );
  });

  test('User CANNOT spoof senderId in a message', async () => {
    await seedDoc('chats', 'chat1', { participants: ['alice', 'bob'] });
    const db = authed('alice').firestore();
    await assertFails(
      db.collection('chats').doc('chat1').collection('messages').add({
        senderId: 'bob',  // Not alice
        text: 'Spoofed',
      })
    );
  });

  test('Participant can send message with correct senderId', async () => {
    await seedDoc('chats', 'chat1', { participants: ['alice', 'bob'] });
    const db = authed('alice').firestore();
    await assertSucceeds(
      db.collection('chats').doc('chat1').collection('messages').add({
        senderId: 'alice',
        text: 'Hello Bob!',
      })
    );
  });
});
