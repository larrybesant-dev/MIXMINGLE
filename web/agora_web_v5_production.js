// ============================================================================
// Agora Web SDK v5 Integration - Production Ready
// ============================================================================
//
// Features:
// - Agora Web SDK v5.x (latest stable)
// - Automatic token validation
// - Proper permission handling (camera/microphone)
// - Comprehensive error handling & logging
// - Web interoperability support
// - Safe fallbacks for testing
//
// Usage: Load this AFTER Agora SDK but BEFORE Flutter app
// ============================================================================

(function (window) {
  "use strict";

  // ========== CONFIGURATION ==========
  const CONFIG = {
    sdk: {
      // Agora Web SDK v5 (latest stable)
      url: "https://download.agora.io/sdk/release/AgoraRTC_N-5.3.1.js",
      // Fallbacks if primary fails
      fallbacks: [
        "https://download.agora.io/sdk/release/AgoraRTC_N-5.x.x.js",
        "https://download.agora.io/sdk/release/AgoraRTC_N.js",
      ],
    },
    timeout: {
      sdk_load: 15000, // 15 sec to load SDK
      permission: 10000, // 10 sec for camera/mic
      join: 30000, // 30 sec to join channel
    },
    retry: {
      max: 3,
      delay: 2000,
    },
  };

  // ========== FLUTTER CALLBACK HOLDER ==========
  // Flutter (via dart:js) can register callbacks on window.agoraWeb
  // for remote user events. We initialize it once here.
  window.agoraWeb = window.agoraWeb || {};

  // ========== STATE ==========
  let state = {
    initialized: false,
    sdkLoaded: false,
    client: null,
    localTracks: { audio: null, video: null },
    remoteUsers: new Map(),
    currentChannel: null,
    currentUid: null,
    appId: null,
    currentToken: null,
    isJoining: false,
<<<<<<< HEAD
    connectionState: 'DISCONNECTED',
    reconnecting: false,
    reconnectAttempts: 0,
    networkQuality: { uplink: 0, downlink: 0 },
    activeAgoraUsers: new Set(),
    errorLog: [],
    videoEnabling: false
=======
    errorLog: [],
    pushError: function (err) {
      this.errorLog.push(err);
      if (this.errorLog.length > 100) {
        this.errorLog.splice(0, this.errorLog.length - 100);
      }
    },
>>>>>>> origin/develop
  };

  // ========== LOGGING ==========
  function log(level, msg, data = null) {
    const timestamp = new Date().toLocaleTimeString();
    const prefix = `[${timestamp}] [AgoraWeb-${level}]`;

    switch (level) {
      case "INFO":
        console.log(`%c${prefix} ${msg}`, "color: #4A90E2; font-weight: bold;", data);
        break;
      case "SUCCESS":
        console.log(`%c${prefix} ✅ ${msg}`, "color: #4CAF50; font-weight: bold;", data);
        break;
      case "WARNING":
        console.warn(`%c${prefix} ⚠️  ${msg}`, "color: #FF9800; font-weight: bold;", data);
        break;
      case "ERROR":
        console.error(`%c${prefix} ❌ ${msg}`, "color: #F44336; font-weight: bold;", data);
        if (state && typeof state.pushError === "function") {
          state.pushError({ timestamp, msg, data });
        }
        break;
      case "DEBUG":
        if (window.__AGORA_DEBUG) {
          console.debug(`%c${prefix} 🔍 ${msg}`, "color: #9C27B0;", data);
        }
        break;
    }
  }

  function findElementByIdDeep(id) {
    if (!id || typeof document === 'undefined') return null;

    // Fast path: Dart registers each platform-view element in a global map so
    // we never need to pierce Flutter's shadow DOM at all.
    if (typeof window.__getAgoraVideoElement === 'function') {
      const registered = window.__getAgoraVideoElement(id);
      if (registered) return registered;
    }

    function walk(root) {
      if (!root) return null;

      // Document and ShadowRoot both support getElementById in modern browsers.
      if (typeof root.getElementById === 'function') {
        const byId = root.getElementById(id);
        if (byId) return byId;
      }

      if (typeof root.querySelectorAll !== 'function') return null;
      const nodes = root.querySelectorAll('*');
      for (let i = 0; i < nodes.length; i++) {
        const node = nodes[i];
        if (node && node.id === id) return node;
        if (node && node.shadowRoot) {
          const fromShadow = walk(node.shadowRoot);
          if (fromShadow) return fromShadow;
        }
      }

      return null;
    }

    return walk(document);
  }

  function findAnyLocalVideoContainer() {
    if (typeof document === 'undefined') return null;

    function walk(root) {
      if (!root || typeof root.querySelectorAll !== 'function') return null;

      const direct = root.querySelector('[id^="mm_local_video_el_"]');
      if (direct) return direct;

      const nodes = root.querySelectorAll('*');
      for (let i = 0; i < nodes.length; i++) {
        const node = nodes[i];
        if (node && node.shadowRoot) {
          const fromShadow = walk(node.shadowRoot);
          if (fromShadow) return fromShadow;
        }
      }

      return null;
    }

    return walk(document);
  }

  // ========== PERMISSION HANDLING ==========
  async function requestPermissions() {
    log("INFO", "Requesting camera and microphone permissions...");

    try {
      const stream = await navigator.mediaDevices.getUserMedia({
        audio: { echoCancellation: true, noiseSuppression: true },
        video: { width: { ideal: 1280 }, height: { ideal: 720 } },
      });

      // Stop the test stream - we just wanted permission
      stream.getTracks().forEach((track) => track.stop());

      log("SUCCESS", "Camera and microphone permissions granted");
      return true;
    } catch (err) {
      log("ERROR", "Permission request denied or failed", {
        name: err.name,
        message: err.message,
        description:
          err.name === "NotAllowedError"
            ? "User denied permission"
            : err.name === "NotFoundError"
              ? "No camera/microphone found"
              : "Unknown permission error",
      });
      return false;
    }
  }

  // ========== SDK LOADING ==========
  async function loadAgoraSDK() {
    // Accept the pre-loaded SDK only if it is v5.x.  A mismatch (e.g. the
    // page loaded the unversioned AgoraRTC_N.js which resolved to v4.x) would
    // leave window.AgoraRTC defined but with a different API shape, causing
    // internal SDK eval errors ("Unexpected identifier 'subscribe'" etc.).
    if (window.AgoraRTC) {
<<<<<<< HEAD
      const ver = window.AgoraRTC.VERSION || '';
      if (ver.startsWith('5.')) {
        log('SUCCESS', `Agora SDK v${ver} already loaded`);
        state.sdkLoaded = true;
        return true;
      }
      // Wrong version — fall through and load the pinned v5.3.1 URL.
      log('WARNING', `AgoraRTC v${ver || '?'} already on page but expected v5.x — loading pinned version`);
=======
      log("SUCCESS", "Agora SDK already loaded");
      state.sdkLoaded = true;
      return true;
>>>>>>> origin/develop
    }

    log("INFO", "Loading Agora SDK v5.x...");

    const urls = [CONFIG.sdk.url, ...CONFIG.sdk.fallbacks];

    for (let i = 0; i < urls.length; i++) {
      try {
        log("DEBUG", `Attempting to load SDK from: ${urls[i]}`);

        await new Promise((resolve, reject) => {
          const script = document.createElement("script");
          const timeout = setTimeout(
            () => reject(new Error("SDK load timeout")),
            CONFIG.timeout.sdk_load,
          );

          script.src = urls[i];
          script.async = true;
          script.onload = () => {
            clearTimeout(timeout);
            log("SUCCESS", `Agora SDK loaded from: ${urls[i]}`);
            resolve();
          };
          script.onerror = () => {
            clearTimeout(timeout);
            reject(new Error(`Failed to load from ${urls[i]}`));
          };

          document.head.appendChild(script);
        });

        // Verify SDK loaded
        if (!window.AgoraRTC) {
          throw new Error("AgoraRTC not available after script load");
        }

        state.sdkLoaded = true;
        return true;
      } catch (err) {
        log("WARNING", `SDK load attempt ${i + 1} failed`, err.message);
        if (i === urls.length - 1) {
          log("ERROR", "All SDK load attempts failed");
          return false;
        }
        await new Promise((r) => setTimeout(r, 1000));
      }
    }

    return false;
  }

  // ========== TOKEN VALIDATION ==========
  function validateToken(token) {
    if (!token) {
      log("WARNING", "Token is empty - joining in testing mode (no credential)");
      return true;
    }

    if (typeof token !== "string") {
      log("ERROR", "Token must be a string", { received: typeof token });
      return false;
    }

    // Agora tokens are base64 encoded, typically 100-400+ characters
    if (token.length < 100) {
      log("WARNING", "Token looks suspiciously short - may be invalid", {
        length: token.length,
        first20chars: token.substring(0, 20) + "...",
      });
    }

    // Check token format (should be alphanumeric + = for base64)
    if (!/^[A-Za-z0-9+/=]+$/.test(token)) {
      log("ERROR", "Token contains invalid characters");
      return false;
    }

    log("SUCCESS", "Token validation passed", {
      length: token.length,
      preview: token.substring(0, 30) + "...",
    });
    return true;
  }

  // ========== CLIENT CREATION ==========
  async function createAndConfigureClient() {
    if (state.client) {
      log("DEBUG", "Client already exists, returning");
      return state.client;
    }

    log("INFO", "Creating Agora RTC client...");

    try {
      if (!window.AgoraRTC) {
        throw new Error("AgoraRTC SDK not available");
      }

      // Create client with VP8 codec — widest cross-browser support
      // (AV1 is not available on Safari; VP8 works on Chrome, Edge, Firefox, Safari)
      state.client = window.AgoraRTC.createClient({
        mode: "rtc",
        codec: "vp8",
      });

<<<<<<< HEAD
      // NOTE: Do not call setClientRole in rtc mode.
      // Agora Web SDK rejects this with INVALID_OPERATION, which causes a false join failure.
      log('SUCCESS', 'Agora client created and configured');
=======
      log("DEBUG", "Client created, setting role to host...");

      // Set client role to host (broadcaster)
      await state.client.setClientRole("host");

      log("SUCCESS", "Agora client created and configured");
>>>>>>> origin/develop

      // ---- REMOTE USER EVENT LISTENERS ----
      // Subscribe to incoming audio/video from other participants
      // and fire Flutter callbacks so the Dart UI can update.
      state.client.on("user-published", async (user, mediaType) => {
        log("INFO", `Remote user published uid=${user.uid} mediaType=${mediaType}`);
        state.remoteUsers.set(String(user.uid), user);
        state.activeAgoraUsers.add(String(user.uid));
        try {
          await state.client.subscribe(user, mediaType);
<<<<<<< HEAD
          log('SUCCESS', `subscribe done uid=${user.uid} mediaType=${mediaType} hasVideo=${!!user.videoTrack} hasAudio=${!!user.audioTrack}`);
          if (mediaType === 'audio' && user.audioTrack) {
            user.audioTrack.play();
          } else if (mediaType === 'video' && user.videoTrack) {
            const videoElementId = `mm_remote_video_el_${user.uid}`;
            const el = findElementByIdDeep(videoElementId);
            if (el) {
              user.videoTrack.play(el);
              log('SUCCESS', `▶️ Remote video attached uid=${user.uid} elementId=${videoElementId}`);
            } else {
              log('INFO', `Remote video element not ready uid=${user.uid} — Dart retry loop will attach`);
              // 5-second safety watchdog: if the Dart retry loop missed this uid
              // for any reason (DOM timing, brief unmount), force one last attempt.
              setTimeout(() => {
                const trackUser = state.remoteUsers.get(String(user.uid));
                if (trackUser && trackUser.videoTrack) {
                  const watchEl = findElementByIdDeep(videoElementId);
                  if (watchEl) {
                    trackUser.videoTrack.play(watchEl);
                    log('SUCCESS', `▶️ Watchdog: remote video attached uid=${user.uid}`);
                  } else {
                    log('WARNING', `Watchdog: element still not found after 5s uid=${user.uid}`);
                  }
                }
              }, 5000);
            }
          }
        } catch (subErr) {
          log('ERROR', `Failed to subscribe uid=${user.uid} mediaType=${mediaType}`, subErr);
        }
        // Notify Flutter — MUST pass two separate string args to match
        // Dart's allowInterop((String uid, String mediaType) {...}) signature.
        // Passing a JS object as the first arg causes a Dart type-error that is
        // silently swallowed by the catch below, making the callback a no-op.
        if (typeof window.agoraWeb.onRemoteUserPublished === 'function') {
          try { window.agoraWeb.onRemoteUserPublished(String(user.uid), String(mediaType)); } catch (_) {}
        }
      });

      state.client.on('user-unpublished', (user, mediaType) => {
        log('INFO', `Remote user unpublished uid=${user.uid} mediaType=${mediaType}`);
        // Only remove from active set when ALL tracks are gone (user still present until user-left).
        if (!user.videoTrack && !user.audioTrack) {
          state.activeAgoraUsers.delete(String(user.uid));
        }
=======
          if (mediaType === "audio" && user.audioTrack) {
            user.audioTrack.play();
            log("SUCCESS", `▶️ Playing remote audio uid=${user.uid}`);
          }
        } catch (subErr) {
          log("ERROR", `Failed to subscribe uid=${user.uid}`, subErr);
        }
        // Notify Flutter
        if (typeof window.agoraWeb.onRemoteUserPublished === "function") {
          try {
            window.agoraWeb.onRemoteUserPublished({ uid: String(user.uid), mediaType });
          } catch (_) {}
        }
      });

      state.client.on("user-unpublished", (user, mediaType) => {
        log("INFO", `Remote user unpublished uid=${user.uid} mediaType=${mediaType}`);
>>>>>>> origin/develop
        // Notify Flutter
        if (typeof window.agoraWeb.onRemoteUserUnpublished === "function") {
          try {
            window.agoraWeb.onRemoteUserUnpublished({ uid: String(user.uid), mediaType });
          } catch (_) {}
        }
      });

      state.client.on("user-left", (user) => {
        log("INFO", `Remote user left uid=${user.uid}`);
        state.remoteUsers.delete(String(user.uid));
<<<<<<< HEAD
        state.activeAgoraUsers.delete(String(user.uid));
        if (typeof window.agoraWeb.onRemoteUserLeft === 'function') {
          try { window.agoraWeb.onRemoteUserLeft({ uid: String(user.uid) }); } catch (_) {}
=======
        // Notify Flutter
        if (typeof window.agoraWeb.onRemoteUserLeft === "function") {
          try {
            window.agoraWeb.onRemoteUserLeft({ uid: String(user.uid) });
          } catch (_) {}
>>>>>>> origin/develop
        }
      });

      // ---- RESILIENCE LISTENERS ----

      state.client.on('user-joined', (user) => {
        state.activeAgoraUsers.add(String(user.uid));
        const totalCount = state.activeAgoraUsers.size + 1; // +1 for local user
        log('INFO', `Remote user joined uid=${user.uid} room_total=${totalCount}`);
        if (totalCount > 6) {
          log('WARNING', `Beta room-size limit (6) reached — ${totalCount} participants detected`);
          if (typeof window.agoraWeb.onRoomFull === 'function') {
            try { window.agoraWeb.onRoomFull({ count: totalCount }); } catch (_) {}
          }
        }
        if (typeof window.agoraWeb.onRemoteUserJoined === 'function') {
          try { window.agoraWeb.onRemoteUserJoined(String(user.uid)); } catch (_) {}
        }
      });

      state.client.on('connection-state-change', async (curState, prevState) => {
        log('INFO', `Connection: ${prevState} → ${curState}`);
        state.connectionState = curState;
        if (typeof window.agoraWeb.onConnectionStateChange === 'function') {
          try { window.agoraWeb.onConnectionStateChange(curState, prevState); } catch (_) {}
        }
        if (curState === 'CONNECTED') {
          state.reconnecting = false;
          state.reconnectAttempts = 0;
        }
        // SDK exhausted its own reconnect attempts — manually rejoin
        if (curState === 'DISCONNECTED' && prevState === 'RECONNECTING' && state.currentChannel && !state.reconnecting) {
          log('WARNING', 'SDK reconnect failed — triggering manual rejoin');
          reconnectToChannel();
        }
      });

      state.client.on('token-privilege-will-expire', async () => {
        log('INFO', 'Token expiring soon — requesting renewal');
        fetchNewAgoraToken();
      });

      state.client.on('token-privilege-did-expire', async () => {
        log('WARNING', 'Token expired — requesting renewal and rejoining');
        fetchNewAgoraToken();
        // Allow 3 s for Flutter to push new token via agoraWebRenewToken()
        await new Promise(r => setTimeout(r, 3000));
        if (state.currentChannel && state.appId && !state.reconnecting) {
          reconnectToChannel();
        }
      });

      state.client.on('network-quality', (stats) => {
        state.networkQuality = { uplink: stats.uplinkNetworkQuality, downlink: stats.downlinkNetworkQuality };
        // 0=unknown 1=excellent 2=good 3=poor 4=bad 5=very_bad 6=disconnected
        if (stats.uplinkNetworkQuality >= 4 || stats.downlinkNetworkQuality >= 4) {
          log('WARNING', `Weak network — uplink=${stats.uplinkNetworkQuality} downlink=${stats.downlinkNetworkQuality}`);
          if (typeof window.agoraWeb.onNetworkQuality === 'function') {
            try { window.agoraWeb.onNetworkQuality({ uplink: stats.uplinkNetworkQuality, downlink: stats.downlinkNetworkQuality }); } catch (_) {}
          }
        }
      });

      // ---- END EVENT LISTENERS ----

      return state.client;
    } catch (err) {
      log("ERROR", "Failed to create client", {
        message: err.message,
        stack: err.stack,
      });
      throw err;
    }
  }

  // ========== TRACK MANAGEMENT ==========
  async function createLocalTracks() {
    log("INFO", "Creating local audio and video tracks...");

    try {
      if (state.localTracks.audio && state.localTracks.video) {
        log("DEBUG", "Local tracks already exist");
        return true;
      }

      // Ensure permissions
      if (!(await requestPermissions())) {
        log("ERROR", "User denied permissions, cannot create tracks");
        return false;
      }

      // Create microphone audio track
      if (!state.localTracks.audio) {
        log("DEBUG", "Creating microphone audio track...");
        state.localTracks.audio = await window.AgoraRTC.createMicrophoneAudioTrack({
          echoCancellation: true,
          noiseSuppression: true,
          autoGainControl: true,
        });
        log("SUCCESS", "Microphone audio track created");
      }

      // Create camera video track
      if (!state.localTracks.video) {
        log("DEBUG", "Creating camera video track...");
        state.localTracks.video = await window.AgoraRTC.createCameraVideoTrack({
          encoderConfig: "720p_auto", // auto-select optimal resolution
        });
        log("SUCCESS", "Camera video track created");
      }

      return true;
    } catch (err) {
      log("ERROR", "Failed to create local tracks", {
        message: err.message,
        name: err.name,
      });
      return false;
    }
  }

  // ========== CHANNEL JOIN ==========
  async function joinChannelWithRetry(appId, channelName, token, uid) {
    let lastError;

    for (let attempt = 1; attempt <= CONFIG.retry.max; attempt++) {
      try {
        log("INFO", `Join attempt ${attempt}/${CONFIG.retry.max}`, {
          channel: channelName,
          uid: uid,
          hasToken: !!token,
        });

        if (state.isJoining) {
          log("WARNING", "Already joining, waiting...");
          // Wait briefly
          await new Promise((r) => setTimeout(r, 1000));
          continue;
        }

        state.isJoining = true;

        // Create client if needed
        await createAndConfigureClient();

        // Validate parameters
        if (!appId) throw new Error("appId is required");
        if (!channelName) throw new Error("channelName is required");
        if (!uid) throw new Error("uid is required");

        // Validate token if provided
        if (token && !validateToken(token)) {
          throw new Error("Token validation failed");
        }

        // Join the channel
        log("DEBUG", "Calling client.join()...");
        const assignedUid = await Promise.race([
          state.client.join(appId, channelName, token || null, uid),
          new Promise((_, reject) =>
            setTimeout(() => reject(new Error("Join timeout")), CONFIG.timeout.join),
          ),
        ]);

        log("SUCCESS", "Successfully joined channel", {
          channel: channelName,
          assignedUid: assignedUid,
          requestedUid: uid,
        });

<<<<<<< HEAD
        // Join should not auto-request media permissions or auto-publish.
        // Tracks are created/published only when the user explicitly toggles cam/mic.
        log('INFO', 'Joined as listener; awaiting explicit cam/mic enable actions');
=======
        // Create local tracks after join
        const tracksCreated = await createLocalTracks();
        if (!tracksCreated) {
          log("WARNING", "Could not create local tracks, but channel join succeeded");
        }

        // Publish tracks if created
        if (state.localTracks.audio || state.localTracks.video) {
          const tracks = [];
          if (state.localTracks.audio) tracks.push(state.localTracks.audio);
          if (state.localTracks.video) tracks.push(state.localTracks.video);

          if (tracks.length > 0) {
            log("DEBUG", "Publishing local tracks...");
            await state.client.publish(tracks);
            log("SUCCESS", "Local tracks published");
          }
        }
>>>>>>> origin/develop

        state.currentChannel = channelName;
        state.currentUid = uid;
        state.appId = appId;
        state.currentToken = token || null;
        state.connectionState = 'CONNECTED';
        state.reconnectAttempts = 0;
        state.isJoining = false;

        return true;
      } catch (err) {
        lastError = err;
        state.isJoining = false;

        log("ERROR", `Join attempt ${attempt} failed`, {
          message: err.message,
          type: err.name || "Unknown",
          willRetry: attempt < CONFIG.retry.max,
        });

        if (attempt < CONFIG.retry.max) {
          log("INFO", `Retrying in ${CONFIG.retry.delay}ms...`);
          await new Promise((r) => setTimeout(r, CONFIG.retry.delay));
        }
      }
    }

    log("ERROR", "Failed to join after all retry attempts", lastError);
    return false;
  }

  // ========== RECONNECT HELPER ==========
  async function reconnectToChannel() {
    if (state.reconnecting || !state.currentChannel || !state.appId) return;
    const MAX_ATTEMPTS = 3;
    if (state.reconnectAttempts >= MAX_ATTEMPTS) {
      log('ERROR', 'Max reconnect attempts reached — giving up');
      if (typeof window.agoraWeb.onConnectionFailed === 'function') {
        try { window.agoraWeb.onConnectionFailed(); } catch (_) {}
      }
      return;
    }
    state.reconnecting = true;
    state.reconnectAttempts += 1;
    const delay = state.reconnectAttempts * 2000;
    log('INFO', `Reconnect attempt ${state.reconnectAttempts}/${MAX_ATTEMPTS} in ${delay}ms...`);
    await new Promise(r => setTimeout(r, delay));
    if (!state.currentChannel) { state.reconnecting = false; return; } // user left intentionally
    try {
      await state.client.join(state.appId, state.currentChannel, state.currentToken || null, state.currentUid);
      log('SUCCESS', 'Reconnected to channel');
      // Re-publish any active local tracks
      const tracks = [];
      if (state.localTracks.audio) tracks.push(state.localTracks.audio);
      if (state.localTracks.video) tracks.push(state.localTracks.video);
      if (tracks.length > 0) {
        try { await state.client.publish(tracks); log('SUCCESS', 'Local tracks re-published after reconnect'); }
        catch (e) { log('ERROR', 'Failed to re-publish tracks after reconnect', e.message); }
      }
      state.reconnecting = false;
      state.reconnectAttempts = 0;
    } catch (err) {
      log('ERROR', `Reconnect attempt ${state.reconnectAttempts} failed`, err.message);
      state.reconnecting = false;
      reconnectToChannel(); // schedule next attempt
    }
  }

  // ========== TOKEN RENEWAL HELPER ==========
  // Flutter registers window.agoraWeb.onTokenWillExpire; it fetches a new token
  // and calls window.agoraWebRenewToken(newToken) to push it back to the bridge.
  function fetchNewAgoraToken() {
    if (typeof window.agoraWeb.onTokenWillExpire === 'function') {
      try { window.agoraWeb.onTokenWillExpire(state.currentChannel, String(state.currentUid)); } catch (_) {}
    } else {
      log('WARNING', 'onTokenWillExpire callback not registered — token renewal will not happen automatically');
    }
  }

  // ========== PUBLIC API - FLUTTER CALLABLE ==========

  /**
   * Initialize Agora Web
   * @param {string} appId - Agora App ID
   * @returns {Promise<boolean>}
   */
  window.agoraWebInit = async function (appId) {
    log("INFO", "agoraWebInit called", { appId: appId?.substring(0, 8) + "..." });

    if (state.initialized) {
      log("DEBUG", "Already initialized, returning true");
      return true;
    }

    try {
      // Load SDK
      const sdkLoaded = await loadAgoraSDK();
      if (!sdkLoaded) {
        throw new Error("Failed to load Agora SDK");
      }

      state.initialized = true;
      log("SUCCESS", "Agora Web initialized successfully");
      return true;
    } catch (err) {
      log("ERROR", "Initialization failed", err);
      return false;
    }
  };

  /**
   * Join a channel
   * @param {string} token - Agora token (or empty for testing)
   * @param {string} channelName - Channel name
   * @param {string} uid - User ID
   * @returns {Promise<boolean>}
   */
  window.agoraWebJoinChannel = async function (appId, channelName, token, uid) {
    log("INFO", "agoraWebJoinChannel called", {
      appId: appId?.substring(0, 8) + "...",
      channel: channelName,
      uid: uid,
      hasToken: !!token,
    });

    if (!state.initialized) {
<<<<<<< HEAD
      log('WARNING', 'Join called before init; auto-initializing now');
      const initOk = await window.agoraWebInit(appId);
      if (!initOk) {
        log('ERROR', 'Auto-init failed before join');
        return false;
      }
=======
      log("ERROR", "Not initialized. Call agoraWebInit first");
      return false;
>>>>>>> origin/develop
    }

    if (!state.sdkLoaded) {
      log("WARNING", "SDK not loaded, attempting to load now...");
      if (!(await loadAgoraSDK())) {
        log("ERROR", "Failed to load SDK");
        return false;
      }
    }

    return joinChannelWithRetry(appId, channelName, token, uid);
  };

  /**
   * Leave the channel
   * @returns {Promise<boolean>}
   */
  window.agoraWebLeaveChannel = async function () {
    log("INFO", "agoraWebLeaveChannel called");

    try {
      if (state.client) {
<<<<<<< HEAD
        // Null out channel first so connection-state-change DISCONNECTED
        // does NOT trigger an automatic reconnect during intentional leave.
        const channel = state.currentChannel;
        state.currentChannel = null;
        state.currentUid = null;
        state.connectionState = 'DISCONNECTED';
        state.activeAgoraUsers.clear();

        // Stop local tracks before unpublishing
=======
        log("DEBUG", "Unpublishing local tracks...");

        // Unpublish local tracks
        if (state.localTracks.audio || state.localTracks.video) {
          const tracks = [];
          if (state.localTracks.audio) tracks.push(state.localTracks.audio);
          if (state.localTracks.video) tracks.push(state.localTracks.video);

          if (tracks.length > 0) {
            await state.client.unpublish(tracks);
          }
        }

        log("DEBUG", "Stopping local tracks...");

        // Stop local tracks
>>>>>>> origin/develop
        if (state.localTracks.audio) {
          state.localTracks.audio.close();
          state.localTracks.audio = null;
        }
        if (state.localTracks.video) {
          state.localTracks.video.stop();
          state.localTracks.video.close();
          state.localTracks.video = null;
        }

<<<<<<< HEAD
=======
        log("DEBUG", "Leaving channel...");

>>>>>>> origin/develop
        // Leave channel
        if (channel) {
          try { await state.client.leave(); }
          catch (leaveErr) { log('WARNING', 'client.leave() error (ignored)', leaveErr.message); }
        }

        log("SUCCESS", "Left channel successfully");
      }
      return true;
    } catch (err) {
      log("ERROR", "Failed to leave channel", err);
      return false;
    }
  };

  /**
   * Set microphone muted state
   * @param {boolean} muted - Whether to mute
   * @returns {Promise<boolean>}
   */
  window.agoraWebSetMicMuted = async function (muted) {
    log("DEBUG", `agoraWebSetMicMuted called (${muted ? "muting" : "unmuting"})`);

    try {
      if (!state.localTracks.audio && muted === false) {
        log('WARNING', 'No local audio track while unmuting; creating track now');
        state.localTracks.audio = await window.AgoraRTC.createMicrophoneAudioTrack({
          echoCancellation: true,
          noiseSuppression: true,
          autoGainControl: true,
        });

        if (state.client && state.currentChannel) {
          await state.client.publish([state.localTracks.audio]);
          log('SUCCESS', 'Audio track created and published from unmute request');
        }
      }

      if (state.localTracks.audio) {
        if (muted) {
          await state.localTracks.audio.setMuted(true);
        } else {
          await state.localTracks.audio.setMuted(false);
        }
        log("SUCCESS", `Microphone ${muted ? "muted" : "unmuted"}`);
        return true;
      }
      return false;
    } catch (err) {
      log("ERROR", "Failed to set mic mute state", err);
      return false;
    }
  };

  /**
   * Set video muted state
   * @param {boolean} muted - Whether to mute
   * @returns {Promise<boolean>}
   */
  window.agoraWebSetVideoMuted = async function (muted) {
    log("DEBUG", `agoraWebSetVideoMuted called (${muted ? "disabling" : "enabling"})`);

    try {
      if (muted) {
        // Camera OFF: unpublish ALL published video tracks (including orphans from
        // any previous concurrent enable calls), then stop/close to release the webcam.
        if (state.client && state.currentChannel) {
          const publishedVideoTracks = Array.isArray(state.client.localTracks)
            ? state.client.localTracks.filter(t => t.trackMediaType === 'video')
            : [];
          if (publishedVideoTracks.length > 0) {
            try { await state.client.unpublish(publishedVideoTracks); } catch (e) {}
          }
          // Stop and close every published video track so the webcam light goes off
          for (const t of publishedVideoTracks) {
            try { t.stop(); } catch (e) {}
            try { t.close(); } catch (e) {}
          }
        }
        // Also close the state-tracked track in case it was created but never published
        if (state.localTracks.video) {
          try { state.localTracks.video.stop(); } catch (e) {}
          try { state.localTracks.video.close(); } catch (e) {}
        }
        state.localTracks.video = null;
        log('SUCCESS', 'Camera track released — webcam light OFF');
        return true;
      } else {
        // Camera ON: if a track already exists, nothing to do
        if (state.localTracks.video) {
          log('INFO', 'Camera track already active, skipping recreate');
          return true;
        }
        // Guard against concurrent enables (race condition from Flutter render loop)
        if (state.videoEnabling) {
          log('INFO', 'Video enable already in progress, skipping duplicate call');
          return true;
        }
        state.videoEnabling = true;
        try {
          // Recreate and publish a fresh camera track
          log('INFO', 'No local video track while enabling video; creating and publishing now');
          state.localTracks.video = await window.AgoraRTC.createCameraVideoTrack({
            encoderConfig: '720p_auto'
          });
          log('SUCCESS', `Camera video track created uid=${state.currentUid}`);

          if (state.client && state.currentChannel) {
            // Guard against double-publish: check if client already has a published video track
            const alreadyPublishedVideo = Array.isArray(state.client.localTracks) &&
              state.client.localTracks.some(t => t.trackMediaType === 'video');
            if (alreadyPublishedVideo) {
              log('WARNING', 'Client already has a published video track — skipping duplicate publish');
            } else {
              await state.client.publish([state.localTracks.video]);
              log('SUCCESS', `client.publish() done — remote peers will receive user-published(video) uid=${state.currentUid}`);
            }
          } else {
            log('WARNING', `client.publish skipped — client=${!!state.client} channel=${state.currentChannel}`);
          }

          // Best-effort: play in local video container if already mounted in DOM
          const localEl = findAnyLocalVideoContainer();
          if (localEl) {
            state.localTracks.video.play(localEl);
            log('SUCCESS', 'Local camera replayed in DOM container after re-enable');
          } else {
            log('WARNING', 'No local video container found yet — Flutter _startAttachRetries will handle playback');
          }
        } finally {
          state.videoEnabling = false;
        }
<<<<<<< HEAD
=======
        log("SUCCESS", `Video ${muted ? "disabled" : "enabled"}`);
>>>>>>> origin/develop
        return true;
      }
    } catch (err) {
      log("ERROR", "Failed to set video mute state", err);
      return false;
    }
  };

  /**
   * Attach local camera track to a target video container element.
   * @param {string} videoElementId - DOM id of the container element
   * @returns {Promise<boolean>}
   */
  window.agoraWebPlayCamera = async function(videoElementId) {
    try {
      if (!state.localTracks.video) {
        log('WARNING', 'agoraWebPlayCamera called with no local video track');
        return false;
      }

      let el = findElementByIdDeep(videoElementId);
      if (!el) {
        el = findAnyLocalVideoContainer();
      }

      if (!el) {
        log('WARNING', 'agoraWebPlayCamera target element not found', { videoElementId });
        return false;
      }

      state.localTracks.video.play(el);
      log('SUCCESS', 'Local camera attached to DOM element', { videoElementId });
      return true;
    } catch (err) {
      log('ERROR', 'Failed to attach local camera to DOM element', err);
      return false;
    }
  };

  /**
   * Attach a remote user's video track to a target DOM element.
   * Called by Flutter after the HtmlElementView div is rendered in the DOM.
   * @param {string} uidStr - Remote user UID as string
   * @param {string} videoElementId - DOM id of the container element
   * @returns {Promise<boolean>}
   */
  window.agoraWebPlayRemoteVideo = async function(uidStr, videoElementId) {
    try {
      const user = state.remoteUsers.get(String(uidStr));
      if (!user || !user.videoTrack) {
        // user-published / subscribe not complete yet — Dart retry loop will retry
        return false;
      }
      const el = findElementByIdDeep(videoElementId);
      if (!el) {
        // HtmlElementView not yet in DOM — Dart retry loop will retry
        return false;
      }
      await user.videoTrack.play(el);
      log('SUCCESS', `Remote video attached uid=${uidStr} elementId=${videoElementId}`);
      return true;
    } catch (err) {
      log('ERROR', 'Failed to attach remote video to DOM element', err);
      return false;
    }
  };

  /**
   * Get current state for debugging
   * @returns {Object}
   */
  window.agoraWebGetState = function () {
    return {
      initialized: state.initialized,
      sdkLoaded: state.sdkLoaded,
      currentChannel: state.currentChannel,
      currentUid: state.currentUid,
      isJoining: state.isJoining,
      hasAudio: !!state.localTracks.audio,
      hasVideo: !!state.localTracks.video,
      remoteUserCount: state.remoteUsers.size,
      viewerCount: state.activeAgoraUsers.size + 1,
      connectionState: state.connectionState,
      reconnecting: state.reconnecting,
      networkQuality: state.networkQuality,
      errorCount: state.errorLog.length,
      lastErrors: state.errorLog.slice(-5),
    };
  };

  /**
   * Renew the Agora token. Flutter calls this after fetching a fresh token
   * from the Firebase generateAgoraToken Cloud Function.
   * @param {string} newToken
   * @returns {Promise<boolean>}
   */
  window.agoraWebRenewToken = async function(newToken) {
    try {
      if (!state.client || !state.currentChannel) {
        log('WARNING', 'agoraWebRenewToken: not in channel, ignoring');
        return false;
      }
      await state.client.renewToken(newToken);
      state.currentToken = newToken;
      log('SUCCESS', 'Agora token renewed successfully');
      return true;
    } catch (err) {
      log('ERROR', 'Failed to renew token', err.message);
      return false;
    }
  };

  // ========== WEB TAB VISIBILITY HANDLING ==========
  // When the user switches browser tabs, mute local tracks to prevent
  // continuous audio/video transmission from a background tab.
  // This mirrors the AppLifecycleState.paused handling on mobile.
  if (typeof document !== "undefined") {
    document.addEventListener("visibilitychange", async function () {
      if (!state.currentChannel) return; // Not in a channel

      if (document.hidden) {
<<<<<<< HEAD
=======
        log("INFO", "Tab hidden — muting local tracks to save bandwidth");
>>>>>>> origin/develop
        try {
          if (state.localTracks.audio) await state.localTracks.audio.setMuted(true);
          // Note: video track may be null if user turned camera off; that is intentional
          if (state.localTracks.video) await state.localTracks.video.setMuted(true);
        } catch (e) {
          log("WARNING", "Failed to mute tracks on tab hidden", e.message);
        }
      } else {
<<<<<<< HEAD
=======
        log("INFO", "Tab visible — unmuting local tracks");
>>>>>>> origin/develop
        try {
          // Only unmute tracks that are still active — do NOT recreate a released video track
          if (state.localTracks.audio) await state.localTracks.audio.setMuted(false);
          if (state.localTracks.video) await state.localTracks.video.setMuted(false);
        } catch (e) {
          log("WARNING", "Failed to unmute tracks on tab visible", e.message);
        }
      }
    });
  }

<<<<<<< HEAD
  // ========== BROWSER UNLOAD HANDLING ==========
  // Fires both on tab close and page navigation so the local user's Agora
  // slot is released promptly instead of waiting for token expiry.
  if (typeof window !== 'undefined') {
    window.addEventListener('beforeunload', function () {
      if (state.currentChannel) {
        state.activeAgoraUsers.clear();
        // Best-effort synchronous track release (no await available in beforeunload)
        try { if (state.localTracks.audio) { state.localTracks.audio.close(); state.localTracks.audio = null; } } catch (_) {}
        try { if (state.localTracks.video) { state.localTracks.video.stop(); state.localTracks.video.close(); state.localTracks.video = null; } } catch (_) {}
        try { state.client.leave(); } catch (_) {}
        state.currentChannel = null;
      }
    });
  }

  // ========== STARTUP ==========
  log('SUCCESS', 'Agora Web production bridge initialized and ready');

  // ========== DJ AUDIO MIXING ==========
  // Plays a remote audio URL as a background music track alongside the live mic.
  // Uses Agora SDK v5 BufferSourceAudioTrack so the mix is published to the channel.

  let djAudioTrack = null;   // Agora BufferSourceAudioTrack
  let djGainNode = null;     // Web Audio GainNode for volume control (fallback path)

  /**
   * Start playing an audio URL as background music in the channel.
   * @param {string} url - HTTP/HTTPS URL of the audio file
   * @param {boolean} loop - Whether to loop the track
   */
  window.agoraWebStartAudioMixing = async function(url, loop) {
    try {
      if (!state.client || !state.currentChannel) {
        log('WARNING', 'DJ startAudioMixing called but not in a channel');
        return false;
      }
      // Stop any existing mix first
      await window.agoraWebStopAudioMixing();

      if (window.AgoraRTC && typeof window.AgoraRTC.createBufferSourceAudioTrack === 'function') {
        // Preferred: Agora's BufferSourceAudioTrack (published to channel)
        djAudioTrack = await window.AgoraRTC.createBufferSourceAudioTrack({ source: url });
        djAudioTrack.startProcessAudioBuffer({ loop: !!loop });
        await state.client.publish([djAudioTrack]);
        log('SUCCESS', 'DJ audio mixing started via BufferSourceAudioTrack', { url, loop });
      } else {
        // Fallback: Web Audio API (only audible locally)
        const audioCtx = new (window.AudioContext || window.webkitAudioContext)();
        const response = await fetch(url);
        const arrayBuffer = await response.arrayBuffer();
        const audioBuffer = await audioCtx.decodeAudioData(arrayBuffer);
        const source = audioCtx.createBufferSource();
        source.buffer = audioBuffer;
        source.loop = !!loop;
        djGainNode = audioCtx.createGain();
        djGainNode.gain.value = 0.5;
        source.connect(djGainNode);
        djGainNode.connect(audioCtx.destination);
        source.start(0);
        djAudioTrack = { _source: source, _ctx: audioCtx, _fallback: true };
        log('WARNING', 'DJ audio mixing started via Web Audio fallback (local only)', { url });
      }
      return true;
    } catch (err) {
      log('ERROR', 'DJ startAudioMixing failed', err);
      return false;
    }
  };

  /** Stop audio mixing and unpublish the track. */
  window.agoraWebStopAudioMixing = async function() {
    try {
      if (!djAudioTrack) return true;
      if (djAudioTrack._fallback) {
        try { djAudioTrack._source.stop(); } catch (_) {}
        try { djAudioTrack._ctx.close(); } catch (_) {}
      } else {
        djAudioTrack.stopProcessAudioBuffer();
        if (state.client) {
          try { await state.client.unpublish([djAudioTrack]); } catch (_) {}
        }
        djAudioTrack.close();
      }
      djAudioTrack = null;
      djGainNode = null;
      log('SUCCESS', 'DJ audio mixing stopped');
      return true;
    } catch (err) {
      log('ERROR', 'DJ stopAudioMixing failed', err);
      return false;
    }
  };

  /** Pause audio mixing. */
  window.agoraWebPauseAudioMixing = async function() {
    try {
      if (!djAudioTrack) return false;
      if (!djAudioTrack._fallback) {
        djAudioTrack.pauseProcessAudioBuffer();
      }
      log('INFO', 'DJ audio mixing paused');
      return true;
    } catch (err) {
      log('ERROR', 'DJ pauseAudioMixing failed', err);
      return false;
    }
  };

  /** Resume paused audio mixing. */
  window.agoraWebResumeAudioMixing = async function() {
    try {
      if (!djAudioTrack) return false;
      if (!djAudioTrack._fallback) {
        djAudioTrack.resumeProcessAudioBuffer();
      }
      log('INFO', 'DJ audio mixing resumed');
      return true;
    } catch (err) {
      log('ERROR', 'DJ resumeAudioMixing failed', err);
      return false;
    }
  };

  /**
   * Set audio mixing volume.
   * @param {number} volume - 0 to 100
   */
  window.agoraWebSetAudioMixingVolume = async function(volume) {
    try {
      const v = Math.max(0, Math.min(100, volume));
      if (!djAudioTrack) return false;
      if (djAudioTrack._fallback) {
        if (djGainNode) djGainNode.gain.value = v / 100;
      } else {
        djAudioTrack.setVolume(v);
      }
      log('INFO', 'DJ volume set', { volume: v });
      return true;
    } catch (err) {
      log('ERROR', 'DJ setAudioMixingVolume failed', err);
      return false;
    }
  };

=======
  // ========== STARTUP ==========
  log("INFO", "Agora Web v5 bridge loaded and ready");

  // Make available globally
  window.agoraWebDebug = function () {
    console.table(window.agoraWebGetState());
    console.table(state.errorLog.slice(-10));
  };

  log("SUCCESS", "Agora Web production bridge initialized");
>>>>>>> origin/develop
})(window);
