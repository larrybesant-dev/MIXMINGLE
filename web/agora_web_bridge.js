(function (window) {
  'use strict';

  const PRIMARY_BRIDGE_SRC = 'agora_web_v5_production.js';
  const LEGACY_BRIDGE_SRC = 'agora_bridge.js';
  let bridgeLoadPromise = null;

  function isFn(value) {
    return typeof value === 'function';
  }

  function isNativeFlat(name) {
    const fn = window[name];
    return isFn(fn) && fn.__agoraWrapperAlias !== true;
  }

  function hasFlatApi() {
    return (
      isNativeFlat('agoraWebInit') &&
      isNativeFlat('agoraWebJoinChannel') &&
      isNativeFlat('agoraWebLeaveChannel') &&
      isNativeFlat('agoraWebSetMicMuted') &&
      isNativeFlat('agoraWebSetVideoMuted') &&
      isNativeFlat('agoraWebGetState')
    );
  }

  function hasLegacyObjectApi() {
    return (
      window.agoraWebBridge &&
      isFn(window.agoraWebBridge.init) &&
      isFn(window.agoraWebBridge.joinChannel) &&
      isFn(window.agoraWebBridge.leaveChannel)
    );
  }

  function syncPublicState() {
    const state = window.agoraWeb.getState();
    const bridgeState = window.agoraBridgeState || {};

    window.agoraWeb.client = bridgeState.client || null;
    window.agoraWeb.initialized = !!state.initialized;
    window.agoraWeb.sdkLoaded = !!window.AgoraRTC || !!state.sdkLoaded;
  }

  function loadScript(src) {
    return new Promise((resolve) => {
      const existing = document.querySelector('script[src="' + src + '"]');
      if (existing) {
        // If already loaded by index.html (or previously injected), proceed.
        if (existing.dataset.loaded === 'true') {
          resolve(true);
          return;
        }

        existing.addEventListener('load', function () {
          existing.dataset.loaded = 'true';
          resolve(true);
        }, { once: true });
        existing.addEventListener('error', function () {
          resolve(false);
        }, { once: true });
        return;
      }

      const script = document.createElement('script');
      script.src = src;
      script.async = true;
      script.onload = function () {
        script.dataset.loaded = 'true';
        resolve(true);
      };
      script.onerror = function () {
        resolve(false);
      };
      document.head.appendChild(script);
    });
  }

  function loadBridgeScripts() {
    if (hasFlatApi() || hasLegacyObjectApi()) {
      return Promise.resolve(true);
    }

    if (bridgeLoadPromise) {
      return bridgeLoadPromise;
    }

    bridgeLoadPromise = (async function () {
      // Try production bridge first.
      const primaryLoaded = await loadScript(PRIMARY_BRIDGE_SRC);
      if (primaryLoaded && hasFlatApi()) {
        return true;
      }

      // Fall back to legacy object bridge.
      const legacyLoaded = await loadScript(LEGACY_BRIDGE_SRC);
      return legacyLoaded && (hasFlatApi() || hasLegacyObjectApi());
    })();

    return bridgeLoadPromise;
  }

  async function invokeBridgeMethod(methodName, args) {
    // Object API first.
    if (window.agoraWebBridge && isFn(window.agoraWebBridge[methodName])) {
      return window.agoraWebBridge[methodName].apply(window.agoraWebBridge, args || []);
    }

    // Flat API fallback.
    const flatName = {
      init: 'agoraWebInit',
      joinChannel: 'agoraWebJoinChannel',
      leaveChannel: 'agoraWebLeaveChannel',
      setMicMuted: 'agoraWebSetMicMuted',
      setVideoMuted: 'agoraWebSetVideoMuted',
      playCamera: 'agoraWebPlayCamera',
      getState: 'agoraWebGetState',
    }[methodName];

    const flatFn = flatName ? window[flatName] : null;
    if (isFn(flatFn)) {
      if (flatFn.__agoraWrapperAlias === true) {
        throw new Error('Bridge alias invoked before native method is ready: ' + flatName);
      }
      return flatFn.apply(window, args || []);
    }

    throw new Error('Agora bridge method unavailable: ' + methodName);
  }

  async function getBridge() {
    const loaded = await loadBridgeScripts();
    if (!loaded) {
      throw new Error(
        'Failed to load Agora bridge dependencies: ' +
        PRIMARY_BRIDGE_SRC + ' or ' + LEGACY_BRIDGE_SRC
      );
    }

    return {
      init: function (appId) {
        return invokeBridgeMethod('init', [appId]);
      },
      joinChannel: function (appId, channelName, token, uid) {
        // Legacy bridge takes (token, channelName, uid).
        if (window.agoraWebBridge && isFn(window.agoraWebBridge.joinChannel)) {
          return window.agoraWebBridge.joinChannel(token, channelName, uid);
        }
        return invokeBridgeMethod('joinChannel', [appId, channelName, token, uid]);
      },
      leaveChannel: function () {
        return invokeBridgeMethod('leaveChannel', []);
      },
      setMicMuted: function (muted) {
        return invokeBridgeMethod('setMicMuted', [muted]);
      },
      setVideoMuted: function (muted) {
        return invokeBridgeMethod('setVideoMuted', [muted]);
      },
      playCamera: function (videoElementId) {
        return invokeBridgeMethod('playCamera', [videoElementId]);
      },
      getState: function () {
        return invokeBridgeMethod('getState', []);
      },
    };
  }

  window.agoraWeb = window.agoraWeb || {
    client: null,
    initialized: false,
    sdkLoaded: false,
  };

  window.agoraWeb.init = async function (appId) {
    try {
      const bridge = await getBridge();
      const ok = await bridge.init(appId);
      syncPublicState();
      return !!ok;
    } catch (error) {
      console.error('[agora_web_bridge] init failed', error);
      return false;
    }
  };

  window.agoraWeb.joinChannel = async function (appId, channelName, token, uid) {
    try {
      if (!window.agoraWeb.initialized) {
        const initOk = await window.agoraWeb.init(appId);
        if (!initOk) {
          return false;
        }
      }

      const bridge = await getBridge();
      const ok = await bridge.joinChannel(appId, channelName, token, uid);
      syncPublicState();
      return !!ok;
    } catch (error) {
      console.error('[agora_web_bridge] joinChannel failed', error);
      return false;
    }
  };

  window.agoraWeb.leaveChannel = async function () {
    try {
      const bridge = await getBridge();
      const ok = await bridge.leaveChannel();
      syncPublicState();
      return !!ok;
    } catch (error) {
      console.error('[agora_web_bridge] leaveChannel failed', error);
      return false;
    }
  };

  window.agoraWeb.setMicMuted = async function (muted) {
    try {
      const bridge = await getBridge();
      return !!(await bridge.setMicMuted(muted));
    } catch (error) {
      console.error('[agora_web_bridge] setMicMuted failed', error);
      return false;
    }
  };

  window.agoraWeb.setVideoMuted = async function (muted) {
    try {
      const bridge = await getBridge();
      return !!(await bridge.setVideoMuted(muted));
    } catch (error) {
      console.error('[agora_web_bridge] setVideoMuted failed', error);
      return false;
    }
  };

  window.agoraWeb.playCamera = async function (videoElementId) {
    try {
      const bridge = await getBridge();
      return !!(await bridge.playCamera(videoElementId));
    } catch (error) {
      console.error('[agora_web_bridge] playCamera failed', error);
      return false;
    }
  };

  // Expose playRemoteVideo on window.agoraWeb so the Dart bridge
  // (_invokeBridgeMethod objectMethod path) can reach it without falling
  // through to the flat agoraWebPlayRemoteVideo alias.
  window.agoraWeb.playRemoteVideo = async function (uidStr, videoElementId) {
    const flatFn = window['agoraWebPlayRemoteVideo'];
    if (typeof flatFn === 'function' && flatFn.__agoraWrapperAlias !== true) {
      return flatFn(uidStr, videoElementId);
    }
    // v5 bridge not yet loaded — attempt lazy load then retry once
    try {
      const bridge = await getBridge();
      void bridge; // ensure scripts loaded
      const fn = window['agoraWebPlayRemoteVideo'];
      if (typeof fn === 'function') return fn(uidStr, videoElementId);
    } catch (_) {}
    return false;
  };

  window.agoraWeb.getState = function () {
    if (window.agoraWebBridge && isFn(window.agoraWebBridge.getState)) {
      return window.agoraWebBridge.getState();
    }

    if (isNativeFlat('agoraWebGetState')) {
      return window.agoraWebGetState();
    }

    return {
      initialized: !!window.agoraWeb.initialized,
      sdkLoaded: !!window.agoraWeb.sdkLoaded,
      inChannel: false,
      currentChannel: null,
      currentUid: null,
      hasAudio: false,
      hasVideo: false,
      audioMuted: true,
      videoMuted: true,
    };
  };

  // Flat API retained for existing Dart JS interop calls.
  // Backward-compatible object API aliases expected by legacy callers.
  window.agoraWeb.initClient = function (appId) {
    return window.agoraWeb.init(appId);
  };

  window.agoraWeb.setAudioMuted = function (muted) {
    return window.agoraWeb.setMicMuted(muted);
  };

  window.agoraWeb.getClientState = function () {
    return window.agoraWeb.getState();
  };

  // Keep flat aliases only when they are missing to avoid replacing native bridge functions.
  if (!isFn(window.agoraWebInit)) {
    const alias = function (appId) {
      return window.agoraWeb.init(appId);
    };
    alias.__agoraWrapperAlias = true;
    window.agoraWebInit = alias;
  }

  if (!isFn(window.agoraWebJoinChannel)) {
    const alias = function (appId, channelName, token, uid) {
      return window.agoraWeb.joinChannel(appId, channelName, token, uid);
    };
    alias.__agoraWrapperAlias = true;
    window.agoraWebJoinChannel = alias;
  }

  if (!isFn(window.agoraWebLeaveChannel)) {
    const alias = function () {
      return window.agoraWeb.leaveChannel();
    };
    alias.__agoraWrapperAlias = true;
    window.agoraWebLeaveChannel = alias;
  }

  if (!isFn(window.agoraWebSetMicMuted)) {
    const alias = function (muted) {
      return window.agoraWeb.setMicMuted(muted);
    };
    alias.__agoraWrapperAlias = true;
    window.agoraWebSetMicMuted = alias;
  }

  if (!isFn(window.agoraWebSetVideoMuted)) {
    const alias = function (muted) {
      return window.agoraWeb.setVideoMuted(muted);
    };
    alias.__agoraWrapperAlias = true;
    window.agoraWebSetVideoMuted = alias;
  }

  if (!isFn(window.agoraWebPlayCamera)) {
    const alias = function (videoElementId) {
      return window.agoraWeb.playCamera(videoElementId);
    };
    alias.__agoraWrapperAlias = true;
    window.agoraWebPlayCamera = alias;
  }

  if (!isFn(window.agoraWebGetState)) {
    const alias = function () {
      return window.agoraWeb.getState();
    };
    alias.__agoraWrapperAlias = true;
    window.agoraWebGetState = alias;
  }

  syncPublicState();
})(window);
