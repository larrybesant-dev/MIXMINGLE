/**
 * SPEED DATING - SERVER-AUTHORITATIVE SESSION MANAGEMENT
 *
 * CRITICAL: Prevents users from:
 * - Extending sessions beyond 5 minutes
 * - Submitting decisions after expiry
 * - Gaming the matching system
 *
 * Flow:
 * 1. Session created → onSessionCreated triggers
 * 2. Schedules Cloud Task to expire session at endTime
 * 3. expireSession fires → marks session 'expired', forces disconnect
 * 4. Client detects expiry → local Agora disconnect + UI redirect
 */

import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { onTaskDispatched } from "firebase-functions/v2/tasks";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";

const SESSION_DURATION_MS = 5 * 60 * 1000; // 5 minutes

// ============================================================
// TRIGGER: When speed dating session created
// ============================================================
export const onSpeedDatingSessionCreated = onDocumentCreated(
  {
    document: "speed_dating_sessions/{sessionId}",
    region: "us-central1",
  },
  async (event) => {
    const sessionId = event.params.sessionId;
    const sessionData = event.data?.data();

    if (!sessionData) {
      logger.warn(`Session ${sessionId} has no data`);
      return;
    }

    try {
      logger.info(`[SpeedDating] Session ${sessionId} created, scheduling expiry`);

      // Calculate end time (5 minutes from now)
      const startTime = sessionData.startedAt
        ? new Date(sessionData.startedAt.toMillis())
        : new Date();
      const endTime = new Date(startTime.getTime() + SESSION_DURATION_MS);

      // Update session with endTime
      await admin
        .firestore()
        .collection("speed_dating_sessions")
        .doc(sessionId)
        .update({
          endTime: admin.firestore.Timestamp.fromDate(endTime),
          expiresAt: admin.firestore.Timestamp.fromDate(endTime),
          duration: SESSION_DURATION_MS,
        });

      logger.info(`[SpeedDating] Session ${sessionId} will expire at ${endTime.toISOString()}`);

      // Schedule expiration via delayed write (simpler than Cloud Tasks)
      // In production, use Cloud Tasks for precise timing
      setTimeout(async () => {
        await expireSessionInternal(sessionId);
      }, SESSION_DURATION_MS);
    } catch (error) {
      logger.error(`[SpeedDating] Error setting up session ${sessionId}:`, error);
    }
  },
);

// ============================================================
// INTERNAL: Expire session (called by timer)
// ============================================================
async function expireSessionInternal(sessionId: string): Promise<void> {
  try {
    const sessionRef = admin.firestore().collection("speed_dating_sessions").doc(sessionId);

    const sessionSnap = await sessionRef.get();
    if (!sessionSnap.exists) {
      logger.warn(`[SpeedDating] Session ${sessionId} not found for expiry`);
      return;
    }

    const sessionData = sessionSnap.data();
    if (sessionData?.status !== "active") {
      logger.info(
        `[SpeedDating] Session ${sessionId} already ${sessionData?.status}, skipping expiry`,
      );
      return;
    }

    logger.info(`[SpeedDating] ⏰ EXPIRING SESSION ${sessionId}`);

    // Mark session as expired
    await sessionRef.update({
      status: "expired",
      expiredAt: admin.firestore.FieldValue.serverTimestamp(),
      forceDisconnect: true, // Signal to clients to disconnect immediately
    });

    // Check if both users submitted decisions
    const decisions = sessionData?.decisions || {};
    const participants: string[] = sessionData?.participants || [];

    const bothDecided =
      participants.length === 2 && decisions[participants[0]] && decisions[participants[1]];

    if (!bothDecided) {
      logger.warn(`[SpeedDating] Session ${sessionId} expired without both decisions`);

      // Auto-submit "pass" for users who didn't decide
      const updates: Record<string, string> = {};
      for (const userId of participants) {
        if (!decisions[userId]) {
          updates[`decisions.${userId}`] = "pass";
        }
      }

      if (Object.keys(updates).length > 0) {
        await sessionRef.update({
          ...updates,
          autoCompleted: true,
        });
      }
    }

    logger.info(`[SpeedDating] ✅ Session ${sessionId} expired successfully`);
  } catch (error) {
    logger.error(`[SpeedDating] Error expiring session ${sessionId}:`, error);
    throw error;
  }
}

// ============================================================
// CALLABLE: Submit decision (with server-side validation)
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

    // Validate decision value
    const validDecisions = ["keep", "pass", "exchange", "reconnect", "discard"];
    if (!validDecisions.includes(decision)) {
      throw new HttpsError(
        "invalid-argument",
        `Invalid decision. Must be one of: ${validDecisions.join(", ")}`,
      );
    }

    try {
      const sessionRef = admin.firestore().collection("speed_dating_sessions").doc(sessionId);

      const sessionSnap = await sessionRef.get();
      if (!sessionSnap.exists) {
        throw new HttpsError("not-found", "Session not found");
      }

      const sessionData = sessionSnap.data();
      if (!sessionData) {
        throw new HttpsError("not-found", "Session data missing");
      }

      // CRITICAL: Check if session is still active
      if (sessionData.status !== "active") {
        throw new HttpsError(
          "failed-precondition",
          `Cannot submit decision: session is ${sessionData.status}`,
        );
      }

      // CRITICAL: Check if session has expired (server time check)
      const now = admin.firestore.Timestamp.now();
      const endTime = sessionData.endTime || sessionData.expiresAt;

      if (endTime && now.toMillis() > endTime.toMillis()) {
        // Session expired but not yet marked - expire it now
        await expireSessionInternal(sessionId);
        throw new HttpsError(
          "deadline-exceeded",
          "Session has expired. Decisions are no longer accepted.",
        );
      }

      // Verify user is a participant
      const participants: string[] = sessionData.participants || [];
      if (!participants.includes(userId)) {
        throw new HttpsError("permission-denied", "User is not a participant in this session");
      }

      // Check if user already decided
      const decisions = sessionData.decisions || {};
      if (decisions[userId]) {
        throw new HttpsError("already-exists", "Decision already submitted for this session");
      }

      // Submit decision
      await sessionRef.update({
        [`decisions.${userId}`]: decision,
        lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
      });

      logger.info(`[SpeedDating] User ${userId} decided: ${decision}`);

      // Check if both users have decided
      const otherUserId = participants.find((id) => id !== userId);
      if (!otherUserId) {
        throw new HttpsError("internal", "Could not find other participant");
      }

      const updatedDecisions = { ...decisions, [userId]: decision };

      if (updatedDecisions[otherUserId]) {
        // Both decided - check for mutual match
        const userDecision = decision;
        const otherDecision = updatedDecisions[otherUserId];

        const isPositive = (d: string) => d === "keep" || d === "exchange" || d === "reconnect";
        const isMutual = isPositive(userDecision) && isPositive(otherDecision);

        // Mark session as completed
        await sessionRef.update({
          status: "completed",
          completedAt: admin.firestore.FieldValue.serverTimestamp(),
          isMutual,
        });

        if (isMutual) {
          // Create mutual match record
          await admin.firestore().collection("speed_dating_results").add({
            sessionId,
            user1Id: userId,
            user2Id: otherUserId,
            matchedAt: admin.firestore.FieldValue.serverTimestamp(),
            type: "mutual_match",
          });

          logger.info(`[SpeedDating] 💕 Mutual match: ${userId} ↔ ${otherUserId}`);
        }

        return { success: true, isMutual, completed: true };
      }

      // Only one user decided so far
      return { success: true, isMutual: false, completed: false };
    } catch (error) {
      if (error instanceof HttpsError) {
        throw error;
      }
      logger.error("[SpeedDating] Error submitting decision:", error);
      throw new HttpsError("internal", "Failed to submit decision");
    }
  },
);

// ============================================================
// CALLABLE: Force leave session (user initiated)
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

    const { sessionId, reason } = request.data;

    if (!sessionId) {
      throw new HttpsError("invalid-argument", "sessionId is required");
    }

    try {
      const sessionRef = admin.firestore().collection("speed_dating_sessions").doc(sessionId);

      const sessionSnap = await sessionRef.get();
      if (!sessionSnap.exists) {
        throw new HttpsError("not-found", "Session not found");
      }

      const sessionData = sessionSnap.data();
      if (!sessionData) {
        throw new HttpsError("not-found", "Session data missing");
      }

      // Verify user is a participant
      const participants: string[] = sessionData.participants || [];
      if (!participants.includes(userId)) {
        throw new HttpsError("permission-denied", "User is not a participant in this session");
      }

      logger.info(
        `[SpeedDating] User ${userId} leaving session ${sessionId}. Reason: ${reason || "none"}`,
      );

      // Mark session as abandoned
      await sessionRef.update({
        status: "abandoned",
        abandonedAt: admin.firestore.FieldValue.serverTimestamp(),
        abandonedBy: userId,
        abandonReason: reason || "user_left",
        [`decisions.${userId}`]: "abandoned",
      });

      return { success: true };
    } catch (error) {
      if (error instanceof HttpsError) {
        throw error;
      }
      logger.error("[SpeedDating] Error leaving session:", error);
      throw new HttpsError("internal", "Failed to leave session");
    }
  },
);
