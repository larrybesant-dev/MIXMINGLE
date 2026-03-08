const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

// Cloud Function to log admin actions
exports.logAdminAction = functions.firestore.document('admin_actions/{actionId}')
    .onCreate(async (snap, context) => {
        const action = snap.data();
        // Add log to admin_logs collection
        await admin.firestore().collection('admin_logs').add({
            actionId: context.params.actionId,
            userId: action.userId,
            actionType: action.actionType,
            targetId: action.targetId,
            timestamp: admin.firestore.FieldValue.serverTimestamp(),
        });
    });

// Cloud Function to send notifications to admins/owner
exports.sendAdminNotification = functions.firestore.document('reports/{reportId}')
    .onUpdate(async (change, context) => {
        const report = change.after.data();
        if (report.status === 'flagged') {
            // Send FCM notification to owner/admin
            // (implementation placeholder)
        }
    });
