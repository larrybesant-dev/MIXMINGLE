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

(function(window) {
  'use strict';

  // ========== CONFIGURATION ==========
  const CONFIG = {
    sdk: {
      // Agora Web SDK v5 (latest stable)
      url: 'https://download.agora.io/sdk/release/AgoraRTC_N-5.3.1.js',
      // Fallbacks if primary fails
      fallbacks: [
        'https://download.agora.io/sdk/release/AgoraRTC_N-5.x.x.js',
        'https://download.agora.io/sdk/release/AgoraRTC_N.js'
      ]
    },
    timeout: {
      sdk_load: 15000,      // 15 sec to load SDK
      permission: 10000,    // 10 sec for camera/mic
      join: 30000,          // 30 sec to join channel
    },
    retry: {
      max: 3,
      delay: 2000
    }
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
    isJoining: false,
    errorLog: []
  };

  // ========== LOGGING ==========
  function log(level, msg, data = null) {
    const timestamp = new Date().toLocaleTimeString();
    const prefix = `[${timestamp}] [AgoraWeb-${level}]`;

    switch(level) {
      case 'INFO':
        console.log(`%c${prefix} ${msg}`, 'color: #4A90E2; font-weight: bold;', data);
        break;
      case 'SUCCESS':
        console.log(`%c${prefix} ✅ ${msg}`, 'color: #4CAF50; font-weight: bold;', data);
        break;
      case 'WARNING':
        console.warn(`%c${prefix} ⚠️  ${msg}`, 'color: #FF9800; font-weight: bold;', data);
        break;
      case 'ERROR':
        console.error(`%c${prefix} ❌ ${msg}`, 'color: #F44336; font-weight: bold;', data);
        state.errorLog.push({ timestamp, msg, data });
        break;
      case 'DEBUG':
        if (window.__AGORA_DEBUG) {
          console.debug(`%c${prefix} 🔍 ${msg}`, 'color: #9C27B0;', data);
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
    log('INFO', 'Requesting camera and microphone permissions...');

    try {
      const stream = await navigator.mediaDevices.getUserMedia({
        audio: { echoCancellation: true, noiseSuppression: true },
        video: { width: { ideal: 1280 }, height: { ideal: 720 } }
      });

      // Stop the test stream - we just wanted permission
      stream.getTracks().forEach(track => track.stop());

      log('SUCCESS', 'Camera and microphone permissions granted');
      return true;
    } catch (err) {
      log('ERROR', 'Permission request denied or failed', {
        name: err.name,
        message: err.message,
        description: err.name === 'NotAllowedError'
          ? 'User denied permission'
          : err.name === 'NotFoundError'
          ? 'No camera/microphone found'
          : 'Unknown permission error'
      });
      return false;
    }
  }

  // ========== SDK LOADING ==========
  async function loadAgoraSDK() {
    if (window.AgoraRTC) {
      log('SUCCESS', 'Agora SDK already loaded');
      state.sdkLoaded = true;
      return true;
    }

    log('INFO', 'Loading Agora SDK v5.x...');

    const urls = [CONFIG.sdk.url, ...CONFIG.sdk.fallbacks];

    for (let i = 0; i < urls.length; i++) {
      try {
        log('DEBUG', `Attempting to load SDK from: ${urls[i]}`);

        await new Promise((resolve, reject) => {
          const script = document.createElement('script');
          const timeout = setTimeout(
            () => reject(new Error('SDK load timeout')),
            CONFIG.timeout.sdk_load
          );

          script.src = urls[i];
          script.async = true;
          script.onload = () => {
            clearTimeout(timeout);
            log('SUCCESS', `Agora SDK loaded from: ${urls[i]}`);
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
          throw new Error('AgoraRTC not available after script load');
        }

        state.sdkLoaded = true;
        return true;
      } catch (err) {
        log('WARNING', `SDK load attempt ${i + 1} failed`, err.message);
        if (i === urls.length - 1) {
          log('ERROR', 'All SDK load attempts failed');
          return false;
        }
        await new Promise(r => setTimeout(r, 1000));
      }
    }

    return false;
  }

  // ========== TOKEN VALIDATION ==========
  function validateToken(token) {
    if (!token) {
      log('WARNING', 'Token is empty - joining in testing mode (no credential)');
      return true;
    }

    if (typeof token !== 'string') {
      log('ERROR', 'Token must be a string', { received: typeof token });
      return false;
    }

    // Agora tokens are base64 encoded, typically 100-400+ characters
    if (token.length < 100) {
      log('WARNING', 'Token looks suspiciously short - may be invalid', {
        length: token.length,
        first20chars: token.substring(0, 20) + '...'
      });
    }

    // Check token format (should be alphanumeric + = for base64)
    if (!/^[A-Za-z0-9+/=]+$/.test(token)) {
      log('ERROR', 'Token contains invalid characters');
      return false;
    }

    log('SUCCESS', 'Token validation passed', {
      length: token.length,
      preview: token.substring(0, 30) + '...'
    });
    return true;
  }

  // ========== CLIENT CREATION ==========
  async function createAndConfigureClient() {
    if (state.client) {
      log('DEBUG', 'Client already exists, returning');
      return state.client;
    }

    log('INFO', 'Creating Agora RTC client...');

    try {
      if (!window.AgoraRTC) {
        throw new Error('AgoraRTC SDK not available');
      }

      // Create client with VP8 codec — widest cross-browser support
      // (AV1 is not available on Safari; VP8 works on Chrome, Edge, Firefox, Safari)
      state.client = window.AgoraRTC.createClient({
        mode: 'rtc',
        codec: 'vp8',
      });

      // NOTE: Do not call setClientRole in rtc mode.
      // Agora Web SDK rejects this with INVALID_OPERATION, which causes a false join failure.
      log('SUCCESS', 'Agora client created and configured');

      // ---- REMOTE USER EVENT LISTENERS ----
      // Subscribe to incoming audio/video from other participants
      // and fire Flutter callbacks so the Dart UI can update.
      state.client.on('user-published', async (user, mediaType) => {
        log('INFO', `Remote user published uid=${user.uid} mediaType=${mediaType}`);
        state.remoteUsers.set(String(user.uid), user);
        try {
          await state.client.subscribe(user, mediaType);
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
        // Notify Flutter
        if (typeof window.agoraWeb.onRemoteUserUnpublished === 'function') {
          try { window.agoraWeb.onRemoteUserUnpublished({ uid: String(user.uid), mediaType }); } catch (_) {}
        }
      });

      state.client.on('user-left', (user) => {
        log('INFO', `Remote user left uid=${user.uid}`);
        state.remoteUsers.delete(String(user.uid));
        // Notify Flutter
        if (typeof window.agoraWeb.onRemoteUserLeft === 'function') {
          try { window.agoraWeb.onRemoteUserLeft({ uid: String(user.uid) }); } catch (_) {}
        }
      });
      // ---- END REMOTE USER LISTENERS ----

      return state.client;
    } catch (err) {
      log('ERROR', 'Failed to create client', {
        message: err.message,
        stack: err.stack
      });
      throw err;
    }
  }

  // ========== TRACK MANAGEMENT ==========
  async function createLocalTracks() {
    log('INFO', 'Creating local audio and video tracks...');

    try {
      if (state.localTracks.audio && state.localTracks.video) {
        log('DEBUG', 'Local tracks already exist');
        return true;
      }

      // Ensure permissions
      if (!await requestPermissions()) {
        log('ERROR', 'User denied permissions, cannot create tracks');
        return false;
      }

      // Create microphone audio track
      if (!state.localTracks.audio) {
        log('DEBUG', 'Creating microphone audio track...');
        state.localTracks.audio = await window.AgoraRTC.createMicrophoneAudioTrack({
          echoCancellation: true,
          noiseSuppression: true,
          autoGainControl: true,
        });
        log('SUCCESS', 'Microphone audio track created');
      }

      // Create camera video track
      if (!state.localTracks.video) {
        log('DEBUG', 'Creating camera video track...');
        state.localTracks.video = await window.AgoraRTC.createCameraVideoTrack({
          encoderConfig: '720p_auto'  // auto-select optimal resolution
        });
        log('SUCCESS', 'Camera video track created');
      }

      return true;
    } catch (err) {
      log('ERROR', 'Failed to create local tracks', {
        message: err.message,
        name: err.name
      });
      return false;
    }
  }

  // ========== CHANNEL JOIN ==========
  async function joinChannelWithRetry(appId, channelName, token, uid) {
    let lastError;

    for (let attempt = 1; attempt <= CONFIG.retry.max; attempt++) {
      try {
        log('INFO', `Join attempt ${attempt}/${CONFIG.retry.max}`, {
          channel: channelName,
          uid: uid,
          hasToken: !!token
        });

        if (state.isJoining) {
          log('WARNING', 'Already joining, waiting...');
          // Wait briefly
          await new Promise(r => setTimeout(r, 1000));
          continue;
        }

        state.isJoining = true;

        // Create client if needed
        await createAndConfigureClient();

        // Validate parameters
        if (!appId) throw new Error('appId is required');
        if (!channelName) throw new Error('channelName is required');
        if (!uid) throw new Error('uid is required');

        // Validate token if provided
        if (token && !validateToken(token)) {
          throw new Error('Token validation failed');
        }

        // Join the channel
        log('DEBUG', 'Calling client.join()...');
        const assignedUid = await Promise.race([
          state.client.join(appId, channelName, token || null, uid),
          new Promise((_, reject) =>
            setTimeout(() => reject(new Error('Join timeout')), CONFIG.timeout.join)
          )
        ]);

        log('SUCCESS', 'Successfully joined channel', {
          channel: channelName,
          assignedUid: assignedUid,
          requestedUid: uid
        });

        // Join should not auto-request media permissions or auto-publish.
        // Tracks are created/published only when the user explicitly toggles cam/mic.
        log('INFO', 'Joined as listener; awaiting explicit cam/mic enable actions');

        state.currentChannel = channelName;
        state.currentUid = uid;
        state.isJoining = false;

        return true;
      } catch (err) {
        lastError = err;
        state.isJoining = false;

        log('ERROR', `Join attempt ${attempt} failed`, {
          message: err.message,
          type: err.name || 'Unknown',
          willRetry: attempt < CONFIG.retry.max
        });

        if (attempt < CONFIG.retry.max) {
          log('INFO', `Retrying in ${CONFIG.retry.delay}ms...`);
          await new Promise(r => setTimeout(r, CONFIG.retry.delay));
        }
      }
    }

    log('ERROR', 'Failed to join after all retry attempts', lastError);
    return false;
  }

  // ========== PUBLIC API - FLUTTER CALLABLE ==========

  /**
   * Initialize Agora Web
   * @param {string} appId - Agora App ID
   * @returns {Promise<boolean>}
   */
  window.agoraWebInit = async function(appId) {
    log('INFO', 'agoraWebInit called', { appId: appId?.substring(0, 8) + '...' });

    if (state.initialized) {
      log('DEBUG', 'Already initialized, returning true');
      return true;
    }

    try {
      // Load SDK
      const sdkLoaded = await loadAgoraSDK();
      if (!sdkLoaded) {
        throw new Error('Failed to load Agora SDK');
      }

      state.initialized = true;
      log('SUCCESS', 'Agora Web initialized successfully');
      return true;
    } catch (err) {
      log('ERROR', 'Initialization failed', err);
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
  window.agoraWebJoinChannel = async function(appId, channelName, token, uid) {
    log('INFO', 'agoraWebJoinChannel called', {
      appId: appId?.substring(0, 8) + '...',
      channel: channelName,
      uid: uid,
      hasToken: !!token
    });

    if (!state.initialized) {
      log('WARNING', 'Join called before init; auto-initializing now');
      const initOk = await window.agoraWebInit(appId);
      if (!initOk) {
        log('ERROR', 'Auto-init failed before join');
        return false;
      }
    }

    if (!state.sdkLoaded) {
      log('WARNING', 'SDK not loaded, attempting to load now...');
      if (!await loadAgoraSDK()) {
        log('ERROR', 'Failed to load SDK');
        return false;
      }
    }

    return joinChannelWithRetry(appId, channelName, token, uid);
  };

  /**
   * Leave the channel
   * @returns {Promise<boolean>}
   */
  window.agoraWebLeaveChannel = async function() {
    log('INFO', 'agoraWebLeaveChannel called');

    try {
      if (state.client) {
        log('DEBUG', 'Unpublishing local tracks...');

        // Unpublish local tracks
        if (state.localTracks.audio || state.localTracks.video) {
          const tracks = [];
          if (state.localTracks.audio) tracks.push(state.localTracks.audio);
          if (state.localTracks.video) tracks.push(state.localTracks.video);

          if (tracks.length > 0) {
            await state.client.unpublish(tracks);
          }
        }

        log('DEBUG', 'Stopping local tracks...');

        // Stop local tracks
        if (state.localTracks.audio) {
          state.localTracks.audio.close();
          state.localTracks.audio = null;
        }
        if (state.localTracks.video) {
          state.localTracks.video.close();
          state.localTracks.video = null;
        }

        log('DEBUG', 'Leaving channel...');

        // Leave channel
        await state.client.leave();

        state.currentChannel = null;
        state.currentUid = null;

        log('SUCCESS', 'Left channel successfully');
      }
      return true;
    } catch (err) {
      log('ERROR', 'Failed to leave channel', err);
      return false;
    }
  };

  /**
   * Set microphone muted state
   * @param {boolean} muted - Whether to mute
   * @returns {Promise<boolean>}
   */
  window.agoraWebSetMicMuted = async function(muted) {
    log('DEBUG', `agoraWebSetMicMuted called (${muted ? 'muting' : 'unmuting'})`);

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
        log('SUCCESS', `Microphone ${muted ? 'muted' : 'unmuted'}`);
        return true;
      }
      return false;
    } catch (err) {
      log('ERROR', 'Failed to set mic mute state', err);
      return false;
    }
  };

  /**
   * Set video muted state
   * @param {boolean} muted - Whether to mute
   * @returns {Promise<boolean>}
   */
  window.agoraWebSetVideoMuted = async function(muted) {
    log('DEBUG', `agoraWebSetVideoMuted called (${muted ? 'disabling' : 'enabling'})`);

    try {
      if (!state.localTracks.video && muted === false) {
        log('INFO', 'No local video track while enabling video; creating and publishing now');
        state.localTracks.video = await window.AgoraRTC.createCameraVideoTrack({
          encoderConfig: '720p_auto'
        });
        log('SUCCESS', `Camera video track created uid=${state.currentUid}`);

        if (state.client && state.currentChannel) {
          await state.client.publish([state.localTracks.video]);
          log('SUCCESS', `client.publish() done — remote peers will receive user-published(video) uid=${state.currentUid}`);
        } else {
          log('WARNING', `client.publish skipped — client=${!!state.client} channel=${state.currentChannel}`);
        }
      }

      if (state.localTracks.video) {
        if (muted) {
          await state.localTracks.video.setMuted(true);
        } else {
          await state.localTracks.video.setMuted(false);
        }
        log('SUCCESS', `Video ${muted ? 'disabled' : 'enabled'}`);
        return true;
      }
      log('WARNING', 'agoraWebSetVideoMuted: no video track after all steps');
      return false;
    } catch (err) {
      log('ERROR', 'Failed to set video mute state', err);
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
  window.agoraWebGetState = function() {
    return {
      initialized: state.initialized,
      sdkLoaded: state.sdkLoaded,
      currentChannel: state.currentChannel,
      currentUid: state.currentUid,
      isJoining: state.isJoining,
      hasAudio: !!state.localTracks.audio,
      hasVideo: !!state.localTracks.video,
      remoteUserCount: state.remoteUsers.size,
      errorCount: state.errorLog.length,
      lastErrors: state.errorLog.slice(-5)
    };
  };

  // ========== WEB TAB VISIBILITY HANDLING ==========
  // When the user switches browser tabs, mute local tracks to prevent
  // continuous audio/video transmission from a background tab.
  // This mirrors the AppLifecycleState.paused handling on mobile.
  if (typeof document !== 'undefined') {
    document.addEventListener('visibilitychange', async function () {
      if (!state.currentChannel) return; // Not in a channel

      if (document.hidden) {
        log('INFO', 'Tab hidden — muting local tracks to save bandwidth');
        try {
          if (state.localTracks.audio) await state.localTracks.audio.setMuted(true);
          if (state.localTracks.video) await state.localTracks.video.setMuted(true);
        } catch (e) {
          log('WARNING', 'Failed to mute tracks on tab hidden', e.message);
        }
      } else {
        log('INFO', 'Tab visible — unmuting local tracks');
        try {
          // Only unmute if they were previously active; rely on Flutter state
          // for whether audio/video was actually enabled by the user.
          if (state.localTracks.audio) await state.localTracks.audio.setMuted(false);
          if (state.localTracks.video) await state.localTracks.video.setMuted(false);
        } catch (e) {
          log('WARNING', 'Failed to unmute tracks on tab visible', e.message);
        }
      }
    });
  }

  // ========== STARTUP ==========
  log('INFO', 'Agora Web v5 bridge loaded and ready');

  // Make available globally
  window.agoraWebDebug = function() {
    console.table(window.agoraWebGetState());
    console.table(state.errorLog.slice(-10));
  };

  log('SUCCESS', 'Agora Web production bridge initialized');

})(window);
