# Agora Video Integration Guide

## Setup Complete! ✅

Your Agora App ID: `ec1b578586d24976a89d787d9ee4d5c7`

## Quick Start

### 1. Run Setup Script

```powershell
.\setup-agora.ps1
```

This will:
- Install `agora-access-token` npm package
- Configure Firestore with your App ID and Certificate
- Prepare Firebase Functions

### 2. Deploy Firebase Functions

```powershell
firebase deploy --only functions
```

### 3. Test Video Calling

The app is now ready for video calls!

## Manual Configuration (Alternative)

If you prefer manual setup:

### A. Add to Firestore

Create document: `config/agora`

```json
{
  "appId": "ec1b578586d24976a89d787d9ee4d5c7",
  "appCertificate": "YOUR_32_CHAR_CERTIFICATE"
}
```

### B. Install Dependencies

```bash
cd functions
npm install agora-access-token
```

### C. Export Function

Add to `functions/src/index.ts`:

```typescript
export { generateAgoraToken } from './agora';
```

## Features

### AgoraVideoService provides:

- ✅ Initialize/Join/Leave rooms
- ✅ Toggle audio/video mute
- ✅ Switch camera
- ✅ Remote user tracking
- ✅ High-quality music audio (perfect for karaoke!)
- ✅ **Full Flutter Web support**

### Usage Example:

```dart
final agoraService = AgoraVideoService();

// Initialize
await agoraService.initialize();

// Join room
await agoraService.joinRoom('room-id-123');

// Toggle audio/video
await agoraService.toggleMic();
await agoraService.toggleVideo();

// Leave room
await agoraService.leaveRoom();
```

## Get Agora App Certificate

1. Visit: https://console.agora.io/
2. Sign in
3. Select your project
4. Click "Configure"
5. Find "Primary Certificate" under Features
6. Copy the 32-character hex string

## Agora Free Tier

- **10,000 minutes/month** free
- Perfect for testing and small apps
- See: https://www.agora.io/en/pricing/

## Why Agora?

- ✅ Native Flutter Web support
- ✅ Production-grade (used by Clubhouse, Discord)
- ✅ Superior audio quality for music
- ✅ Stable and reliable
- ✅ Great documentation

## Support

- Agora Docs: https://docs.agora.io/en/
- Flutter SDK: https://docs.agora.io/en/video-calling/get-started/get-started-sdk?platform=flutter

---

**Migration from 100ms complete!** 🎉
