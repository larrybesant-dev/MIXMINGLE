/**
 * Firebase Cloud Functions for Push Notifications (v2 API)
 * Handles FCM token management, notification delivery, and scheduled tasks
 */

import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { onSchedule } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

/**
 * Helper function to fetch FCM tokens for a user
 * Supports both:
 * 1. Array field: users/{userId}.fcmTokens (legacy)
 * 2. Subcollection: users/{userId}/tokens/{tokenId} (frontend pattern)
 */
async function getUserFcmTokens(userId: string): Promise<string[]> {
  const tokens: string[] = [];

  try {
    // Method 1: Check for tokens subcollection (frontend pattern)
    const tokensSnap = await admin
      .firestore()
      .collection("users")
      .doc(userId)
      .collection("tokens")
      .get();

    tokensSnap.docs.forEach((doc) => {
      const data = doc.data();
      if (data.token) {
        tokens.push(data.token);
      }
    });

    // Method 2: Also check array field for backward compatibility
    const userDoc = await admin.firestore().collection("users").doc(userId).get();

    if (userDoc.exists) {
      const userData = userDoc.data();
      // Support both fcmTokens array and tokens array
      const arrayTokens = userData?.fcmTokens || userData?.tokens || [];
      arrayTokens.forEach((t: any) => {
        const tokenValue = typeof t === "string" ? t : t.token;
        if (tokenValue && !tokens.includes(tokenValue)) {
          tokens.push(tokenValue);
        }
      });
    }
  } catch (error) {
    logger.error("Error fetching FCM tokens:", error);
  }

  return tokens;
}

/**
 * Helper function to remove invalid FCM tokens
 * Removes from both subcollection and array field
 */
async function removeInvalidFcmTokens(userId: string, invalidTokens: string[]): Promise<void> {
  if (!invalidTokens || invalidTokens.length === 0) return;

  try {
    const batch = admin.firestore().batch();

    // Remove from tokens subcollection
    const tokensSnap = await admin
      .firestore()
      .collection("users")
      .doc(userId)
      .collection("tokens")
      .get();

    tokensSnap.docs.forEach((doc) => {
      const data = doc.data();
      const tokenValue = data.token;
      if (tokenValue && invalidTokens.includes(tokenValue)) {
        batch.delete(doc.ref);
      }
    });

    // Also remove from array fields (backward compatibility)
    const userRef = admin.firestore().collection("users").doc(userId);
    const userDoc = await userRef.get();

    if (userDoc.exists) {
      const userData = userDoc.data();

      // Clean fcmTokens array
      if (userData?.fcmTokens && Array.isArray(userData.fcmTokens)) {
        const tokensToRemove = userData.fcmTokens.filter((t: any) => {
          const val = typeof t === "string" ? t : t.token;
          return invalidTokens.includes(val);
        });
        if (tokensToRemove.length > 0) {
          batch.update(userRef, {
            fcmTokens: admin.firestore.FieldValue.arrayRemove(...tokensToRemove),
          });
        }
      }
    }

    await batch.commit();
    logger.info(`Removed ${invalidTokens.length} invalid tokens for user ${userId}`);
  } catch (error) {
    logger.error("Error removing invalid tokens:", error);
  }
}

/**
 * Process notification queue and send push notifications
 * Triggered when a new document is added to notificationQueue collection
 */
export const sendPushNotification = onDocumentCreated(
  "notificationQueue/{notificationId}",
  async (event) => {
    const snap = event.data;
    if (!snap) {
      logger.warn("No data associated with the event");
      return;
    }

    const data = snap.data();
    const { userId, title, body, type, data: customData } = data;

    // Get tokens - either from the queue document or fetch from user
    let tokens = data.tokens as string[] | undefined;
    if (!tokens || tokens.length === 0) {
      tokens = await getUserFcmTokens(userId);
    }

    if (!tokens || tokens.length === 0) {
      logger.log("No FCM tokens found for user:", userId);
      await snap.ref.update({ status: "failed", error: "No tokens" });
      return;
    }

    const message = {
      notification: {
        title: title,
        body: body,
      },
      data: {
        type: type || "general",
        ...(customData || {}),
      },
      tokens: tokens,
    };

    try {
      const response = await admin.messaging().sendEachForMulticast(message);

      logger.log(`Successfully sent ${response.successCount} messages`);

      if (response.failureCount > 0) {
        const failedTokens: string[] = [];
        response.responses.forEach((resp, idx) => {
          if (!resp.success) {
            failedTokens.push(tokens![idx]);
            logger.error("Error sending to token:", tokens![idx], resp.error);
          }
        });

        // Remove invalid tokens using the helper function
        if (failedTokens.length > 0) {
          await removeInvalidFcmTokens(userId, failedTokens);
        }
      }

      // Update status
      await snap.ref.update({
        status: "sent",
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        successCount: response.successCount,
        failureCount: response.failureCount,
      });
    } catch (error: any) {
      logger.error("Error sending notification:", error);
      await snap.ref.update({
        status: "failed",
        error: error.message,
      });
    }
  },
);

/**
 * Send notification when a new message is received
 */
export const onNewMessage = onDocumentCreated(
  "conversations/{conversationId}/messages/{messageId}",
  async (event) => {
    const snap = event.data;
    if (!snap) return;

    const message = snap.data();
    const { senderId, text } = message;
    const conversationId = event.params.conversationId;

    // Get conversation to find recipient
    const conversationSnap = await admin
      .firestore()
      .collection("conversations")
      .doc(conversationId)
      .get();

    if (!conversationSnap.exists) return;

    const conversation = conversationSnap.data();
    const recipientId = conversation?.participants?.find((id: string) => id !== senderId);

    if (!recipientId) return;

    // Get sender name
    const senderSnap = await admin.firestore().collection("users").doc(senderId).get();

    const senderName = senderSnap.exists ? senderSnap.data()?.displayName : "Someone";

    // Queue notification
    await admin
      .firestore()
      .collection("notificationQueue")
      .add({
        userId: recipientId,
        title: `New message from ${senderName}`,
        body: text?.length > 100 ? text.substring(0, 97) + "..." : text,
        type: "message",
        data: {
          conversationId: conversationId,
          senderId: senderId,
        },
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        status: "pending",
      });
  },
);

/**
 * Send notification when someone follows you
 */
export const onNewFollow = onDocumentCreated("follows/{followId}", async (event) => {
  const snap = event.data;
  if (!snap) return;

  const follow = snap.data();
  const { followerId, followingId } = follow;

  // Get follower name
  const followerSnap = await admin.firestore().collection("users").doc(followerId).get();

  const followerName = followerSnap.exists ? followerSnap.data()?.displayName : "Someone";

  // Queue notification
  await admin
    .firestore()
    .collection("notificationQueue")
    .add({
      userId: followingId,
      title: "New Follower",
      body: `${followerName} started following you`,
      type: "follow",
      data: {
        userId: followerId,
      },
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      status: "pending",
    });
});

/**
 * Send notification for event reminders
 * Run daily to check for upcoming events
 */
export const sendEventReminders = onSchedule(
  { schedule: "every day 09:00", region: "us-central1" },
  async () => {
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    tomorrow.setHours(0, 0, 0, 0);

    const tomorrowEnd = new Date(tomorrow);
    tomorrowEnd.setHours(23, 59, 59, 999);

    // Get events happening tomorrow
    const eventsSnap = await admin
      .firestore()
      .collection("events")
      .where("startTime", ">=", admin.firestore.Timestamp.fromDate(tomorrow))
      .where("startTime", "<=", admin.firestore.Timestamp.fromDate(tomorrowEnd))
      .get();

    for (const eventDoc of eventsSnap.docs) {
      const eventData = eventDoc.data();
      const { participants, title } = eventData;

      if (!participants || participants.length === 0) continue;

      // Send reminder to all participants
      for (const userId of participants) {
        await admin
          .firestore()
          .collection("notificationQueue")
          .add({
            userId: userId,
            title: "Event Reminder",
            body: `"${title}" is happening tomorrow!`,
            type: "eventReminder",
            data: {
              eventId: eventDoc.id,
            },
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            status: "pending",
          });
      }
    }

    logger.log(`Sent reminders for ${eventsSnap.size} events`);
    // No return value (void)
  },
);

/**
 * Clean up old notifications (older than 30 days)
 * Runs daily
 */
export const cleanupOldNotifications = onSchedule(
  { schedule: "every day 02:00", region: "us-central1" },
  async () => {
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    const oldNotificationsSnap = await admin
      .firestore()
      .collection("notifications")
      .where("createdAt", "<", admin.firestore.Timestamp.fromDate(thirtyDaysAgo))
      .get();

    const batch = admin.firestore().batch();
    oldNotificationsSnap.docs.forEach((doc) => {
      batch.delete(doc.ref);
    });

    await batch.commit();
    logger.log(`Deleted ${oldNotificationsSnap.size} old notifications`);
    // No return value (void)
  },
);
