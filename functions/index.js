const { onRequest } = require('firebase-functions/v2/https');
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
    try {
      const authHeader = req.headers.authorization;
      if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({ error: 'Unauthorized: Missing token' });
      }

      const idToken = authHeader.split('Bearer ')[1];
      let decodedToken;

      try {
        decodedToken = await admin.auth().verifyIdToken(idToken);
      } catch (error) {
        logger.error('Token verification failed:', error);
        return res.status(401).json({ error: 'Unauthorized: Invalid token' });
      }

      const userId = decodedToken.uid;

      const channelName = req.query.channelName || req.body?.channelName;
      const uid = parseInt(req.query.uid || req.body?.uid || 0);
      const role = req.query.role || req.body?.role || 'audience';

      if (!channelName) {
        return res.status(400).json({ error: 'channelName is required' });
      }

      const agoraAppId = process.env.AGORA_APP_ID;
      const agoraAppCert = process.env.AGORA_APP_CERTIFICATE;

      if (!agoraAppId || !agoraAppCert) {
        logger.error('Agora credentials not configured in environment');
        return res.status(500).json({
          error: 'Server configuration error',
          hint: 'Set AGORA_APP_ID and AGORA_APP_CERTIFICATE in functions/.env'
        });
      }

      const roomRef = admin.firestore().collection('rooms').doc(channelName);
      const roomDoc = await roomRef.get();

      if (!roomDoc.exists) {
        return res.status(404).json({ error: 'Room not found' });
      }

      const roomData = roomDoc.data();

      if (roomData.privacy === 'private' || roomData.isPrivate) {
        const participantRef = roomRef.collection('participants').doc(userId);
        const participantDoc = await participantRef.get();

        if (!participantDoc.exists && roomData.hostId !== userId) {
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
        token,
        appId: agoraAppId,
        channelName,
        uid,
        role: agoraRole,
        expiresAt: privilegeExpiredTs * 1000
      });

    } catch (error) {
      logger.error('Error generating Agora token:', error);
      return res.status(500).json({
        error: 'Internal server error',
        message: error?.message || 'Unknown error'
      });
    }
  });
});

// Import push notification functions
const pushNotifications = require('./push_notifications');

// Export notification functions
exports.sendPushNotification = pushNotifications.sendPushNotification;
exports.onNewMessage = pushNotifications.onNewMessage;
exports.onNewFollow = pushNotifications.onNewFollow;
exports.sendEventReminders = pushNotifications.sendEventReminders;
exports.cleanupOldNotifications = pushNotifications.cleanupOldNotifications;
