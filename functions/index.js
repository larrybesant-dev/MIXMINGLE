const { onRequest, onCall, HttpsError } = require('firebase-functions/v2/https');
const logger = require('firebase-functions/logger');
const admin = require('firebase-admin');
const { RtcTokenBuilder, RtcRole } = require('agora-token');
const cors = require('cors')({ origin: true });

admin.initializeApp();

/**
 * Generate Agora RTC Token for video/audio rooms
 *
 * Required query params:
 * - channelName: Room ID
 * - uid: User ID (numeric)
 * - role: 'broadcaster' or 'audience'
 *
 * Returns: { token: string, expiresAt: timestamp }
 */
exports.getAgoraToken = onRequest((req, res) => {
  return cors(req, res, async () => {
    res.set('Access-Control-Allow-Origin', '*');
    try {
      const authHeader = req.headers.authorization;
      if (!authHeader || !authHeader.startsWith('Bearer ')) {
        res.set('Access-Control-Allow-Origin', '*');
        return res.status(401).json({ error: 'Unauthorized: Missing token' });
      }

      const idToken = authHeader.split('Bearer ')[1];
      let decodedToken;

      try {
        decodedToken = await admin.auth().verifyIdToken(idToken);
      } catch (error) {
        logger.error('Token verification failed:', error);
        res.set('Access-Control-Allow-Origin', '*');
        return res.status(401).json({ error: 'Unauthorized: Invalid token' });
      }

      const userId = decodedToken.uid;

      const channelName = req.query.channelName || req.body?.channelName;
      const uid = parseInt(req.query.uid || req.body?.uid || 0);
      const role = req.query.role || req.body?.role || 'audience';

      if (!channelName) {
        res.set('Access-Control-Allow-Origin', '*');
        return res.status(400).json({ error: 'channelName is required' });
      }

      const agoraAppId = process.env.AGORA_APP_ID;
      const agoraAppCert = process.env.AGORA_APP_CERTIFICATE;

      if (!agoraAppId || !agoraAppCert) {
        logger.error('Agora credentials not configured in environment');
        res.set('Access-Control-Allow-Origin', '*');
        return res.status(500).json({
          error: 'Server configuration error',
          hint: 'Set AGORA_APP_ID and AGORA_APP_CERTIFICATE in functions/.env'
        });
      }

      const roomRef = admin.firestore().collection('rooms').doc(channelName);
      const roomDoc = await roomRef.get();

      if (!roomDoc.exists) {
        res.set('Access-Control-Allow-Origin', '*');
        return res.status(404).json({ error: 'Room not found' });
      }

      const roomData = roomDoc.data();

      if (roomData.privacy === 'private' || roomData.isPrivate) {
        const participantRef = roomRef.collection('participants').doc(userId);
        const participantDoc = await participantRef.get();

        if (!participantDoc.exists && roomData.hostId !== userId) {
          res.set('Access-Control-Allow-Origin', '*');
          return res.status(403).json({ error: 'Access denied: Private room' });
        }
      }

      const agoraRole = role === 'broadcaster' || role === 'host' || role === 'speaker'
        ? RtcRole.PUBLISHER
        : RtcRole.SUBSCRIBER;

      const expirationTimeInSeconds = 86400;
      const currentTimestamp = Math.floor(Date.now() / 1000);
      const privilegeExpiredTs = currentTimestamp + expirationTimeInSeconds;

      const token = RtcTokenBuilder.buildTokenWithUid(
        agoraAppId,
        agoraAppCert,
        channelName,
        uid,
        agoraRole,
        privilegeExpiredTs
      );

      logger.info('Token generated', {
        userId,
        channelName,
        uid,
        role: agoraRole === RtcRole.PUBLISHER ? 'PUBLISHER' : 'SUBSCRIBER',
        expiresAt: new Date(privilegeExpiredTs * 1000).toISOString()
      });

      return res.status(200).json({
        res.set('Access-Control-Allow-Origin', '*');
        return res.status(200).json({
          token,
          appId: agoraAppId,
          channelName,
          uid,
          role: agoraRole,
          expiresAt: privilegeExpiredTs * 1000
        });

    } catch (error) {
      logger.error('Error generating Agora token:', error);
      res.set('Access-Control-Allow-Origin', '*');
      return res.status(500).json({
        error: 'Internal server error',
        message: error?.message || 'Unknown error'
      });
    }
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// generateAgoraToken — callable version (used by Flutter via httpsCallable)
// Flutter passes: { roomId: string, userId: string }
// Returns:        { token: string, appId: string, uid: number }
// ─────────────────────────────────────────────────────────────────────────────
exports.generateAgoraToken = onCall(async (request) => {
  // Log invocation metadata only (do not log secrets or token values)
  try {
    console.log('generateAgoraToken callable invoked; auth present:', !!request.auth);
    const data = request.data || {};
    console.log('generateAgoraToken received keys:', Object.keys(data));

    const { roomId, userId } = data || {};
    if (!roomId || !userId) {
      console.warn('generateAgoraToken missing parameters:', { roomId: !!roomId, userId: !!userId });
      // Use HttpsError so client receives a structured error
      throw new functions.https.HttpsError('invalid-argument', 'Missing required parameters: roomId and userId');
    }

    // --- Place your existing Agora token generation logic below ---
    // Example placeholder: replace with your real implementation that uses secrets safely
    // const token = await createAgoraToken({ roomId, userId });
    const token = `token_${roomId}_${userId}_${Date.now()}`; // local/test placeholder
    // --- End placeholder ---

    return { token };
  } catch (err) {
    // If it's already an HttpsError, rethrow so Firebase returns the proper code/message
    if (err instanceof functions.https.HttpsError) throw err;
    console.error('generateAgoraToken unexpected error:', err);
    throw new functions.https.HttpsError('internal', 'Internal server error');
  }
});

/** Deterministic hash of a Firebase UID string → 32-bit signed integer */
function _hashToUid(str) {
  let hash = 0;
  for (let i = 0; i < str.length; i++) {
    hash = Math.imul(31, hash) + str.charCodeAt(i) | 0;
  }
  return hash;
}

// Import push notification functions
const pushNotifications = require('./push_notifications');

// Export notification functions
exports.sendPushNotification = pushNotifications.sendPushNotification;
exports.onNewMessage = pushNotifications.onNewMessage;
exports.onNewFollow = pushNotifications.onNewFollow;
exports.sendEventReminders = pushNotifications.sendEventReminders;
exports.cleanupOldNotifications = pushNotifications.cleanupOldNotifications;

// ─────────────────────────────────────────────────────────────────────────────
// #10  BEHAVIOR TAG INTELLIGENCE
// ─────────────────────────────────────────────────────────────────────────────
const { onSchedule } = require('firebase-functions/v2/scheduler');
const { onDocumentWritten } = require('firebase-functions/v2/firestore');

/**
 * computeBehaviorTags  — runs nightly at 03:00 UTC
 * Reads every user doc, recomputes behavior tags from activity metrics and
 * writes them back to users/{uid}.computedTags.
 *
 * Tag rules (mirror of VibeIntelligenceService.computeBehaviorTags in Dart):
 *   roomsHostedCount >= 10  → "Super Host"
 *   totalRoomsJoined >= 30  → "Social Butterfly"
 *   eventsAttended >= 5     → "Event Junkie"
 *   communityRating >= 4.5  → "Top Rated"
 *   vibeHistory contains 3+ joins in "Late Night" → "Night Owl"
 */
exports.computeBehaviorTags = onSchedule('every 24 hours', async (_event) => {
  const db = admin.firestore();
  const usersSnap = await db.collection('users').get();

  const batch = db.batch();
  let updateCount = 0;

  for (const doc of usersSnap.docs) {
    const d = doc.data();
    const tags = [];

    if ((d.roomsHostedCount || 0) >= 10)          tags.push('Super Host');
    if ((d.totalRoomsJoined || 0) >= 30)           tags.push('Social Butterfly');
    if ((d.eventsAttended || 0) >= 5)              tags.push('Event Junkie');
    if ((d.communityRating || 0) >= 4.5)           tags.push('Top Rated');
    const lateNight = ((d.vibeHistory || {})['Late Night'] || 0);
    if (lateNight >= 3)                            tags.push('Night Owl');

    // Only write if tags changed to avoid unnecessary writes
    const existing = (d.computedTags || []).slice().sort().join(',');
    if (existing !== tags.slice().sort().join(',')) {
      batch.update(doc.ref, { computedTags: tags });
      updateCount++;
    }

    // Commit in chunks of 400 to stay under Firestore batch limit
    if (updateCount > 0 && updateCount % 400 === 0) {
      await batch.commit();
    }
  }

  await batch.commit();
  logger.info(`computeBehaviorTags: updated ${updateCount} users`);
});

/**
 * updateJoinVelocity — runs every 5 minutes
 * For each live room, counts how many new participant joins happened in the
 * last 5 minutes (by inspecting Firestore timestamp metadata) and writes
 * the result back as rooms/{roomId}.joinVelocity.
 *
 * Lightweight: only scans rooms where isLive == true.
 */
exports.updateJoinVelocity = onSchedule('every 5 minutes', async (_event) => {
  const db = admin.firestore();
  const now = Date.now();
  const windowMs = 5 * 60 * 1000; // 5 minutes

  const liveRooms = await db.collection('rooms').where('isLive', '==', true).get();

  const roomUpdates = liveRooms.docs.map(async (roomDoc) => {
    const data = roomDoc.data();
    const joinTimestamps = data.recentJoins || []; // array of server millis

    // Separate fresh joins (within window) from stale ones
    const freshJoins = joinTimestamps.filter((t) => now - t < windowMs);
    const velocity   = freshJoins.length;

    const fields = {};
    if (velocity !== (data.joinVelocity || 0)) fields.joinVelocity = velocity;

    // TTL cleanup: prune stale entries to prevent unbounded array growth
    if (freshJoins.length < joinTimestamps.length) fields.recentJoins = freshJoins;

    if (Object.keys(fields).length > 0) {
      await roomDoc.ref.update(fields);
    }
  });

  await Promise.all(roomUpdates);
  logger.info(`updateJoinVelocity: processed ${liveRooms.size} live rooms`);
});

/**
 * onRoomMemberJoin — Firestore trigger on rooms/{roomId}
 * When a room document's participantIds array changes (new member joined),
 * records the join timestamp in recentJoins and increments the user's
 * vibeHistory for the room's vibeTag.
 */
exports.onRoomMemberJoin = onDocumentWritten('rooms/{roomId}', async (event) => {
  const before = event.data?.before?.data() || {};
  const after  = event.data?.after?.data()  || {};

  const prevIds = before.participantIds || [];
  const currIds = after.participantIds   || [];

  // Find newly added participants
  const newJoins = currIds.filter((id) => !prevIds.includes(id));
  if (newJoins.length === 0) return;

  const db = admin.firestore();
  const vibeTag = after.vibeTag;
  const now = admin.firestore.FieldValue.serverTimestamp();
  const nowMs = Date.now();

  const tasks = [];

  // Append join timestamp for velocity tracking
  tasks.push(
    event.data.after.ref.update({
      recentJoins: admin.firestore.FieldValue.arrayUnion(nowMs),
    })
  );

  // Increment vibeHistory for each new joiner
  if (vibeTag) {
    for (const userId of newJoins) {
      const userRef = db.collection('users').doc(userId);
      tasks.push(
        userRef.update({
          [`vibeHistory.${vibeTag}`]: admin.firestore.FieldValue.increment(1),
          lastRoomJoinedAt: now,
        })
      );
    }
  }

  await Promise.all(tasks);
  logger.info(`onRoomMemberJoin: ${newJoins.length} new joins in room ${event.params.roomId}`);
});
