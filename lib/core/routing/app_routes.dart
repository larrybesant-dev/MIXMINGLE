import 'package:flutter/material.dart';
import 'package:mixmingle/app/auth_gate_root.dart';

/// Centralized route constants for MixVy.
/// Do NOT import UI widgets here.
class AppRoutes {
        static const matchDiscovery = '/match-discovery';
      static const terms = '/terms';
      static const privacy = '/privacy';
      static const matchPreferences = '/match-preferences';
    static const userProfile = '/user-profile';
    static const createStory = '/create-story';
    static const storyViewer = '/story-viewer';
    static const profileMedia = '/profile-media';
    static const reportUser = '/report-user';
    static const socialFeed = '/social-feed';
    static const suggestedUsers = '/suggested-users';
    static const trendingUsers = '/trending-users';
    static const activeNow = '/active-now';
    static const discoverRoomsLive = '/discover-rooms-live';
  static const landing = '/';
  static const ageGate = '/age-gate';
  static const login = '/login';
  static const signup = '/signup';
  static const onboarding = '/onboarding';
  static const profile = '/profile';
  static const chat = '/chat';
  static const rooms = '/rooms';
  static const matches = '/matches';
  static const editProfile = '/profile/edit';
  static const followers = '/followers';
  static const following = '/following';
  static const friends = '/friends';
  static const chats = '/chats';
  static const messageRequests = '/message-requests';
  static const room = '/room';
  static const liveRoom = '/live-room';
  static const createRoom = '/create-room';
  static const discoverRooms = '/discover-rooms';
  static const discovery = '/discovery';
  static const events = '/events';
  static const eventDetails = '/event-details';
  static const createShortVideo = '/create-video';
  static const settings = '/settings';
  static const accountSettings = '/settings/account';
  static const privacySettings = '/settings/privacy';
  static const notificationSettings = '/settings/notifications';
  static const blockedUsers = '/settings/blocked';

  // SYSTEM
  static const notifications = '/notifications'; // New route
  static const coins = '/coins'; // New route

  // ADMIN
  static const adminDashboard = '/admin'; // New route

  // TESTING
  static const agoraTest = '/agora-test'; // New route
  static const routeTest = '/route-test'; // New route

  // SYSTEM
  static const app = '/app'; // Added missing route
  static Route<dynamic> onGenerateRoute(RouteSettings settings) => onGenerateRouteImpl(settings);
  static Route<dynamic> onGenerateRouteImpl(RouteSettings settings) {
    // Only route strings here. UI mapping is handled in app_router.dart.
    switch (settings.name) {
      case AppRoutes.home:
      case AppRoutes.login:
      case AppRoutes.chat:
      case AppRoutes.messageRequests:
      case AppRoutes.userProfile:
      case AppRoutes.signup:
      case AppRoutes.landing:
      case AppRoutes.discovery:
      case AppRoutes.friends:
      case AppRoutes.notifications:
      case AppRoutes.events:
      case AppRoutes.eventDetails:
      case AppRoutes.coins:
      case AppRoutes.accountSettings:
      case AppRoutes.privacySettings:
      case AppRoutes.notificationSettings:
      case AppRoutes.blockedUsers:
      case AppRoutes.routeTest:
      case AppRoutes.onboarding:
      case AppRoutes.matches:
      case AppRoutes.discoverRooms:
      case AppRoutes.createShortVideo:
      case AppRoutes.agoraTest:
      case AppRoutes.app:
        return MaterialPageRoute(
          builder: (_) => const AuthGateRoot(),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Route not found')),
          ),
        );
    }
  }
  static const home = '/';
}

/// Centralized route generator stub (UI mapping handled in app_router.dart).
Route<dynamic> onGenerateRoute(RouteSettings settings) {
  // Only route strings here. UI mapping is handled in app_router.dart.
  switch (settings.name) {
    case AppRoutes.home:
    case AppRoutes.login:
    case AppRoutes.chat:
    case AppRoutes.messageRequests:
    case AppRoutes.userProfile:
    case AppRoutes.signup:
    case AppRoutes.landing:
    case AppRoutes.discovery:
    case AppRoutes.friends:
    case AppRoutes.notifications:
    case AppRoutes.events:
    case AppRoutes.eventDetails:
    case AppRoutes.coins:
      case AppRoutes.accountSettings:
      case AppRoutes.privacySettings:
      case AppRoutes.notificationSettings:
      case AppRoutes.blockedUsers:
      case AppRoutes.routeTest:
      // providerDebug is not defined in AppRoutes, remove or add if needed
      case AppRoutes.onboarding:
      case AppRoutes.matches:
      case AppRoutes.discoverRooms:
      // discoverRoomsLive, suggestedUsers, trendingUsers, activeNow, storyViewer, createStory, reportUser, profileMedia, socialFeed are not defined in AppRoutes, add if needed
      case AppRoutes.createShortVideo:
      case AppRoutes.agoraTest:
      case AppRoutes.app:
        // Map '/app' to the main authenticated app shell
        return MaterialPageRoute(
          builder: (_) => const AuthGateRoot(),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Route not found')),
          ),
        );
    }
  }
