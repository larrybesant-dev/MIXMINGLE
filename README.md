# MixVy

MixVy is a Flutter social/live-room app with Firebase, Riverpod, payments, moderation, and web support.

## Prerequisites
- Flutter SDK (stable)
- Dart SDK (bundled with Flutter)
- Firebase project configured for Auth, Firestore, Functions, Storage
- Node.js 22 (for Firebase Functions)

## Local Setup
1. Install dependencies:
	- flutter pub get
2. Install function dependencies:
	- cd functions && npm install
3. Align the local Functions runtime version before using npm or Firebase Functions commands:
	- use Node 22 in `functions/` (`.nvmrc` and `.node-version` are provided)
4. Ensure required environment values are available for runtime:
	- FIREBASE_API_KEY_WEB
	- FIREBASE_API_KEY_WINDOWS
	- AGORA_APP_ID (if using live A/V)
	- STRIPE keys and function env vars for payment features

## Running the App
- Mobile/Desktop:
  - flutter run
- Web (Chrome):
  - flutter run -d chrome

## Web Build and Deploy Workflow
1. Build release web:
	- flutter build web --release --base-href "/"
2. Optional runtime compatibility patch:
	- powershell -ExecutionPolicy Bypass -File tools/patch_flutter_web_runtime.ps1
3. Deploy hosting:
	- firebase deploy --only hosting

## Web Stability Notes
- Hosting rewrites are configured in firebase.json to route all paths to /index.html.
- Entry boot script is now stable and no longer force-clears browser caches every load.
- Cache-control headers are configured for index/bootstrap/service worker in firebase.json.

## Tests
Run focused tests:
- flutter test test/app_router_redirect_test.dart
- flutter test test/room_service_test.dart

Run full suite:
- flutter test

## Key Project Docs
- MIXVY_PRODUCT_AUDIT_2026-03-29.md
- MIXVY_AUDIT_SUMMARY.md
- ONBOARDING.md

## Current Product Audit Direction
- Apple Sign In is intentionally deferred until web behavior is validated and stable in production.
- Current priority is web reliability, safety hardening, and account-control completion.
