import { onCall, HttpsError } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import * as logger from "firebase-functions/logger";
import { RtcTokenBuilder, RtcRole } from "agora-token";
import * as admin from "firebase-admin";
import { defineSecret } from "firebase-functions/params";

// Initialize Firebase Admin (single init — never call this again elsewhere)
admin.initializeApp();

// Define secrets at the top
const AGORA_APP_ID = defineSecret("AGORA_APP_ID");
const AGORA_APP_CERTIFICATE = defineSecret("AGORA_APP_CERTIFICATE");

// ─────────────────────────────────────────────────────────────────────────────
// generateAgoraToken — called from Flutter via FirebaseFunctions.httpsCallable
// Input:  { roomId: string, userId: string }
// Output: { token, uid, appId, channelName, role, expiresAt }
// ─────────────────────────────────────────────────────────────────────────────
export const generateAgoraToken = onCall(
  {
    region: "us-central1",
    cors: true,
    secrets: [AGORA_APP_ID, AGORA_APP_CERTIFICATE],
  },
  async (request) => {
    const callerUid = request.auth?.uid;

    // ── 1. Auth check ──────────────────────────────────────────────────────
    if (!callerUid) {
      logger.error("generateAgoraToken: unauthenticated call");
      throw new HttpsError("unauthenticated", "Authentication required.");
    }

    const { roomId, userId } = request.data as { roomId?: string; userId?: string };

    logger.info("generateAgoraToken: request received", {
      callerUid,
      roomId: roomId ?? "MISSING",
      userId: userId ?? "MISSING",
    });

    // ── 2. Input validation ────────────────────────────────────────────────
    if (!roomId || typeof roomId !== "string" || roomId.trim() === "") {
      throw new HttpsError(
        "invalid-argument",
        "roomId is required and must be a non-empty string.",
      );
    }
    if (!userId || typeof userId !== "string" || userId.trim() === "") {
      throw new HttpsError(
        "invalid-argument",
        "userId is required and must be a non-empty string.",
      );
    }

    // ── 3. Enforce caller == userId (prevent token theft) ─────────────────
    if (callerUid !== userId) {
      logger.error("generateAgoraToken: auth mismatch — REJECTED", {
        callerUid,
        requestedUserId: userId,
        roomId,
      });
      throw new HttpsError("permission-denied", "Cannot generate a token for a different user.");
    }

    // ── 4. Agora credentials ───────────────────────────────────────────────
    const appId = AGORA_APP_ID.value();
    const appCertificate = AGORA_APP_CERTIFICATE.value();
    if (!appId || !appCertificate) {
      logger.error("generateAgoraToken: AGORA secrets not set");
      throw new HttpsError("internal", "Server configuration error: Agora secrets missing.");
    }

    if (!appId || appId.trim() === "") {
      logger.error("generateAgoraToken: AGORA_APP_ID is not set in environment");
      throw new HttpsError("internal", "Server configuration error: Agora App ID is missing.");
    }
    if (!appCertificate || appCertificate.trim() === "") {
      logger.error("generateAgoraToken: AGORA_APP_CERTIFICATE is not set in environment");
      throw new HttpsError(
        "internal",
        "Server configuration error: Agora App Certificate is missing.",
      );
    }

    // ── 5. Firestore room lookup ───────────────────────────────────────────
    let roomData: FirebaseFirestore.DocumentData;
    try {
      const roomSnap = await admin.firestore().collection("rooms").doc(roomId).get();
      if (!roomSnap.exists) {
        logger.warn(`generateAgoraToken: room '${roomId}' not found`);
        throw new HttpsError("not-found", `Room '${roomId}' does not exist.`);
      }
      roomData = roomSnap.data()!;
    } catch (err) {
      // Re-throw HttpsErrors; wrap Firestore errors
      if (err instanceof HttpsError) throw err;
      logger.error("generateAgoraToken: Firestore read failed", { err, roomId });
      throw new HttpsError("internal", "Failed to read room data from Firestore.");
    }

    // ── 6. Room-level access guards ────────────────────────────────────────
    const isLive: boolean = roomData["isLive"] === true;
    const status: string = roomData["status"] ?? "";
    const bannedUsers: string[] = roomData["bannedUsers"] ?? [];
    const kickedUsers: string[] = roomData["kickedUsers"] ?? [];
    const hostId: string = roomData["hostId"] ?? "";
    const moderators: string[] = roomData["moderators"] ?? roomData["admins"] ?? [];
    const speakers: string[] = roomData["speakers"] ?? [];
    const isPrivate: boolean = roomData["privacy"] === "private" || roomData["isPrivate"] === true;

    if (!isLive || status === "ended") {
      throw new HttpsError("failed-precondition", "Room has ended or is no longer live.");
    }
    if (bannedUsers.includes(userId)) {
      throw new HttpsError("permission-denied", "You have been banned from this room.");
    }
    if (kickedUsers.includes(userId)) {
      throw new HttpsError("permission-denied", "You were removed from this room.");
    }
    if (isPrivate && hostId !== userId && !moderators.includes(userId)) {
      // Check participant sub-collection
      const partSnap = await admin
        .firestore()
        .collection("rooms")
        .doc(roomId)
        .collection("participants")
        .doc(userId)
        .get();
      if (!partSnap.exists) {
        throw new HttpsError("permission-denied", "Access denied: this is a private room.");
      }
    }

    // ── 7. Determine role ──────────────────────────────────────────────────
    const isBroadcaster =
      userId === hostId || moderators.includes(userId) || speakers.includes(userId);
    const agoraRole = isBroadcaster ? RtcRole.PUBLISHER : RtcRole.SUBSCRIBER;

    // ── 8. Derive stable numeric Agora UID from Firebase UID ───────────────
    const uid = Math.abs(_hashToUid(userId)) % 100_000;

    // ── 9. Build token — use RELATIVE seconds, NOT absolute epoch ──────────
    //  agora-token v2: tokenExpire and privilegeExpire are seconds from NOW
    const TOKEN_EXPIRE_SECS = 86_400; // 24 hours

    logger.info("generateAgoraToken: building token", {
      callerUid,
      roomId,
      uid,
      role: isBroadcaster ? "PUBLISHER" : "SUBSCRIBER",
      tokenExpireSecs: TOKEN_EXPIRE_SECS,
      appIdSet: true,
    });

    let token: string;
    try {
      token = RtcTokenBuilder.buildTokenWithUid(
        appId,
        appCertificate,
        roomId, // channelName
        uid, // numeric Agora UID
        agoraRole,
        TOKEN_EXPIRE_SECS, // tokenExpire  — relative seconds ✅
        TOKEN_EXPIRE_SECS, // privilegeExpire — relative seconds ✅
      );
    } catch (err) {
      logger.error("generateAgoraToken: RtcTokenBuilder failed", { err });
      throw new HttpsError("internal", "Token generation failed — check Agora credentials.");
    }

    if (!token || token.trim() === "") {
      logger.error("generateAgoraToken: builder returned empty token");
      throw new HttpsError("internal", "Token generation produced an empty result.");
    }

    const expiresAtMs = (Math.floor(Date.now() / 1000) + TOKEN_EXPIRE_SECS) * 1000;

    logger.info("generateAgoraToken: ✅ token issued", {
      callerUid,
      roomId,
      uid,
      role: isBroadcaster ? "broadcaster" : "audience",
      expiresAt: new Date(expiresAtMs).toISOString(),
    });

    return {
      token,
      uid,
      appId,
      channelName: roomId,
      role: isBroadcaster ? "broadcaster" : "audience",
      expiresAt: expiresAtMs,
    };
  },
);

/** Deterministic hash of a Firebase UID string → 32-bit signed integer */
function _hashToUid(str: string): number {
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    hash = (Math.imul(31, hash) + str.charCodeAt(i)) | 0;
  }
  return hash;
}

// Export match functions
export { generateUserMatches, handleLike, handlePass, refreshDailyMatches } from "./matches";

// Export speed dating functions (Phase 1 hardened)
export {
  matchSpeedDating,
  generateSpeedDatingAgoraToken,
  submitSpeedDatingDecision,
  endSpeedDatingSession,
  leaveSpeedDatingSession,
  joinSpeedDatingQueue,
  leaveSpeedDatingQueue,
  autoExpireSpeedDatingSessions,
} from "./speedDatingComplete";

// ─────────────────────────────────────────────────────────────────────────────
// ROOM CLEANUP — runs every hour, marks stale live rooms as 'ended'
// ─────────────────────────────────────────────────────────────────────────────

/**
 * Mark any room that has been "live" for more than 6 hours (with no update in
 * the last 30 min) as ended.  This prevents orphan rooms from clogging the
 * discovery feed when a host disconnects without properly closing the room.
 */
export const cleanupStaleRooms = onSchedule(
  {
    schedule: "every 60 minutes",
    region: "us-central1",
    timeoutSeconds: 120,
  },
  async () => {
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();

    // Rooms live > 6 hours
    const staleCutoff = admin.firestore.Timestamp.fromMillis(now.toMillis() - 6 * 60 * 60 * 1000);
    // Rooms not updated in > 30 minutes
    const inactiveCutoff = admin.firestore.Timestamp.fromMillis(now.toMillis() - 30 * 60 * 1000);

    const snapshot = await db
      .collection("rooms")
      .where("isLive", "==", true)
      .where("createdAt", "<", staleCutoff)
      .limit(100)
      .get();

    if (snapshot.empty) {
      logger.info("cleanupStaleRooms: no stale rooms found");
      return;
    }

    const batch = db.batch();
    let count = 0;

    for (const doc of snapshot.docs) {
      const data = doc.data();
      const updatedAt = data.updatedAt as admin.firestore.Timestamp | undefined;

      // Skip recently active rooms
      if (updatedAt && updatedAt > inactiveCutoff) continue;

      batch.update(doc.ref, {
        isLive: false,
        status: "ended",
        endedAt: now,
        endReason: "auto_cleanup_stale",
        updatedAt: now,
      });
      count++;
    }

    if (count > 0) {
      await batch.commit();
      logger.info(`cleanupStaleRooms: ended ${count} stale room(s)`);
    } else {
      logger.info("cleanupStaleRooms: all live rooms are still active");
    }
  },
);
