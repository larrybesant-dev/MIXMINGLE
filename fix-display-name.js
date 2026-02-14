// Firebase Admin script to check and fix display names
// Run: node fix-display-name.js

const admin = require('firebase-admin');

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  projectId: 'mix-and-mingle-v2'
});

const db = admin.firestore();
const auth = admin.auth();

async function fixDisplayName() {
  try {
    console.log('🔍 Checking display names for all users...\n');

    // Get current Firebase Auth user (larrybesant@gmail.com)
    const authUser = await auth.getUserByEmail('larrybesant@gmail.com');
    console.log(`👤 Firebase Auth User:`);
    console.log(`   UID: ${authUser.uid}`);
    console.log(`   Email: ${authUser.email}`);
    console.log(`   Display Name: ${authUser.displayName || '(empty)'}`);
    console.log();

    // Get Firestore profile
    const userDoc = await db.collection('users').doc(authUser.uid).get();

    if (!userDoc.exists) {
      console.log('❌ User document does not exist in Firestore!');
      return;
    }

    const userData = userDoc.data();
    console.log(`📄 Firestore Profile:`);
    console.log(`   displayName: ${userData.displayName || '(empty)'}`);
    console.log(`   username: ${userData.username || '(empty)'}`);
    console.log(`   email: ${userData.email || '(empty)'}`);
    console.log();

    // Check if displayName is empty
    if (!userData.displayName || userData.displayName.trim() === '') {
      console.log('⚠️  Display name is empty or null!');
      console.log('🔧 Fixing by setting displayName from username or email...\n');

      // Use username if available, otherwise use email prefix
      const newDisplayName = userData.username || userData.email?.split('@')[0] || 'User';

      // Update Firestore
      await db.collection('users').doc(authUser.uid).update({
        displayName: newDisplayName,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });

      console.log(`✅ Updated displayName to: "${newDisplayName}"`);
      console.log('   You can change this in the app by going to:');
      console.log('   Profile → Edit Profile → Display Name');
    } else {
      console.log('✅ Display name is already set correctly!');
      console.log(`   Current value: "${userData.displayName}"`);
    }

    console.log('\n🎉 Done! Refresh your app to see the changes.');

  } catch (error) {
    console.error('❌ Error:', error.message);
  } finally {
    process.exit(0);
  }
}

// Run the fix
fixDisplayName();
