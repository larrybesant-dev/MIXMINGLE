/**
 * Agora Web Bridge v2.js
 *
 * Bridges Agora SDK calls from Flutter Dart to JavaScript.
 * Provides mock implementations for testing without real Agora SDK.
 *
 * Usage: Add this script BEFORE main.dart.js in index.html
 * <script src="agora_web_bridge_v2.js"></script>
 */

(function (window) {
  "use strict";

  // Global state
  let agoraInitialized = false;
  let currentChannel = null;
  let currentUid = null;
  let isAudioMuted = false;
  let isVideoMuted = false;

  console.log("[AgoraBridge] Initializing Agora Web Bridge v2...");

  /**
   * Initialize Agora SDK
   * @param {string} appId - Agora App ID
   */
  window.AgoraInit = async function (appId) {
    console.log("[AgoraBridge] AgoraInit called with App ID:", appId);

    if (!appId || appId === "YOUR_AGORA_APP_ID_HERE") {
      console.warn("[AgoraBridge] ⚠️  Using test/demo App ID. Real Agora SDK not loaded.");
    }

    agoraInitialized = true;
    console.log("[AgoraBridge] ✅ Agora initialized successfully");

    return Promise.resolve();
  };

  /**
   * Join a channel
   * @param {string} channel - Channel name
   * @param {number} uid - Local user ID
   * @param {string} token - Agora token (can be empty for testing)
   */
  window.AgoraJoinChannel = async function (channel, uid, token) {
    console.log("[AgoraBridge] AgoraJoinChannel:", {
      channel,
      uid,
      token: token ? "<token provided>" : "<no token>",
    });

    if (!agoraInitialized) {
      console.error("[AgoraBridge] ❌ Agora not initialized. Call AgoraInit first.");
      throw new Error("Agora not initialized");
    }

    currentChannel = channel;
    currentUid = uid;

    console.log("[AgoraBridge] ✅ Joined channel:", channel, "with UID:", uid);

    // Simulate a remote user joining after 2 seconds (for testing)
    setTimeout(() => {
      if (window.onUserJoined) {
        const remoteUid = 1234;
        console.log("[AgoraBridge] 🎥 Simulating remote user join:", remoteUid);
        window.onUserJoined(remoteUid);
      }
    }, 2000);

    return Promise.resolve();
  };

  /**
   * Leave the current channel
   */
  window.AgoraLeaveChannel = async function () {
    console.log("[AgoraBridge] AgoraLeaveChannel called");

    if (currentChannel) {
      // Simulate remote user leaving after 500ms
      setTimeout(() => {
        if (window.onUserLeft) {
          console.log("[AgoraBridge] ⛔ Simulating remote user leave: 1234");
          window.onUserLeft(1234);
        }
      }, 500);
    }

    currentChannel = null;
    currentUid = null;
    isAudioMuted = false;
    isVideoMuted = false;

    console.log("[AgoraBridge] ✅ Left channel");
    return Promise.resolve();
  };

  /**
   * Enable/disable local audio and video tracks
   * @param {boolean} enableAudio - Enable audio
   * @param {boolean} enableVideo - Enable video
   */
  window.AgoraEnableLocalTracks = async function (enableAudio, enableVideo) {
    console.log("[AgoraBridge] AgoraEnableLocalTracks:", { enableAudio, enableVideo });

    if (!currentChannel) {
      console.error("[AgoraBridge] ❌ Not connected to a channel");
      throw new Error("Not connected to channel");
    }

    console.log(
      "[AgoraBridge] ✅ Local tracks enabled - Audio:",
      enableAudio,
      "Video:",
      enableVideo,
    );
    return Promise.resolve();
  };

  /**
   * Mute/unmute local audio
   * @param {boolean} muted - True to mute, false to unmute
   */
  window.AgoraSetAudioMuted = async function (muted) {
    console.log("[AgoraBridge] AgoraSetAudioMuted:", muted);

    if (!currentChannel) {
      console.error("[AgoraBridge] ❌ Not connected to a channel");
      throw new Error("Not connected to channel");
    }

    isAudioMuted = muted;
    console.log("[AgoraBridge] ✅ Audio", muted ? "muted" : "unmuted");
    return Promise.resolve();
  };

  /**
   * Mute/unmute local video
   * @param {boolean} muted - True to mute, false to unmute
   */
  window.AgoraSetVideoMuted = async function (muted) {
    console.log("[AgoraBridge] AgoraSetVideoMuted:", muted);

    if (!currentChannel) {
      console.error("[AgoraBridge] ❌ Not connected to a channel");
      throw new Error("Not connected to channel");
    }

    isVideoMuted = muted;
    console.log("[AgoraBridge] ✅ Video", muted ? "muted" : "unmuted");
    return Promise.resolve();
  };

  /**
   * Get bridge status (for debugging)
   */
  window.AgoraGetBridgeStatus = function () {
    return {
      initialized: agoraInitialized,
      currentChannel,
      currentUid,
      isAudioMuted,
      isVideoMuted,
      version: "2.0.0",
    };
  };

  // Event handlers (set by Dart code)
  window.onUserJoined = null;
  window.onUserLeft = null;
  window.onConnectionStateChanged = null;

  console.log("[AgoraBridge] ✅ Agora Web Bridge v2 ready");
})(window);
