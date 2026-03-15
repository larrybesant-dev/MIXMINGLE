import { onCall, HttpsError } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { defineSecret } from "firebase-functions/params";
import * as logger from "firebase-functions/logger";
import { RtcTokenBuilder, RtcRole } from "agora-token";
import * as admin from "firebase-admin";
import { defineSecret } from "firebase-functions/params";


// ─────────────────────────────────────────────────────────────────────────────
// generateAgoraToken — called from Flutter via FirebaseFunctions.httpsCallable
// Input:  { roomId: string, userId: string }
// Output: { token, uid, appId, channelName, role, expiresAt }
// ─────────────────────────────────────────────────────────────────────────────
export const generateAgoraToken = onCall(
  {
    region: "us-central1",
    cors: true,
<<<<<<< HEAD
    secrets: [agoraAppIdSecret, agoraAppCertSecret],
=======
    secrets: [AGORA_APP_ID, AGORA_APP_CERTIFICATE],
>>>>>>> origin/develop
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
<<<<<<< HEAD
      // Log auth context for debugging
      logger.debug('Callable request verification passed');
      logger.debug(`Auth context - UID: ${request.auth?.uid || 'NONE'}, Token: ${request.auth?.token ? 'PRESENT' : 'MISSING'}`);

      const requestData = (request.data ?? {}) as Record<string, unknown>;

      // Support both callable payload shapes used in this codebase.
      const roomIdRaw = requestData.roomId ?? requestData.channelName;
      const userIdRaw = requestData.userId ?? requestData.uid ?? request.auth?.uid;

      const roomId = typeof roomIdRaw === "string" ? roomIdRaw.trim() : "";
      const userId = typeof userIdRaw === "string"
        ? userIdRaw.trim()
        : typeof userIdRaw === "number"
          ? String(userIdRaw)
          : "";

      logger.debug(`Request data - roomId: ${roomId}, userId: ${userId}`);

      if (!roomId || !userId) {
        throw new HttpsError("invalid-argument", "Missing required parameters: roomId/channelName and userId/uid");
      }

      // Enforce authenticated user matches requested userId.
      if (request.auth?.uid && request.auth.uid !== userId) {
        logger.warn(`Auth mismatch: request.auth.uid=${request.auth.uid} but data.userId=${userId}`);
        throw new HttpsError("permission-denied", "Cannot generate a token for another user");
      }

      // Ensure user is authenticated via Firebase callable auth
      if (!request.auth?.uid) {
        logger.error('Request missing auth context - user not authenticated via Firebase SDK');
        throw new HttpsError('unauthenticated', 'Authentication required. Please ensure you are signed in.');
      }

      // Load room metadata for enforcement
      const roomSnap = await admin.firestore().collection('rooms').doc(roomId).get();
      if (!roomSnap.exists) {
        throw new HttpsError('not-found', 'Room not found');
=======
      const roomSnap = await admin.firestore().collection("rooms").doc(roomId).get();
      if (!roomSnap.exists) {
        logger.warn(`generateAgoraToken: room '${roomId}' not found`);
        throw new HttpsError("not-found", `Room '${roomId}' does not exist.`);
>>>>>>> origin/develop
      }
      roomData = roomSnap.data()!;
    } catch (err) {
      // Re-throw HttpsErrors; wrap Firestore errors
      if (err instanceof HttpsError) throw err;
      logger.error("generateAgoraToken: Firestore read failed", { err, roomId });
      throw new HttpsError("internal", "Failed to read room data from Firestore.");
    }

<<<<<<< HEAD
      const roomData = roomSnap.data() || {};
      const isLive = roomData.isLive === true;
      const isActive = roomData.isActive !== false;
      const videoChannelLive = roomData.videoChannelLive === true;
      const status = roomData.status as string | undefined;
      const bannedUsers: string[] = roomData.bannedUsers ?? [];
      const kickedUsers: string[] = roomData.kickedUsers ?? [];
      const hostId: string | undefined = roomData.hostId;
      const moderators: string[] = roomData.moderators ?? roomData.admins ?? [];
      const speakers: string[] = roomData.speakers ?? [];

      const roomEnded =
        status === 'ended' ||
        status === 'closed' ||
        (isLive === false && isActive === false && videoChannelLive === false);

      if (roomEnded) {
        throw new HttpsError('failed-precondition', 'Room has ended');
=======
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
>>>>>>> origin/develop
      }
    }

<<<<<<< HEAD
      if (bannedUsers.includes(userId)) {
        throw new HttpsError('permission-denied', 'User is banned from this room');
      }

      if (kickedUsers.includes(userId)) {
        throw new HttpsError('permission-denied', 'User was removed from this room');
      }

      // Get Agora credentials from environment variables
      const appId = agoraAppIdSecret.value() || process.env.AGORA_APP_ID;
      const appCertificate =
        agoraAppCertSecret.value() || process.env.AGORA_APP_CERTIFICATE;

      const looksLikePlaceholder =
        appId === 'your-agora-app-id' ||
        appCertificate === 'your-agora-app-certificate';

      if (!appId || !appCertificate) {
        logger.error(`Agora credentials missing: appId=${!!appId}, certificate=${!!appCertificate}`);
        throw new HttpsError(
          'failed-precondition',
          `Agora credentials not configured. AppID: ${appId ? 'SET' : 'MISSING'}, Certificate: ${appCertificate ? 'SET' : 'MISSING'}`
        );
      }

      if (looksLikePlaceholder) {
        logger.error('Agora credentials are placeholders and must be replaced with real secret values');
        throw new HttpsError(
          'failed-precondition',
          'Agora credentials are placeholders. Configure AGORA_APP_ID and AGORA_APP_CERTIFICATE secrets.'
        );
      }
=======
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
>>>>>>> origin/develop

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
<<<<<<< HEAD

      const normalizedToken = typeof token === 'string' ? token.trim() : '';
      if (!normalizedToken) {
        logger.error('Agora SDK returned an empty token', {
          roomId,
          userId,
          uid,
          role: isBroadcaster ? 'broadcaster' : 'audience',
        });
        throw new HttpsError('internal', 'Agora token generation returned an empty token');
      }

      logger.info(`✅ Generated Agora token for user ${userId} in room ${roomId}`);
      console.log('Token generated for channel:', roomId);

      return {
        token: normalizedToken,
        uid,
        appId,
        channelName: roomId,
        role: isBroadcaster ? 'broadcaster' : 'audience',
        expiresAt: privilegeExpiredTs * 1000,
      };
    } catch (error) {
      logger.error('❌ Error generating Agora token:', error);

      if (error instanceof HttpsError) {
        throw error;
      }

      throw new HttpsError(
        'internal',
        `Failed to generate Agora token: ${error instanceof Error ? error.message : String(error)}`
      );
=======
    } catch (err) {
      logger.error("generateAgoraToken: RtcTokenBuilder failed", { err });
      throw new HttpsError("internal", "Token generation failed — check Agora credentials.");
>>>>>>> origin/develop
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
<<<<<<< HEAD
export { generateUserMatches, handleLike, handlePass, refreshDailyMatches } from './matches';
export { checkRateLimit } from './rateLimit';
export { storiesCleanup } from './storiesCleanup';
=======
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
>>>>>>> origin/develop

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
        viewerCount: 0,
        participantCount: 0,
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

// ROLE GOVERNANCE — set Firebase Custom Claims + Firestore role
// ─────────────────────────────────────────────────────────────────────────────
export { setUserRole } from "./setUserRole";

// SPEED DATING — queue management, automatic matching, session lifecycle
// ─────────────────────────────────────────────────────────────────────────────
export {
  matchSpeedDating,
  generateSpeedDatingToken,
  submitSpeedDatingDecision,
  endSpeedDatingSession,
  leaveSpeedDatingSession,
  joinSpeedDatingQueue,
  leaveSpeedDatingQueue,
  autoExpireSpeedDatingSessions,
} from "./speedDatingComplete";
