const admin = require("firebase-admin");
const path = require("path");
const fs = require("fs");

// Check if we're in the functions directory
const credentialsPath = path.resolve(__dirname, "../functions");

// Try to initialize with default credentials (works in Firebase environment)
try {
  admin.initializeApp();
  console.log("✅ Firebase initialized with default credentials");
} catch (e) {
  console.log("⚠️  Using default app initialization");
}

const db = admin.firestore();

async function updateConfig() {
  try {
    console.log("\n🔧 Updating Firestore config/agora with Agora credentials...\n");

    const result = await db.collection("config").doc("agora").set(
      {
        appId: "ec1b578586d24976a89d787d9ee4d5c7",
        appCertificate: "79a3e92a657042d08c3c26a26d1e70b6",
        updatedAt: new Date().toISOString(),
        updatedBy: "script",
      },
      { merge: true },
    );

    console.log("✅ Successfully updated Agora config in Firestore!");
    console.log("   📄 Document: config/agora");
    console.log("   🔑 AppId: ec1b578586d24976a89d787d9ee4d5c7");
    console.log("   🔐 AppCertificate: 79a3e92a657042d08c3c26a26d1e70b6");
    console.log("   ⏰ Updated: " + new Date().toISOString());
    console.log("\n✨ Config is ready. Your token generation should work now!\n");

    process.exit(0);
  } catch (error) {
    console.error("\n❌ Error updating Firestore:", error.message);
    console.error("\nPossible solutions:");
    console.error("1. Ensure you are logged in: firebase login");
    console.error("2. Check your project is set: firebase use mix-and-mingle-v2");
    console.error("3. Make sure Firestore is enabled in your Firebase project");
    process.exit(1);
  }
}

updateConfig();
