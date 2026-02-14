# 100ms Video Integration for Web

This project uses a custom build process to integrate the 100ms JavaScript SDK with Flutter Web.

## Architecture

- **Mobile (Android/iOS)**: Uses `hmssdk_flutter` package
- **Web**: Uses `@100mslive/hms-video-store` via bundled JavaScript

## Web Setup

The `web_modules/` directory contains:
- `package.json` - NPM dependencies including 100ms SDK
- `hms-setup.js` - JavaScript that initializes 100ms and exposes it globally
- `vite.config.js` - Vite bundler configuration

## Building for Web

1. **Build the JavaScript bundle** (only needed when updating 100ms or changing hms-setup.js):
   ```bash
   cd web_modules
   npm install
   npm run build
   ```
   This creates `web/hms-bundle.iife.js`

2. **Build Flutter web**:
   ```bash
   flutter build web --release
   ```

3. **Deploy**:
   ```bash
   firebase deploy --only hosting
   ```

## How It Works

1. Vite bundles `@100mslive/hms-video-store` into a single `hms-bundle.iife.js` file
2. This bundle exposes `window.hmsStore` and `window.hmsActions` globals
3. Flutter's `hms_video_service_web.dart` uses `dart:js_interop` to call these JavaScript APIs
4. The same Cloud Function (`generate100msToken`) works for both mobile and web

## Development

To watch for changes and auto-rebuild the bundle:
```bash
cd web_modules
npm run dev
```

Then in another terminal:
```bash
flutter run -d chrome
```

## Files

- `web_modules/hms-setup.js` - Initializes 100ms SDK
- `web/index.html` - Loads the bundled script
- `lib/services/hms_video_service_web.dart` - Dart wrapper for JS SDK
- `lib/services/hms_video_service.dart` - Platform-agnostic service

## Updating 100ms SDK

To update to a newer version:
```bash
cd web_modules
npm update @100mslive/hms-video-store
npm run build
```

Then rebuild and redeploy Flutter web.
