import * as functions from 'firebase-functions/v2';
import { defineSecret } from 'firebase-functions/params';
import * as admin from 'firebase-admin';

const agoraAppId = defineSecret("AGORA_APP_ID");
const agoraAppCertificate = defineSecret("AGORA_APP_CERTIFICATE");

// One-time setup function to initialize Agora config
export const initializeAgoraConfig = functions.https.onRequest(
  { secrets: [agoraAppId, agoraAppCertificate] },
  async (req, res) => {
    try {
      const db = admin.firestore();
      const appId = agoraAppId.value();
      const appCertificate = agoraAppCertificate.value();

      await db.collection('config').doc('agora').set({
        appId: appId,
        appCertificate: appCertificate,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedBy: 'initializeAgoraConfig',
      }, { merge: true });

      res.status(200).json({
        success: true,
        message: 'Agora config initialized',
      });
    } catch (error) {
      functions.logger.error('Failed to initialize Agora config', error);
      res.status(500).json({
        success: false,
        message: 'Failed to initialize Agora config',
        error: error instanceof Error ? error.message : String(error),
      });
    }
  }
);
