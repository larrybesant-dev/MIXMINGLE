const admin = require("firebase-admin");

// Initialize admin SDK (if not already initialized)
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

// Create a test room
const roomData = {
  name: "Test Room",
  description: "Room for testing Agora token generation",
  createdAt: admin.firestore.FieldValue.serverTimestamp(),
  createdBy: "DahcyIkN6DSnOeENNuWeC0dfGLQ2",
  isActive: true,
  participants: [],
};

db.collection("rooms")
  .doc("test-room-001")
  .set(roomData)
  .then(() => {
    console.log("✅ Test room created successfully!");
    console.log("Room ID: test-room-001");
    console.log("Room Name:", roomData.name);
    process.exit(0);
  })
  .catch((err) => {
    console.error("❌ Error creating room:", err);
    process.exit(1);
  });
