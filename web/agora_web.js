// Agora Web SDK Helper for Flutter Web
// Handles Web-specific Agora initialization and channel joining

let agoraClient = null;
let localTracks = {
  videoTrack: null,
  audioTrack: null
};

// Track media state per remote user to prevent ghost users
// Maps uid → { hasVideo: bool, hasAudio: bool }
let remoteUserMediaState = new Map();

// Initialize Agora for Web
window.initializeAgoraWeb = async function (appId) {
  console.log('🎬 Initializing Agora Web SDK...', appId);

  // Create Agora client
  agoraClient = AgoraRTC.createClient({ mode: "live", codec: "vp8" });

  // Set client role to host (broadcaster)
  await agoraClient.setClientRole("host");

  console.log('✅ Agora Web client created');
  return true;
};

// Join channel with token
window.joinAgoraChannel = async function (token, channelName, uid) {
  if (!agoraClient) {
    throw new Error('Agora client not initialized');
  }

  console.log('🔗 Joining Agora channel:', channelName);

  try {
    // Join the channel
    const assignedUid = await agoraClient.join(null, channelName, token, uid || null);
    console.log('✅ Joined channel with UID:', assignedUid);

    // Create local audio and video tracks
    console.log('🎤 Creating local tracks...');
    localTracks.audioTrack = await AgoraRTC.createMicrophoneAudioTrack();
    localTracks.videoTrack = await AgoraRTC.createCameraVideoTrack();

    // Publish local tracks
    console.log('📡 Publishing local tracks...');
    await agoraClient.publish([localTracks.audioTrack, localTracks.videoTrack]);

    console.log('✅ Local tracks published');

    // Play local video
    if (localTracks.videoTrack) {
      const localContainer = document.getElementById('local-video');
      if (localContainer) {
        localTracks.videoTrack.play(localContainer);
      }
    }

    // Listen for remote users - with deduplication and proper media state tracking
    agoraClient.on("user-published", async (user, mediaType) => {
      console.log('👤 Remote user published:', user.uid, mediaType);

      try {
        // Get or create media state for this user
        let mediaState = remoteUserMediaState.get(user.uid);
        if (!mediaState) {
          mediaState = { hasVideo: false, hasAudio: false };
          remoteUserMediaState.set(user.uid, mediaState);
        }

        // Update media state based on type
        if (mediaType === "video") {
          mediaState.hasVideo = true;
        } else if (mediaType === "audio") {
          mediaState.hasAudio = true;
        }

        // Only notify Flutter if this is a NEW user (both tracks were false before)
        const isNewUser = (!mediaState.hasVideo && !mediaState.hasAudio) ||
                         (mediaType === "video" && !mediaState.hasVideo) ||
                         (mediaType === "audio" && !mediaState.hasAudio);

        // Subscribe to the media (safe to call multiple times)
        await agoraClient.subscribe(user, mediaType);

        // Play the media
        if (mediaType === "video" && user.videoTrack) {
          const remoteContainer = document.getElementById(`remote-video-${user.uid}`);
          if (remoteContainer) {
            user.videoTrack.play(remoteContainer);
          }
        } else if (mediaType === "audio" && user.audioTrack) {
          user.audioTrack.play();
        }

        // Notify Flutter ONLY for initial join
        if (isNewUser && window.onAgoraUserPublished) {
          window.onAgoraUserPublished({
            uid: user.uid,
            mediaType: mediaType,
            hasVideo: mediaState.hasVideo,
            hasAudio: mediaState.hasAudio
          });
        }
      } catch (error) {
        console.error('❌ Error handling user-published:', error);
      }
    });

    agoraClient.on("user-unpublished", (user, mediaType) => {
      console.log('👤 Remote user unpublished:', user.uid, mediaType);

      try {
        // Get media state for this user
        let mediaState = remoteUserMediaState.get(user.uid);
        if (!mediaState) {
          // User not tracked, ignore
          return;
        }

        // Update media state based on type
        if (mediaType === "video") {
          mediaState.hasVideo = false;
        } else if (mediaType === "audio") {
          mediaState.hasAudio = false;
        }

        // Only notify Flutter if ALL tracks are now gone
        const hasAnyMedia = mediaState.hasVideo || mediaState.hasAudio;
        if (!hasAnyMedia) {
          // User is completely gone
          remoteUserMediaState.delete(user.uid);

          if (window.onAgoraUserUnpublished) {
            window.onAgoraUserUnpublished({
              uid: user.uid,
              mediaType: mediaType
            });
          }
        }
      } catch (error) {
        console.error('❌ Error handling user-unpublished:', error);
      }
    });

    // Handle user left event (most reliable way to detect total disconnect)
    agoraClient.on("user-left", (user) => {
      console.log('👤 User completely left:', user.uid);

      try {
        // Force-remove this user from our tracking
        remoteUserMediaState.delete(user.uid);

        if (window.onAgoraUserLeft) {
          window.onAgoraUserLeft({
            uid: user.uid
          });
        }
      } catch (error) {
        console.error('❌ Error handling user-left:', error);
      }
    });

    return assignedUid;
  } catch (error) {
    console.error('❌ Failed to join channel:', error);
    throw error;
  }
};

// Leave channel
window.leaveAgoraChannel = async function () {
  console.log('👋 Leaving Agora channel...');

  // Close local tracks
  if (localTracks.audioTrack) {
    localTracks.audioTrack.close();
    localTracks.audioTrack = null;
  }

  if (localTracks.videoTrack) {
    localTracks.videoTrack.close();
    localTracks.videoTrack = null;
  }

  // Leave channel
  if (agoraClient) {
    await agoraClient.leave();
  }

  // Clear remote user tracking
  remoteUserMediaState.clear();

  console.log('✅ Left channel');
};

// Toggle mic
window.toggleAgoraMic = function (muted) {
  if (localTracks.audioTrack) {
    localTracks.audioTrack.setEnabled(!muted);
  }
};

// Toggle camera
window.toggleAgoraCamera = function (muted) {
  if (localTracks.videoTrack) {
    localTracks.videoTrack.setEnabled(!muted);
  }
};

// ============================================================================
// SPRINT 2: HOST CONTROLS - MUTE REMOTE AUDIO
// ============================================================================

// Mute/unmute remote user's audio
window.muteRemoteAudio = async function (remoteUid, muted) {
  if (!agoraClient) {
    console.error('❌ Agora client not initialized');
    return false;
  }

  try {
    // Get the remote user
    const user = agoraClient.remoteUsers.find(u => u.uid === remoteUid);
    if (!user || !user.audioTrack) {
      console.warn('❌ Remote user audio track not found for UID:', remoteUid);
      return false;
    }

    // Mute/unmute the remote audio track
    user.audioTrack.setEnabled(!muted);

    console.log(muted ? '🔇 Remote audio muted: UID=' + remoteUid : '🔊 Remote audio unmuted: UID=' + remoteUid);
    return true;
  } catch (error) {
    console.error('❌ Failed to mute remote audio:', error);
    return false;
  }
};
