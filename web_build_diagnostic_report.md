# Flutter Web Build Diagnostic Report

Generated: 2026-02-13 21:13:32

## Summary

- **Blocking Errors**: 17
- **Warnings**: 11

## Errors

- ❌ lib\core\errors\app_error.dart uses dart:io (not supported on web)
- ❌ lib\core\launch\launch_build_service.dart uses dart:io (not supported on web)
- ❌ lib\core\multiplatform\platform_adapter.dart uses dart:io (not supported on web)
- ❌ lib\core\providers\connectivity_provider.dart uses dart:io (not supported on web)
- ❌ lib\core\services\push_notification_service.dart uses dart:io (not supported on web)
- ❌ lib\features\chat_room_page.dart uses dart:io (not supported on web)
- ❌ lib\features\create_event_page.dart uses dart:io (not supported on web)
- ❌ lib\features\app\screens\profile_edit_page.dart uses dart:io (not supported on web)
- ❌ lib\features\onboarding\screens\onboarding_page.dart uses dart:io (not supported on web)
- ❌ lib\features\onboarding\screens\profile_setup_screen.dart uses dart:io (not supported on web)
- ❌ lib\providers\video_media_providers.dart uses dart:io (not supported on web)
- ❌ lib\services\file_share_service.dart uses dart:io (not supported on web)
- ❌ lib\services\image_optimization_service.dart uses dart:io (not supported on web)
- ❌ lib\services\photo_upload_service.dart uses dart:io (not supported on web)
- ❌ lib\services\storage_service.dart uses dart:io (not supported on web)
- ❌ Code imports 'provider' but it's not in pubspec.yaml
- ❌ Code imports 'firebase_performance' but it's not in pubspec.yaml

## Warnings

- ⚠️ lib\core\launch\launch_build_service.dart uses Platform without kIsWeb guard
- ⚠️ lib\features\payments\services\revenuecat_service.dart uses Platform without kIsWeb guard
- ⚠️ lib\features\payments\services\revenuecat_service.dart uses Platform without kIsWeb guard
- ⚠️ flutter_local_notifications - Not supported on web
- ⚠️ image_picker - Uses web-specific plugin
- ⚠️ permission_handler - Limited/no web support
- ⚠️ agora_rtc_engine - Requires separate web SDK initialization
- ⚠️ path_provider - Limited web support
- ⚠️ image_cropper - Limited web support
- ⚠️ firebase_messaging - Requires web-specific setup
- ⚠️ file_picker - Uses web-specific implementation

## Dependencies in pubspec.yaml

flutter, sdk, firebase_core, firebase_auth, cloud_firestore, firebase_storage, firebase_messaging, firebase_analytics, firebase_remote_config, firebase_crashlytics, flutter_local_notifications, cloud_functions, flutter_riverpod, agora_rtc_engine, permission_handler, cupertino_icons, google_fonts, photo_view, lottie, intl, timeago, url_launcher, uuid, share_plus, path_provider, shared_preferences, image_picker, image_cropper, file_picker, image, google_sign_in, sign_in_with_apple, flutter_dotenv, web
