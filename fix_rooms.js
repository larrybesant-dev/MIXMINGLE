const admin = require("firebase-admin");

admin.initializeApp({
  projectId: "mix-and-mingle-v2",
});

const db = admin.firestore();

async function fixRoomDocuments() {
  try {
    const roomsRef = db.collection("rooms");
    const snapshot = await roomsRef.get();

    console.log(`Found ${snapshot.size} rooms`);

    const batch = db.batch();
    let fixed = 0;

    snapshot.forEach((doc) => {
      const data = doc.data();
      const needsUpdate = {};

      // Add required fields if missing
      if (!data.title && !data.name) needsUpdate.title = "Unnamed Room";
      if (!data.description) needsUpdate.description = "";
      if (!data.hostId) needsUpdate.hostId = data.createdBy || "admin";
      if (!data.category) needsUpdate.category = "Other";
      if (!data.createdAt) needsUpdate.createdAt = admin.firestore.FieldValue.serverTimestamp();
      if (!data.updatedAt) needsUpdate.updatedAt = admin.firestore.FieldValue.serverTimestamp();
      if (data.isLive === undefined) needsUpdate.isLive = true;
      if (data.viewerCount === undefined) needsUpdate.viewerCount = 0;
      if (data.isPublic === undefined) needsUpdate.isPublic = true;
      if (!data.moderators) needsUpdate.moderators = [];
      if (!data.admins) needsUpdate.admins = data.createdBy ? [data.createdBy] : [];

      if (Object.keys(needsUpdate).length > 0) {
        console.log(`Fixing room ${doc.id}:`, needsUpdate);
        batch.update(doc.ref, needsUpdate);
        fixed++;
      }
    });

    if (fixed > 0) {
      await batch.commit();
      console.log(`✅ Fixed ${fixed} rooms`);
    } else {
      console.log("✅ All rooms are valid");
    }

    process.exit(0);
  } catch (error) {
    console.error("❌ Error fixing rooms:", error);
    process.exit(1);
  }
}

fixRoomDocuments();
