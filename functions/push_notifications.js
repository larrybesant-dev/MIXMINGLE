/**
 * Firebase Cloud Functions for Push Notifications (v2 API)
 * Handles FCM token management, notification delivery, and scheduled tasks
 * Deploy with: firebase deploy --only functions
 */

const { onDocumentCreated } = require('firebase-functions/v2/firestore');
const { onSchedule } = require('firebase-functions/v2/scheduler');
const admin = require('firebase-admin');
const logger = require('firebase-functions/logger');

// Don't initialize admin here - it's initialized in index.js

/**
 * Process notification queue and send push notifications
 * Triggered when a new document is added to notificationQueue collection
 */
exports.sendPushNotification = onDocumentCreated('notificationQueue/{notificationId}', async (event) => {
  const snap = event.data;
  if (!snap) {
    logger.warn('No data associated with the event');
    return;
  }

  const data = snap.data();
  const { userId, title, body, type, tokens, data: customData } = data;

  if (!tokens || tokens.length === 0) {
    logger.log('No FCM tokens found for user:', userId);
    await snap.ref.update({ status: 'failed', error: 'No tokens' });
    return;
  }

  const message = {
    notification: {
      title: title,
      body: body,
    },
    data: {
      type: type || 'general',
      ...(customData || {}),
    },
    tokens: tokens,
  };

  try {
    const response = await admin.messaging().sendEachForMulticast(message);

    logger.log(`Successfully sent ${response.successCount} messages`);

    if (response.failureCount > 0) {
      const failedTokens = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          failedTokens.push(tokens[idx]);
          logger.error('Error sending to token:', tokens[idx], resp.error);
        }
      });

      // Remove invalid tokens from user document
      if (failedTokens.length > 0) {
        const userRef = admin.firestore().collection('users').doc(userId);
        await userRef.update({
          fcmTokens: admin.firestore.FieldValue.arrayRemove(...failedTokens.map(token => ({ token }))),
        });
      }
    }

    // Update status
    await snap.ref.update({
      status: 'sent',
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
      successCount: response.successCount,
      failureCount: response.failureCount,
    });

  } catch (error) {
    logger.error('Error sending notification:', error);
    await snap.ref.update({
      status: 'failed',
      error: error.message,
    });
  }
});

/**
 * Send notification when a new message is received
 */
exports.onNewMessage = onDocumentCreated('conversations/{conversationId}/messages/{messageId}', async (event) => {
  const snap = event.data;
  if (!snap) return;

  const message = snap.data();
  const { senderId, text } = message;
  const conversationId = event.params.conversationId;

  // Get conversation to find recipient
  const conversationSnap = await admin.firestore()
    .collection('conversations')
    .doc(conversationId)
    .get();

  if (!conversationSnap.exists) return;

  const conversation = conversationSnap.data();
  const recipientId = conversation.participants.find(id => id !== senderId);

  if (!recipientId) return;

  // Get sender name
  const senderSnap = await admin.firestore()
    .collection('users')
    .doc(senderId)
    .get();

  const senderName = senderSnap.exists ? senderSnap.data().displayName : 'Someone';

  // Queue notification
  await admin.firestore().collection('notificationQueue').add({
    userId: recipientId,
    title: `New message from ${senderName}`,
    body: text.length > 100 ? text.substring(0, 97) + '...' : text,
    type: 'message',
    data: {
      conversationId: conversationId,
      senderId: senderId,
    },
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    status: 'pending',
  });
});

/**
 * Send notification when someone follows you
 */
exports.onNewFollow = onDocumentCreated('follows/{followId}', async (event) => {
  const snap = event.data;
  if (!snap) return;

  const follow = snap.data();
  const { followerId, followingId } = follow;

  // Get follower name
  const followerSnap = await admin.firestore()
    .collection('users')
    .doc(followerId)
    .get();

  const followerName = followerSnap.exists ? followerSnap.data().displayName : 'Someone';

  // Queue notification
  await admin.firestore().collection('notificationQueue').add({
    userId: followingId,
    title: 'New Follower',
    body: `${followerName} started following you`,
    type: 'follow',
    data: {
      userId: followerId,
    },
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    status: 'pending',
  });
});

/**
 * Send notification for event reminders
 * Run daily to check for upcoming events
 */
exports.sendEventReminders = onSchedule('every day 09:00', async (event) => {
  const now = admin.firestore.Timestamp.now();
  const tomorrow = new Date();
  tomorrow.setDate(tomorrow.getDate() + 1);
  tomorrow.setHours(0, 0, 0, 0);

  const tomorrowEnd = new Date(tomorrow);
  tomorrowEnd.setHours(23, 59, 59, 999);

  // Get events happening tomorrow
  const eventsSnap = await admin.firestore()
    .collection('events')
    .where('startTime', '>=', admin.firestore.Timestamp.fromDate(tomorrow))
    .where('startTime', '<=', admin.firestore.Timestamp.fromDate(tomorrowEnd))
    .get();

  for (const eventDoc of eventsSnap.docs) {
    const event = eventDoc.data();
    const { participants, title } = event;

    if (!participants || participants.length === 0) continue;

    // Send reminder to all participants
    for (const userId of participants) {
      await admin.firestore().collection('notificationQueue').add({
        userId: userId,
        title: 'Event Reminder',
        body: `"${title}" is happening tomorrow!`,
        type: 'eventReminder',
        data: {
          eventId: eventDoc.id,
        },
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        status: 'pending',
      });
    }
  }

  logger.log(`Sent reminders for ${eventsSnap.size} events`);
  return null;
});
});

/**
 * Clean up old notifications (older than 30 days)
 * Runs daily
 */
exports.cleanupOldNotifications = onSchedule('every day 02:00', async (event) => {
  const thirtyDaysAgo = new Date();
  thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

  const oldNotificationsSnap = await admin.firestore()
    .collection('notifications')
    .where('createdAt', '<', admin.firestore.Timestamp.fromDate(thirtyDaysAgo))
    .get();

  const batch = admin.firestore().batch();
  oldNotificationsSnap.docs.forEach(doc => {
    batch.delete(doc.ref);
  });

  await batch.commit();
  console.log(`Deleted ${oldNotificationsSnap.size} old notifications`);
  return null;
});
