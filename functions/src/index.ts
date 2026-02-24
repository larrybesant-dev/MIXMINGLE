import { onCall } from "firebase-functions/v2/https";
import { onSchedule } from "firebase-functions/v2/scheduler";
import * as logger from "firebase-functions/logger";
import { RtcTokenBuilder, RtcRole } from "agora-token";
import * as admin from "firebase-admin";

// Initialize Firebase Admin
admin.initializeApp();

// Generate Agora RTC token for video chat
export const generateAgoraToken = onCall(
  {
    region: "us-central1",
    cors: true
  },
  async (request) => {
    try {
      // Log auth context for debugging
      logger.debug('Callable request verification passed');
      logger.debug(`Auth context - UID: ${request.auth?.uid || 'NONE'}, Token: ${request.auth?.token ? 'PRESENT' : 'MISSING'}`);

      const { roomId, userId } = request.data;
      logger.debug(`Request data - roomId: ${roomId}, userId: ${userId}`);

      if (!roomId || !userId) {
        throw new Error("Missing required parameters: roomId and userId");
      }

      // Verify authenticated user matches requested userId
      if (request.auth?.uid && request.auth.uid !== userId) {
        logger.warn(`Auth mismatch: request.auth.uid=${request.auth.uid} but data.userId=${userId}`);
        // For now, just warn - don't enforce to maintain compatibility
      }

      // Ensure user is authenticated via Firebase callable auth
      if (!request.auth?.uid) {
        logger.error('Request missing auth context - user not authenticated via Firebase SDK');
        throw new Error('Authentication required. Please ensure you are signed in.');
      }

      // Load room metadata for enforcement
      const roomSnap = await admin.firestore().collection('rooms').doc(roomId).get();
      if (!roomSnap.exists) {
        throw new Error('Room not found');
      }

      const roomData = roomSnap.data() || {};
      const isLive = roomData.isLive === true;
      const status = roomData.status as string | undefined;
      const bannedUsers: string[] = roomData.bannedUsers ?? [];
      const kickedUsers: string[] = roomData.kickedUsers ?? [];
      const hostId: string | undefined = roomData.hostId;
      const moderators: string[] = roomData.moderators ?? roomData.admins ?? [];
      const speakers: string[] = roomData.speakers ?? [];

      if (!isLive || status === 'ended') {
        throw new Error('Room has ended');
      }

      if (bannedUsers.includes(userId)) {
        throw new Error('User is banned from this room');
      }

      if (kickedUsers.includes(userId)) {
        throw new Error('User was removed from this room');
      }

      // Get Agora credentials from environment variables
      const appId = process.env.AGORA_APP_ID;
      const appCertificate = process.env.AGORA_APP_CERTIFICATE;

      if (!appId || !appCertificate) {
        logger.error(`Agora credentials missing: appId=${!!appId}, certificate=${!!appCertificate}`);
        throw new Error(`Agora credentials not configured. AppID: ${appId ? 'SET' : 'MISSING'}, Certificate: ${appCertificate ? 'SET' : 'MISSING'}`);
      }

      // Generate UID from userId (convert string to number)
      const uid = Math.abs(hashCode(userId));

      // Token expires in 24 hours
      const expirationTimeInSeconds = 86400;
      const currentTimestamp = Math.floor(Date.now() / 1000);
      const privilegeExpiredTs = currentTimestamp + expirationTimeInSeconds;

      // Determine role: host/mod/speaker = publisher; others = audience
      const isBroadcaster = userId === hostId || moderators.includes(userId) || speakers.includes(userId);
      const agoraRole = isBroadcaster ? RtcRole.PUBLISHER : RtcRole.SUBSCRIBER;

      // Build token with role
      const token = RtcTokenBuilder.buildTokenWithUid(
        appId,
        appCertificate,
        roomId,
        uid,
        agoraRole,
        privilegeExpiredTs,
        privilegeExpiredTs
      );

      logger.info(`✅ Generated Agora token for user ${userId} in room ${roomId}`);

      return {
        token,
        uid,
        appId,
        channelName: roomId,
        role: isBroadcaster ? 'broadcaster' : 'audience',
        expiresAt: privilegeExpiredTs * 1000,
      };
    } catch (error) {
      logger.error('❌ Error generating Agora token:', error);
      throw new Error(`Failed to generate Agora token: ${error instanceof Error ? error.message : String(error)}`);
    }
  }
);

/**
 * Simple hash function to convert string to number
 */
function hashCode(str: string): number {
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    const char = str.charCodeAt(i);
    hash = ((hash << 5) - hash) + char;
    hash = hash & hash; // Convert to 32bit integer
  }
  return hash;
}

// Export match functions
export { generateUserMatches, handleLike, handlePass, refreshDailyMatches } from './matches';

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
    const staleCutoff = admin.firestore.Timestamp.fromMillis(
      now.toMillis() - 6 * 60 * 60 * 1000
    );
    // Rooms not updated in > 30 minutes
    const inactiveCutoff = admin.firestore.Timestamp.fromMillis(
      now.toMillis() - 30 * 60 * 1000
    );

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
  }
);
