const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// Function to force-close a room
exports.forceCloseRoom = functions.https.onCall(async (data, context) => {
    const { roomId, userId } = data;
    // Only owner or assigned admin can force-close
    const userDoc = await admin.firestore().collection('admin_roles').doc(userId).get();
    if (!userDoc.exists) throw new functions.https.HttpsError('not-found', 'Role not found');
    const role = userDoc.data();
    if (role.roleType !== 'owner' && !(role.roleType === 'admin' && role.roomIds.includes(roomId))) {
        throw new functions.https.HttpsError('permission-denied', 'Not authorized');
    }
    // Mark room as closed
    await admin.firestore().collection('rooms').doc(roomId).update({ status: 'closed' });
    return { success: true };
});

// Function to suspend/ban user
exports.suspendUser = functions.https.onCall(async (data, context) => {
    const { targetUserId, reason, userId } = data;
    // Only owner/admin can suspend/ban
    const userDoc = await admin.firestore().collection('admin_roles').doc(userId).get();
    if (!userDoc.exists) throw new functions.https.HttpsError('not-found', 'Role not found');
    const role = userDoc.data();
    if (role.roleType !== 'owner' && role.roleType !== 'admin') {
        throw new functions.https.HttpsError('permission-denied', 'Not authorized');
    }
    await admin.firestore().collection('users').doc(targetUserId).update({ suspended: true, suspensionReason: reason });
    return { success: true };
});
