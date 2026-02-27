// Cloud Function for managing broadcaster recording via Agora REST API
// File: functions/src/broadcasters.ts

import * as functions from "firebase-functions";
import { defineSecret } from "firebase-functions/params";
import * as admin from "firebase-admin";
import axios from "axios";

// Define secrets
const agoraAppId = defineSecret("AGORA_APP_ID");
const agoraApiKey = defineSecret("AGORA_API_KEY");
const agoraApiSecret = defineSecret("AGORA_API_SECRET");
const awsAccessKey = defineSecret("AWS_ACCESS_KEY");
const awsSecretKey = defineSecret("AWS_SECRET_KEY");

const db = admin.firestore();

interface AgoraRecordingRequest {
  cname: string;
  uid: number;
  clientRequest: {
    recordingFileFormat: Array<{
      fileFormat: string;
    }>;
    recordingConfig: {
      maxIdleTime: number;
      streamTypes: number;
      audioProfile: number;
      channelProfile: number;
      videoStreamType: number;
      decryptionMode: string;
    };
    storageConfig: {
      vendor: number;
      region: number;
      bucket: string;
      accessKey: string;
      secretKey: string;
      fileNamePrefix: string[];
    };
  };
}

/**
 * Start recording a broadcast when user switches to broadcaster role
 * Called when user starts broadcasting
 */
export const onBroadcasterApproved = functions.firestore
  .document("rooms/{roomId}/broadcasterQueue/{userId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const { roomId, userId } = context.params;

    // Only act when status changes to 'broadcasting'
    if (before?.status !== "broadcasting" && after?.status === "broadcasting") {
      try {
        await startRecording(roomId, userId, after);
      } catch (error) {
        console.error(`Failed to start recording for ${userId}:`, error);
      }
    }

    // Only act when status changes from 'broadcasting' to other states
    if (before?.status === "broadcasting" && after?.status !== "broadcasting") {
      try {
        await stopRecording(roomId, userId, before);
      } catch (error) {
        console.error(`Failed to stop recording for ${userId}:`, error);
      }
    }
  });

/**
 * Start recording via Agora REST API (Composite Recording)
 * Records the entire room view as if it's being watched by a viewer
 */
async function startRecording(roomId: string, userId: string, broadcasterData: any) {
  const AGORA_APP_ID = agoraAppId.value();
  const AGORA_API_KEY = agoraApiKey.value();
  const AGORA_API_SECRET = agoraApiSecret.value();

  if (!AGORA_APP_ID || !AGORA_API_KEY || !AGORA_API_SECRET) {
    throw new Error("Agora credentials not configured");
  }

  // Get room data
  const roomDoc = await db.collection("rooms").doc(roomId).get();
  const roomData = roomDoc.data();
  if (!roomData) throw new Error("Room not found");

  // Get user profile for file naming
  const userDoc = await db.collection("users").doc(userId).get();
  const userData = userDoc.data();
  const userName = userData?.displayName || "User";

  // Generate unique recording ID
  const recordingId = `${roomId}-${userId}-${Date.now()}`;

  // Prepare recording request
  const recordingRequest: AgoraRecordingRequest = {
    cname: roomId,
    uid: 0, // Use uid 0 for composite recording
    clientRequest: {
      recordingFileFormat: [
        {
          fileFormat: "m3u8", // Or "mp4"
        },
      ],
      recordingConfig: {
        maxIdleTime: 300, // Stop if idle for 5 minutes
        streamTypes: 2, // Both audio and video
        audioProfile: 1, // High quality audio
        channelProfile: 1, // Live broadcasting profile
        videoStreamType: 0, // All video streams
        decryptionMode: "none",
      },
      storageConfig: {
        vendor: 1, // AWS S3
        region: 0, // US East
        bucket: "agora-recordings",
        accessKey: awsAccessKey.value(),
        secretKey: awsSecretKey.value(),
        fileNamePrefix: [`${roomId}/${userName}/${recordingId}`],
      },
    },
  };

  try {
    // Get Agora token for recording
    const token = await getAgoraRecordingToken(
      AGORA_APP_ID,
      AGORA_API_KEY,
      AGORA_API_SECRET,
      roomId,
    );

    // Start recording via REST API
    const response = await axios.post(
      `https://api.agora.io/v1/apps/${AGORA_APP_ID}/recordings`,
      recordingRequest,
      {
        auth: {
          username: AGORA_API_KEY,
          password: AGORA_API_SECRET,
        },
        headers: {
          "Content-Type": "application/json",
        },
      },
    );

    const recordingDetails = response.data;

    // Save recording metadata
    await db.collection("rooms").doc(roomId).collection("broadcasterQueue").doc(userId).update({
      isRecording: true,
      recordingStartedAt: admin.firestore.FieldValue.serverTimestamp(),
      recordingId: recordingDetails.resourceId,
      recordingSessionId: recordingDetails.sid,
    });

    console.log(`✅ Recording started: ${recordingId}`);
  } catch (error) {
    console.error("Failed to start recording:", error);
    throw error;
  }
}

/**
 * Stop recording via Agora REST API
 */
async function stopRecording(roomId: string, userId: string, broadcasterData: any) {
  const AGORA_APP_ID = agoraAppId.value();
  const AGORA_API_KEY = agoraApiKey.value();
  const AGORA_API_SECRET = agoraApiSecret.value();

  if (!AGORA_APP_ID || !AGORA_API_KEY || !AGORA_API_SECRET) {
    throw new Error("Agora credentials not configured");
  }

  const resourceId = broadcasterData.recordingId;
  const sid = broadcasterData.recordingSessionId;

  if (!resourceId || !sid) {
    console.warn(`No recording details found for ${userId}, skipping stop recording`);
    return;
  }

  try {
    // Stop recording via REST API
    await axios.post(
      `https://api.agora.io/v1/apps/${AGORA_APP_ID}/recordings/${resourceId}/sid/${sid}/stop`,
      {
        cname: roomId,
        uid: 0,
        clientRequest: {},
      },
      {
        auth: {
          username: AGORA_API_KEY,
          password: AGORA_API_SECRET,
        },
      },
    );

    // Update recording status
    await db.collection("rooms").doc(roomId).collection("broadcasterQueue").doc(userId).update({
      isRecording: false,
      recordingEndedAt: admin.firestore.FieldValue.serverTimestamp(),
      recordingStatus: "completed",
    });

    console.log(`✅ Recording stopped for ${userId}`);
  } catch (error) {
    console.error("Failed to stop recording:", error);
    throw error;
  }
}

/**
 * Generate Agora recording token
 */
async function getAgoraRecordingToken(
  appId: string,
  apiKey: string,
  apiSecret: string,
  channelName: string,
): Promise<string> {
  // In production, use the @agora-community/token-server package
  // For now, return placeholder - implement with real token generation
  return "token_placeholder";
}

/**
 * Auto-approve next broadcaster in queue when one goes offline
 */
export const onBroadcasterOffline = functions.firestore
  .document("rooms/{roomId}/broadcasterQueue/{userId}")
  .onDelete(async (snap, context) => {
    const { roomId } = context.params;

    try {
      // Get next pending broadcaster
      const queueSnapshot = await db
        .collection("rooms")
        .doc(roomId)
        .collection("broadcasterQueue")
        .where("status", "==", "pending")
        .orderBy("requestedAt", "asc")
        .limit(1)
        .get();

      if (queueSnapshot.empty) {
        console.log(`No pending broadcasters for room ${roomId}`);
        return;
      }

      const nextBroadcaster = queueSnapshot.docs[0];

      // Auto-approve
      await nextBroadcaster.ref.update({
        status: "approved",
        approvedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`✅ Auto-approved: ${nextBroadcaster.data().userName}`);

      // Send notification to approved user
      const userData = await db.collection("users").doc(nextBroadcaster.id).get();

      // TODO: Send push notification or update user's notification feed
      console.log(`Notification sent to ${userData.data()?.displayName}`);
    } catch (error) {
      console.error("Failed to auto-approve next broadcaster:", error);
    }
  });

/**
 * Cleanup completed broadcasts after 30 days
 */
export const cleanupOldBroadcasts = functions.pubsub
  .schedule("every day 02:00")
  .timeZone("UTC")
  .onRun(async () => {
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    try {
      const roomsSnapshot = await db.collection("rooms").get();

      for (const roomDoc of roomsSnapshot.docs) {
        const queueSnapshot = await roomDoc.ref
          .collection("broadcasterQueue")
          .where("broadcastEndedAt", "<", thirtyDaysAgo)
          .where("status", "==", "completed")
          .get();

        for (const doc of queueSnapshot.docs) {
          await doc.ref.delete();
          console.log(`Deleted old broadcast: ${doc.id}`);
        }
      }

      console.log("✅ Cleanup completed");
    } catch (error) {
      console.error("Cleanup failed:", error);
    }
  });
