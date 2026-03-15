// Firebase Admin script to DELETE ALL USER ACCOUNTS
// WARNING: This is IRREVERSIBLE! It will delete all users from Auth and Firestore.
// Run: node delete-all-users.js

const admin = require("firebase-admin");
const readline = require("readline");

// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  projectId: "mix-and-mingle-v2",
});

const db = admin.firestore();
const auth = admin.auth();

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
});

function askQuestion(query) {
  return new Promise((resolve) => rl.question(query, resolve));
}

async function deleteAllUsers() {
  try {
    console.log("🔥 DELETE ALL USERS - Mix & Mingle v2");
    console.log("=".repeat(60));
    console.log("⚠️  WARNING: This will permanently delete:");
    console.log("   - All Firebase Authentication users");
    console.log("   - All Firestore user documents");
    console.log("   - This action CANNOT be undone!");
    console.log("=".repeat(60));
    console.log();

    // Step 1: List all users
    console.log("📋 Fetching all users...\n");

    const listUsersResult = await auth.listUsers();
    const authUsers = listUsersResult.users;

    if (authUsers.length === 0) {
      console.log("✅ No users found. Nothing to delete.");
      rl.close();
      process.exit(0);
    }

    console.log(`Found ${authUsers.length} user(s):\n`);
    authUsers.forEach((user, index) => {
      console.log(`${index + 1}. Email: ${user.email || "(no email)"}`);
      console.log(`   UID: ${user.uid}`);
      console.log(`   Created: ${user.metadata.creationTime}`);
      console.log();
    });

    // Step 2: Confirm deletion
    console.log("=".repeat(60));
    const confirmation = await askQuestion(
      `❓ Type "DELETE ALL" to confirm deletion of ${authUsers.length} user(s): `,
    );
    console.log();

    if (confirmation.trim() !== "DELETE ALL") {
      console.log("❌ Deletion cancelled. No users were deleted.");
      rl.close();
      process.exit(0);
    }

    // Step 3: Delete users
    console.log("🗑️  Deleting users...\n");

    let deletedAuth = 0;
    let deletedFirestore = 0;
    let errors = 0;

    for (const user of authUsers) {
      try {
        // Delete from Firebase Auth
        await auth.deleteUser(user.uid);
        deletedAuth++;
        console.log(`✅ Deleted Auth user: ${user.email || user.uid}`);

        // Delete from Firestore
        try {
          await db.collection("users").doc(user.uid).delete();
          deletedFirestore++;
          console.log(`   ✅ Deleted Firestore document`);
        } catch (firestoreError) {
          console.log(`   ⚠️  Firestore doc not found or already deleted`);
        }

        console.log();
      } catch (error) {
        errors++;
        console.log(`❌ Error deleting ${user.email || user.uid}: ${error.message}\n`);
      }
    }

    // Step 4: Summary
    console.log("=".repeat(60));
    console.log("📊 DELETION SUMMARY:");
    console.log(`   Firebase Auth users deleted: ${deletedAuth}`);
    console.log(`   Firestore documents deleted: ${deletedFirestore}`);
    console.log(`   Errors: ${errors}`);
    console.log("=".repeat(60));
    console.log();

    if (deletedAuth > 0) {
      console.log("🎉 All users have been deleted successfully!");
      console.log("   The app is now in a clean state.");
      console.log("   New users can register fresh.");
    }
  } catch (error) {
    console.error("❌ Fatal error:", error.message);
  } finally {
    rl.close();
    process.exit(0);
  }
}

// Run the deletion
deleteAllUsers();
