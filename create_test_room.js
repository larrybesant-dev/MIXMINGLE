const admin = require("firebase-admin");
const serviceAccount = require("./mix-and-mingle-v2-firebase-adminsdk-yh9fw-c2e2f6ede0.json");
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});
const db = admin.firestore();
db.collection("rooms")
  .doc("test-room-001")
  .set({
    name: "Test Room",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    createdBy: "DahcyIkN6DSnOeENNuWeC0dfGLQ2",
    isActive: true,
  })
  .then(() => {
    console.log("Room created successfully!");
    process.exit(0);
  })
  .catch((err) => {
    console.error("Error:", err);
    process.exit(1);
  });
