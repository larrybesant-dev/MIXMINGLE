const admin = require("firebase-admin");
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function listRooms() {
  try {
    const roomsSnapshot = await db.collection("rooms").get();
    console.log(`\n📊 Total rooms: ${roomsSnapshot.size}\n`);

    roomsSnapshot.docs.forEach((doc) => {
      const data = doc.data();
      console.log(`ID: ${doc.id}`);
      console.log(`Title: ${data.title || "Untitled"}`);
      console.log(`Active: ${data.isActive}`);
      console.log(`---`);
    });
  } catch (error) {
    console.error("❌ Error:", error);
  } finally {
    process.exit(0);
  }
}

listRooms();
