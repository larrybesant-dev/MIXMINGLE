const admin = require('firebase-admin');

// Initialize Firebase Admin
const serviceAccount = require('./serviceAccountKey.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function deleteAllRoomsExcept(keepRoomId) {
  try {
    console.log(`🔍 Fetching all rooms...`);
    const roomsSnapshot = await db.collection('rooms').get();

    console.log(`📊 Found ${roomsSnapshot.size} rooms total`);

    let deleteCount = 0;

    for (const doc of roomsSnapshot.docs) {
      if (doc.id !== keepRoomId) {
        console.log(`🗑️  Deleting room: ${doc.id} (${doc.data().title || 'Untitled'})`);

        // Delete subcollections first
        const participantsSnap = await doc.ref.collection('participants').get();
        for (const participantDoc of participantsSnap.docs) {
          await participantDoc.ref.delete();
        }

        const messagesSnap = await doc.ref.collection('messages').get();
        for (const messageDoc of messagesSnap.docs) {
          await messageDoc.ref.delete();
        }

        const eventsSnap = await doc.ref.collection('events').get();
        for (const eventDoc of eventsSnap.docs) {
          await eventDoc.ref.delete();
        }

        // Delete the room document
        await doc.ref.delete();
        deleteCount++;
      } else {
        console.log(`✅ Keeping room: ${doc.id} (${doc.data().title || 'Untitled'})`);
      }
    }

    console.log(`\n✅ Cleanup complete!`);
    console.log(`📊 Deleted ${deleteCount} rooms`);
    console.log(`📊 Kept 1 room (${keepRoomId})`);

  } catch (error) {
    console.error('❌ Error:', error);
  } finally {
    process.exit(0);
  }
}

// Run the cleanup
const keepRoomId = 'DoWJnySEtTtEZsaB80RR';
deleteAllRoomsExcept(keepRoomId);
