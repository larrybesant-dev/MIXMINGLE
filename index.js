const admin = require("firebase-admin");
const { RtcTokenBuilder, RtcRole } = require("agora-token");
if (!admin.apps.length) admin.initializeApp();

exports.generateAgoraToken = async (req, res) => {
  // Input validation
  const { roomId, userId, role } = req.body || {};
  if (!roomId || !userId) {
    console.error(JSON.stringify({ event: "missing_param", roomId: !!roomId, userId: !!userId }));
    return res
      .status(400)
      .json({ error: "Missing required parameter: roomId and userId are required" });
  }

  // Secret checks
  const appId = process.env.AGORA_APP_ID;
  const appCertificate = process.env.AGORA_APP_CERTIFICATE;
  if (!appId || !appCertificate) {
    console.error(
      JSON.stringify({ event: "missing_secret", appId: !!appId, appCertificate: !!appCertificate }),
    );
    return res.status(500).json({ error: "Server configuration error: Agora secrets missing" });
  }

  // Room/participant checks (optional, remove if not using Firestore)
  try {
    const roomRef = admin.firestore().collection("rooms").doc(roomId);
    const roomDoc = await roomRef.get();
    if (!roomDoc.exists) {
      console.warn(JSON.stringify({ event: "room_not_found", roomId }));
      return res.status(404).json({ error: "Room not found" });
    }
    const roomData = roomDoc.data();
    if (roomData.privacy === "private" || roomData.isPrivate) {
      const participantRef = roomRef.collection("participants").doc(userId);
      const participantDoc = await participantRef.get();
      if (!participantDoc.exists && roomData.hostId !== userId) {
        console.warn(JSON.stringify({ event: "private_room_denied", roomId, userId }));
        return res.status(403).json({ error: "Access denied: Private room" });
      }
    }
    // Token generation
    const agoraRole =
      role === "broadcaster" || role === "host" || role === "speaker"
        ? RtcRole.PUBLISHER
        : RtcRole.SUBSCRIBER;
    const expirationTimeInSeconds = 86400;
    const currentTimestamp = Math.floor(Date.now() / 1000);
    const privilegeExpiredTs = currentTimestamp + expirationTimeInSeconds;
    const token = RtcTokenBuilder.buildTokenWithUid(
      appId,
      appCertificate,
      roomId,
      parseInt(userId, 10),
      agoraRole,
      privilegeExpiredTs,
    );
    console.info(
      JSON.stringify({
        event: "token_generated",
        roomId,
        userId,
        role: agoraRole,
        expiresAt: new Date(privilegeExpiredTs * 1000).toISOString(),
      }),
    );
    return res.status(200).json({
      token,
      appId,
      roomId,
      userId,
      role: agoraRole,
      expiresAt: privilegeExpiredTs * 1000,
    });
  } catch (error) {
    console.error(
      JSON.stringify({ event: "token_error", error: error?.message, stack: error?.stack }),
    );
    return res
      .status(500)
      .json({ error: "Internal server error", message: error?.message || "Unknown error" });
  }
};
