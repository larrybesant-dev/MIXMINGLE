import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mixmingle/core/routing/app_routes.dart';

/// DeepLinkService initializes app_links and routes incoming URIs to the
/// correct screens using the app's Navigator key.
///
/// Supported deep link paths:
///   /user/{id}   → AppRoutes.userProfile
///   /room/{id}   → AppRoutes.liveRoom
///   /event/{id}  → AppRoutes.eventDetails
///   /post/{id}   → AppRoutes.socialFeed  (navigates to feed, highlighting post)
///
/// Register your scheme/host in:
///   Android: android/app/src/main/AndroidManifest.xml
///   iOS:     ios/Runner/Info.plist + Associated Domains entitlement
class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();
  static DeepLinkService get instance => _instance;

  AppLinks? _appLinks;
  StreamSubscription<Uri>? _sub;
  GlobalKey<NavigatorState>? _navigatorKey;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  /// Call once from main.dart or app startup with your app's NavigatorKey.
  /// This handles both cold-start links and foreground deep links.
  Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
    if (kIsWeb) return; // Deep links handled by URL in browser
    _navigatorKey = navigatorKey;
    _appLinks = AppLinks();

    // Handle cold-start deep link
    try {
      final initialLink = await _appLinks!.getInitialLink();
      if (initialLink != null) {
        debugPrint('🔗 [DeepLink] Cold-start link: $initialLink');
        // Post-frame so the widget tree is ready
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _route(initialLink);
        });
      }
    } catch (e) {
      debugPrint('❌ [DeepLink] getInitialLink error: $e');
    }

    // Handle foreground / background-to-foreground links
    _sub = _appLinks!.uriLinkStream.listen(
      (uri) {
        debugPrint('🔗 [DeepLink] Foreground link: $uri');
        _route(uri);
      },
      onError: (e) => debugPrint('❌ [DeepLink] stream error: $e'),
    );
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }

  // ── Routing ────────────────────────────────────────────────────────────────

  void _route(Uri uri) {
    final nav = _navigatorKey?.currentState;
    if (nav == null) return;

    final segments = uri.pathSegments;
    if (segments.isEmpty) return;

    switch (segments[0]) {
      case 'user':
        final userId = segments.length > 1 ? segments[1] : null;
        if (userId != null && userId.isNotEmpty) {
          nav.pushNamed(AppRoutes.userProfile, arguments: userId);
        }
      case 'room':
        final roomId = segments.length > 1 ? segments[1] : null;
        if (roomId != null && roomId.isNotEmpty) {
          nav.pushNamed(AppRoutes.liveRoom, arguments: roomId);
        }
      case 'event':
        final eventId = segments.length > 1 ? segments[1] : null;
        if (eventId != null && eventId.isNotEmpty) {
          nav.pushNamed(AppRoutes.eventDetails, arguments: eventId);
        }
      case 'post':
        // Navigate to home feed; individual post detail can be added later
        nav.pushNamed(AppRoutes.home);
      default:
        debugPrint('🔗 [DeepLink] Unknown path: ${uri.path}');
    }
  }

  // ── Link builders ──────────────────────────────────────────────────────────
  // Call these to build shareable links for share_plus.

  /// Build a shareable user profile link.
  static Uri userLink(String userId) =>
      Uri.https('mixmingle.app', '/user/$userId');

  /// Build a shareable room link.
  static Uri roomLink(String roomId) =>
      Uri.https('mixmingle.app', '/room/$roomId');

  /// Build a shareable event link.
  static Uri eventLink(String eventId) =>
      Uri.https('mixmingle.app', '/event/$eventId');

  /// Build a shareable post link.
  static Uri postLink(String postId) =>
      Uri.https('mixmingle.app', '/post/$postId');
}
