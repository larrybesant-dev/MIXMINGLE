const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// Function to mute/unmute user in audio room
exports.muteUser = functions.https.onCall(async (data, context) => {
    const { roomId, userId, mute } = data;
    // Only owner/admin can mute/unmute
    const roomDoc = await admin.firestore().collection('rooms').doc(roomId).get();
    const ownerId = roomDoc.data().ownerId;
    const admins = roomDoc.data().admins || [];
    if (context.auth.uid !== ownerId && !admins.includes(context.auth.uid)) {
        throw new functions.https.HttpsError('permission-denied', 'Not authorized');
    }
    await admin.firestore().collection('rooms').doc(roomId)
        .collection('speakers').doc(userId)
        .set({ muted: mute }, { merge: true });
    return { success: true };
});

// Function to kick user from audio room
exports.kickUser = functions.https.onCall(async (data, context) => {
    const { roomId, userId } = data;
    // Only owner/admin can kick
    const roomDoc = await admin.firestore().collection('rooms').doc(roomId).get();
    const ownerId = roomDoc.data().ownerId;
    const admins = roomDoc.data().admins || [];
    if (context.auth.uid !== ownerId && !admins.includes(context.auth.uid)) {
        throw new functions.https.HttpsError('permission-denied', 'Not authorized');
    }
    await admin.firestore().collection('rooms').doc(roomId)
        .collection('speakers').doc(userId).delete();
    await admin.firestore().collection('rooms').doc(roomId)
        .collection('micQueue').doc(userId).delete();
    return { success: true };
});
