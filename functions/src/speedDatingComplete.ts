/**
 * SPEED DATING - COMPLETE PRODUCTION SYSTEM
 *
 * Features:
 * - Automatic matching based on preferences
 * - Agora token generation
 * - Session lifecycle management
 * - Decision handling with match creation
 * - Server-side validation
 */

import { onSchedule } from "firebase-functions/v2/scheduler";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { onDocumentCreated, onDocumentUpdated } from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";
import { RtcTokenBuilder, RtcRole } from "agora-token";
import { defineSecret } from "firebase-functions/params";

// Define secrets at the top
const AGORA_APP_ID = defineSecret("AGORA_APP_ID");
const AGORA_APP_CERTIFICATE = defineSecret("AGORA_APP_CERTIFICATE");

const firestore = admin.firestore();

// Configuration
const SESSION_DURATION_MS = 5 * 60 * 1000; // 5 minutes
const TOKEN_EXPIRATION = 3600; // 1 hour

// ============================================================
// MATCHING ALGORITHM - Runs every 30 seconds
// ============================================================
export const matchSpeedDating = onSchedule(
  {
    schedule: "every 1 minutes",
    region: "us-central1",
    timeoutSeconds: 60,
  },
  async () => {
    try {
      logger.info("[SpeedDating] 🔄 Starting matching cycle");

      // Get all users in queue waiting to be matched
      const queueSnapshot = await firestore
        .collection("speed_dating_queue")
        .where("status", "==", "waiting")
        .orderBy("joinedAt", "asc")
        .limit(50)
        .get();

      if (queueSnapshot.empty) {
        logger.info("[SpeedDating] ⏸️  No users in queue");
        return;
      }

      const queuedUsers: Array<{
        id: string;
        preferences?: Record<string, any>;
        [key: string]: any;
      }> = queueSnapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }));

      logger.info(`[SpeedDating] 👥 Found ${queuedUsers.length} users in queue`);

      const matched: Set<string> = new Set();

      // Try to match users
      for (let i = 0; i < queuedUsers.length; i++) {
        if (matched.has(queuedUsers[i].id)) continue;

        const user1 = queuedUsers[i];
        const prefs1 = user1.preferences || {};

        // Find compatible match
        for (let j = i + 1; j < queuedUsers.length; j++) {
          if (matched.has(queuedUsers[j].id)) continue;

          const user2 = queuedUsers[j];
          const prefs2 = user2.preferences || {};

          // Check mutual compatibility
          if (areCompatible(user1, prefs1, user2, prefs2)) {
            logger.info(`[SpeedDating] 💖 Matching ${user1.id} with ${user2.id}`);

            await createSpeedDatingSession(user1, user2);

            matched.add(user1.id);
            matched.add(user2.id);
            break;
          }
        }
      }

      logger.info(`[SpeedDating] ✅ Matched ${matched.size} users`);
    } catch (error) {
      logger.error("[SpeedDating] ❌ Error in matching:", error);
    }
  },
);

// ============================================================
// COMPATIBILITY CHECK
// ============================================================
function areCompatible(user1: any, prefs1: any, user2: any, prefs2: any): boolean {
  // Age compatibility
  const age1 = user1.age || 0;
  const age2 = user2.age || 0;

  if (age1 < (prefs2.minAge || 18) || age1 > (prefs2.maxAge || 80)) {
    return false;
  }
  if (age2 < (prefs1.minAge || 18) || age2 > (prefs1.maxAge || 80)) {
    return false;
  }

  // Gender preference compatibility
  const gender1 = user1.gender || "other";
  const gender2 = user2.gender || "other";

  const genderPrefs1: string[] = prefs1.genderPreferences || [];
  const genderPrefs2: string[] = prefs2.genderPreferences || [];

  if (genderPrefs1.length > 0 && !genderPrefs1.includes(gender2)) {
    return false;
  }
  if (genderPrefs2.length > 0 && !genderPrefs2.includes(gender1)) {
    return false;
  }

  // Sexuality compatibility (optional)
  const sexuality2 = user2.sexuality;
  const sexuality1 = user1.sexuality;

  if (prefs1.sexuality && sexuality2 && prefs1.sexuality !== sexuality2) {
    return false;
  }
  if (prefs2.sexuality && sexuality1 && prefs2.sexuality !== sexuality1) {
    return false;
  }

  // Verified-only check
  if (prefs1.onlyVerified && !user2.isVerified) {
    return false;
  }
  if (prefs2.onlyVerified && !user1.isVerified) {
    return false;
  }

  return true;
}

// ============================================================
// CREATE SESSION
// ============================================================
async function createSpeedDatingSession(user1: any, user2: any): Promise<void> {
  const sessionId = firestore.collection("speed_dating_sessions").doc().id;
  const channelName = `speed_dating_${sessionId}`;
  const startedAt = admin.firestore.Timestamp.now();
  const endsAt = admin.firestore.Timestamp.fromMillis(startedAt.toMillis() + SESSION_DURATION_MS);

  const batch = firestore.batch();

  // Create session document
  const sessionRef = firestore.collection("speed_dating_sessions").doc(sessionId);
  batch.set(sessionRef, {
    id: sessionId,
    user1Id: user1.id,
    user2Id: user2.id,
    user1Name: user1.displayName || "User 1",
    user2Name: user2.displayName || "User 2",
    user1Photo: user1.photoUrl || null,
    user2Photo: user2.photoUrl || null,
    agoraChannel: channelName,
    status: "active",
    startedAt,
    endsAt,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    decisions: {},
  });

  // Update queue status for both users
  batch.update(firestore.collection("speed_dating_queue").doc(user1.id), {
    status: "matched",
    sessionId,
    matchedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  batch.update(firestore.collection("speed_dating_queue").doc(user2.id), {
    status: "matched",
    sessionId,
    matchedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // Update users' active session
  batch.update(firestore.collection("users").doc(user1.id), {
    activeSpeedDatingSession: sessionId,
  });

  batch.update(firestore.collection("users").doc(user2.id), {
    activeSpeedDatingSession: sessionId,
  });

  await batch.commit();

  logger.info(`[SpeedDating] ✅ Created session ${sessionId}`);
}

// ============================================================
// GENERATE AGORA TOKEN
// ============================================================
export const generateSpeedDatingAgoraToken = onCall(
  {
    region: "us-central1",
    cors: true,
    secrets: [AGORA_APP_ID, AGORA_APP_CERTIFICATE],
  },
  async (request) => {
    const userId = request.auth?.uid;
    if (!userId) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    const { sessionId, uid } = request.data;

    if (!sessionId || uid === undefined) {
      throw new HttpsError("invalid-argument", "sessionId and uid are required");
    }

    try {
      // Verify session exists and user is a participant
      const sessionDoc = await firestore.collection("speed_dating_sessions").doc(sessionId).get();

      if (!sessionDoc.exists) {
        throw new HttpsError("not-found", "Session not found");
      }

      const sessionData = sessionDoc.data();
      if (!sessionData) {
        throw new HttpsError("not-found", "Session data missing");
      }

      // Verify user is a participant
      if (sessionData.user1Id !== userId && sessionData.user2Id !== userId) {
        throw new HttpsError("permission-denied", "User is not a participant in this session");
      }

      // Verify session is active
      if (sessionData.status !== "active") {
        throw new HttpsError("failed-precondition", `Session is ${sessionData.status}`);
      }

      // Generate Agora token
      const channelName = sessionData.agoraChannel;
      const expirationTime = Math.floor(Date.now() / 1000) + TOKEN_EXPIRATION;

      const appId = AGORA_APP_ID.value();
      const appCertificate = AGORA_APP_CERTIFICATE.value();
      if (!appId || !appCertificate) {
        throw new HttpsError("internal", "Agora credentials not configured.");
      }
      const token = RtcTokenBuilder.buildTokenWithUid(
        appId,
        appCertificate,
        channelName,
        uid,
        RtcRole.PUBLISHER,
        expirationTime,
        expirationTime,
      );

      logger.info(`[SpeedDating] 🎫 Generated token for user ${userId} in session ${sessionId}`);

      return {
        token,
        channelName,
        appId: AGORA_APP_ID,
        uid,
        expiresAt: expirationTime,
      };
    } catch (error) {
      logger.error("[SpeedDating] Error generating token:", error);
      throw error;
    }
  },
);

// ============================================================
// SUBMIT DECISION
// ============================================================
export const submitSpeedDatingDecision = onCall(
  {
    region: "us-central1",
    cors: true,
  },
  async (request) => {
    const userId = request.auth?.uid;
    if (!userId) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    const { sessionId, decision } = request.data;

    if (!sessionId || !decision) {
      throw new HttpsError("invalid-argument", "sessionId and decision are required");
    }

    // Validate decision
    if (!["like", "pass"].includes(decision)) {
      throw new HttpsError("invalid-argument", "decision must be 'like' or 'pass'");
    }

    try {
      const sessionRef = firestore.collection("speed_dating_sessions").doc(sessionId);

      const sessionDoc = await sessionRef.get();
      if (!sessionDoc.exists) {
        throw new HttpsError("not-found", "Session not found");
      }

      const sessionData = sessionDoc.data();
      if (!sessionData) {
        throw new HttpsError("not-found", "Session data missing");
      }

      // Verify session is active
      if (sessionData.status !== "active") {
        throw new HttpsError(
          "failed-precondition",
          `Cannot submit decision: session is ${sessionData.status}`,
        );
      }

      // Verify user is a participant
      if (sessionData.user1Id !== userId && sessionData.user2Id !== userId) {
        throw new HttpsError("permission-denied", "User is not a participant in this session");
      }

      // Record decision
      await sessionRef.update({
        [`decisions.${userId}`]: decision,
        [`${userId}DecisionAt`]: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Store decision in history
      await firestore.collection("speed_dating_decisions").add({
        sessionId,
        userId,
        decision,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Check if both users have decided
      const updatedDoc = await sessionRef.get();
      const updatedData = updatedDoc.data();
      const decisions = updatedData?.decisions || {};

      const user1Decision = decisions[sessionData.user1Id];
      const user2Decision = decisions[sessionData.user2Id];

      if (user1Decision && user2Decision) {
        logger.info(`[SpeedDating] 🎯 Both users decided in session ${sessionId}`);

        // Check for mutual match
        if (user1Decision === "like" && user2Decision === "like") {
          logger.info(`[SpeedDating] 💖 MATCH! Creating chat`);

          // Create match and chat
          await createMatch(sessionData.user1Id, sessionData.user2Id, sessionData);
        }

        // Mark session as completed
        await sessionRef.update({
          status: "completed",
          completedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      logger.info(`[SpeedDating] ✅ Decision recorded for user ${userId} in session ${sessionId}`);

      return { success: true };
    } catch (error) {
      logger.error("[SpeedDating] Error submitting decision:", error);
      throw error;
    }
  },
);

// ============================================================
// CREATE MATCH
// ============================================================
async function createMatch(user1Id: string, user2Id: string, sessionData: any): Promise<void> {
  const chatId = firestore.collection("chats").doc().id;

  const batch = firestore.batch();

  // Create chat
  const chatRef = firestore.collection("chats").doc(chatId);
  batch.set(chatRef, {
    id: chatId,
    participantIds: [user1Id, user2Id],
    participantNames: {
      [user1Id]: sessionData.user1Name,
      [user2Id]: sessionData.user2Name,
    },
    participantPhotos: {
      [user1Id]: sessionData.user1Photo || null,
      [user2Id]: sessionData.user2Photo || null,
    },
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    lastMessage: "🎉 You matched!",
    lastMessageTimestamp: admin.firestore.FieldValue.serverTimestamp(),
    unreadCount: {
      [user1Id]: 0,
      [user2Id]: 0,
    },
  });

  // Add system message
  const messageRef = chatRef.collection("messages").doc();
  batch.set(messageRef, {
    senderId: "system",
    text: "🎉 You matched! Start chatting now!",
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    type: "system",
  });

  // Add to matches arrays
  batch.update(firestore.collection("users").doc(user1Id), {
    matches: admin.firestore.FieldValue.arrayUnion(user2Id),
  });

  batch.update(firestore.collection("users").doc(user2Id), {
    matches: admin.firestore.FieldValue.arrayUnion(user1Id),
  });

  await batch.commit();

  logger.info(`[SpeedDating] ✅ Created match and chat ${chatId}`);
}

// ============================================================
// END SESSION (triggered when session expires)
// ============================================================
export const endSpeedDatingSession = onDocumentUpdated(
  {
    document: "speed_dating_sessions/{sessionId}",
    region: "us-central1",
  },
  async (event) => {
    const sessionId = event.params.sessionId;
    const beforeData = event.data?.before.data();
    const afterData = event.data?.after.data();

    if (!afterData || !beforeData) return;

    // Check if session just completed
    if (beforeData.status === "active" && afterData.status === "completed") {
      logger.info(`[SpeedDating] 🏁 Session ${sessionId} completed`);

      // Clean up queue entries
      const batch = firestore.batch();

      batch.delete(firestore.collection("speed_dating_queue").doc(afterData.user1Id));
      batch.delete(firestore.collection("speed_dating_queue").doc(afterData.user2Id));

      // Clear active session from users
      batch.update(firestore.collection("users").doc(afterData.user1Id), {
        activeSpeedDatingSession: admin.firestore.FieldValue.delete(),
      });

      batch.update(firestore.collection("users").doc(afterData.user2Id), {
        activeSpeedDatingSession: admin.firestore.FieldValue.delete(),
      });

      await batch.commit();

      logger.info(`[SpeedDating] ✅ Cleaned up session ${sessionId}`);
    }
  },
);

// ============================================================
// LEAVE SESSION (user cancels mid-session)
// ============================================================
export const leaveSpeedDatingSession = onCall(
  {
    region: "us-central1",
    cors: true,
  },
  async (request) => {
    const userId = request.auth?.uid;
    if (!userId) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    const { sessionId } = request.data;

    if (!sessionId) {
      throw new HttpsError("invalid-argument", "sessionId is required");
    }

    try {
      const sessionRef = firestore.collection("speed_dating_sessions").doc(sessionId);

      const sessionDoc = await sessionRef.get();
      if (!sessionDoc.exists) {
        throw new HttpsError("not-found", "Session not found");
      }

      const sessionData = sessionDoc.data();
      if (!sessionData) {
        throw new HttpsError("not-found", "Session data missing");
      }

      // Verify user is a participant
      if (sessionData.user1Id !== userId && sessionData.user2Id !== userId) {
        throw new HttpsError("permission-denied", "User is not a participant in this session");
      }

      // Mark session as cancelled
      await sessionRef.update({
        status: "cancelled",
        cancelledBy: userId,
        cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      logger.info(`[SpeedDating] ❌ User ${userId} left session ${sessionId}`);

      return { success: true };
    } catch (error) {
      logger.error("[SpeedDating] Error leaving session:", error);
      throw error;
    }
  },
);

// ============================================================
// JOIN QUEUE (with preferences)
// ============================================================
export const joinSpeedDatingQueue = onCall(
  {
    region: "us-central1",
    cors: true,
  },
  async (request) => {
    const userId = request.auth?.uid;
    if (!userId) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    const { preferences } = request.data;

    try {
      // Get user profile
      const userDoc = await firestore.collection("users").doc(userId).get();
      if (!userDoc.exists) {
        throw new HttpsError("not-found", "User profile not found");
      }

      const userData = userDoc.data();
      if (!userData) {
        throw new HttpsError("not-found", "User data missing");
      }

      // Verify user has completed onboarding
      if (!userData.hasCompletedOnboarding) {
        throw new HttpsError("failed-precondition", "Please complete onboarding first");
      }

      // Check if already in queue
      const existingQueue = await firestore.collection("speed_dating_queue").doc(userId).get();

      if (existingQueue.exists) {
        throw new HttpsError("already-exists", "Already in queue");
      }

      // Add to queue
      await firestore
        .collection("speed_dating_queue")
        .doc(userId)
        .set({
          userId,
          displayName: userData.displayName || "Anonymous",
          photoUrl: userData.photoUrl || null,
          age: userData.age || 18,
          gender: userData.gender || "other",
          sexuality: userData.sexuality || null,
          isVerified: userData.isVerified || false,
          preferences: preferences || {},
          status: "waiting",
          joinedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

      // Update user's speed dating preferences
      if (preferences) {
        await firestore.collection("users").doc(userId).update({
          speedDatingPreferences: preferences,
        });
      }

      logger.info(`[SpeedDating] ✅ User ${userId} joined queue`);

      return { success: true };
    } catch (error) {
      logger.error("[SpeedDating] Error joining queue:", error);
      throw error;
    }
  },
);

// ============================================================
// LEAVE QUEUE
// ============================================================
export const leaveSpeedDatingQueue = onCall(
  {
    region: "us-central1",
    cors: true,
  },
  async (request) => {
    const userId = request.auth?.uid;
    if (!userId) {
      throw new HttpsError("unauthenticated", "User must be authenticated");
    }

    try {
      await firestore.collection("speed_dating_queue").doc(userId).delete();

      logger.info(`[SpeedDating] ✅ User ${userId} left queue`);

      return { success: true };
    } catch (error) {
      logger.error("[SpeedDating] Error leaving queue:", error);
      throw error;
    }
  },
);

// ============================================================
// AUTO-EXPIRE SESSIONS (runs every minute)
// ============================================================
export const autoExpireSpeedDatingSessions = onSchedule(
  {
    schedule: "every 1 minutes",
    region: "us-central1",
  },
  async () => {
    try {
      const now = admin.firestore.Timestamp.now();

      const expiredSessions = await firestore
        .collection("speed_dating_sessions")
        .where("status", "==", "active")
        .where("endsAt", "<=", now)
        .get();

      if (expiredSessions.empty) {
        logger.info("[SpeedDating] ⏸️  No expired sessions");
        return;
      }

      logger.info(`[SpeedDating] ⏰ Found ${expiredSessions.size} expired sessions`);

      const batch = firestore.batch();

      for (const doc of expiredSessions.docs) {
        const sessionData = doc.data();

        // Auto-complete with "pass" for undecided users
        const decisions = sessionData.decisions || {};
        const updates: any = {
          status: "expired",
          expiredAt: admin.firestore.FieldValue.serverTimestamp(),
        };

        if (!decisions[sessionData.user1Id]) {
          updates[`decisions.${sessionData.user1Id}`] = "pass";
        }
        if (!decisions[sessionData.user2Id]) {
          updates[`decisions.${sessionData.user2Id}`] = "pass";
        }

        batch.update(doc.ref, updates);
      }

      await batch.commit();

      logger.info(`[SpeedDating] ✅ Expired ${expiredSessions.size} sessions`);
    } catch (error) {
      logger.error("[SpeedDating] Error expiring sessions:", error);
    }
  },
);
