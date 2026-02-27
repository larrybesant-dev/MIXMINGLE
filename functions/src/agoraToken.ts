// functions/src/agoraToken.ts

import { onCall, HttpsError } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import * as admin from "firebase-admin";
import { RtcTokenBuilder, RtcRole } from "agora-access-token";

admin.initializeApp();

const AGORA_APP_ID = defineSecret("AGORA_APP_ID");
const AGORA_APP_CERTIFICATE = defineSecret("AGORA_APP_CERTIFICATE");

export const generateAgoraToken = onCall(
  {
    region: "us-central1",
    cors: true,
    secrets: [AGORA_APP_ID, AGORA_APP_CERTIFICATE],
  },
  async (request) => {
    const { channelName, uid, role } = request.data;
    const appId = AGORA_APP_ID.value();
    const appCertificate = AGORA_APP_CERTIFICATE.value();
    if (!appId || !appCertificate) {
      throw new HttpsError("internal", "Agora credentials not configured.");
    }
    const expireTime = 3600;
    const agoraRole = role === "host" ? RtcRole.PUBLISHER : RtcRole.SUBSCRIBER;
    const token = RtcTokenBuilder.buildTokenWithUid(
      appId,
      appCertificate,
      channelName,
      uid,
      agoraRole,
      expireTime,
    );
    return { token };
  },
);
