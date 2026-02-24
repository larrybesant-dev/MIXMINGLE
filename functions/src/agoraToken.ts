// functions/src/agoraToken.ts

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { RtcTokenBuilder, RtcRole } from 'agora-access-token';

admin.initializeApp();

export const generateAgoraToken = functions.https.onCall(async (data, context) => {
  const { channelName, uid, role } = data;
  const appId = functions.config().agora.appid;
  const appCertificate = functions.config().agora.certificate;
  const expireTime = 3600;

  const agoraRole = role === 'host' ? RtcRole.PUBLISHER : RtcRole.SUBSCRIBER;
  const token = RtcTokenBuilder.buildTokenWithUid(appId, appCertificate, channelName, uid, agoraRole, expireTime);

  return { token };
});
