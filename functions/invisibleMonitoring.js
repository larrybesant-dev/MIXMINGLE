const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// Function to mark admin/owner as invisible in room presence
exports.setInvisiblePresence = functions.https.onCall(async (data, context) => {
    const { roomId, userId } = data;
    // Only owner/admin can set invisible presence
    const userDoc = await admin.firestore().collection('admin_roles').doc(userId).get();
    if (!userDoc.exists) throw new functions.https.HttpsError('not-found', 'Role not found');
    const role = userDoc.data();
    if (role.roleType !== 'owner' && role.roleType !== 'admin') {
        throw new functions.https.HttpsError('permission-denied', 'Not authorized');
    }
    // Mark invisible presence in room
    await admin.firestore().collection('rooms').doc(roomId)
        .collection('participants').doc(userId)
        .set({ invisible: true }, { merge: true });
    return { success: true };
});
