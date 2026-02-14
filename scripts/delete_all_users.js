// Delete all Firebase Auth users
// Run with: node scripts/delete_all_users.js

const admin = require('firebase-admin');

// Initialize with application default credentials (uses Firebase CLI login)
admin.initializeApp({
  projectId: 'mix-and-mingle-v2'
});

async function deleteAllUsers() {
  console.log('Starting to delete all users...');

  let deletedCount = 0;
  let nextPageToken;

  do {
    const listUsersResult = await admin.auth().listUsers(1000, nextPageToken);

    const uids = listUsersResult.users.map(user => user.uid);

    if (uids.length > 0) {
      const deleteResult = await admin.auth().deleteUsers(uids);
      deletedCount += deleteResult.successCount;
      console.log(`Deleted ${deleteResult.successCount} users (${deleteResult.failureCount} failures)`);
    }

    nextPageToken = listUsersResult.pageToken;
  } while (nextPageToken);

  console.log(`\n✅ Total deleted: ${deletedCount} users`);
  console.log('Database and Auth are now clean!');
  process.exit(0);
}

deleteAllUsers().catch(err => {
  console.error('Error:', err);
  process.exit(1);
});
