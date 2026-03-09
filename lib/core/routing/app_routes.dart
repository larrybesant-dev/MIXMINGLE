
/// Centralized route constants for MixVy.
/// Do NOT import UI widgets here.
import 'package:flutter/material.dart';

class AppRoutes {
  static const landing = '/';
  static const ageGate = '/age-gate';
  static const login = '/login';
  static const signup = '/signup';
  static const forgotPassword = '/forgot-password';
  static const home = '/home';
  static const discovery = '/discovery';
  static const userProfile = '/profile';
  static const editProfile = '/profile/edit';
  static const followers = '/followers';
  static const following = '/following';
  static const friends = '/friends';
  static const friendRequests = '/profile/friend-requests';
  static const chats = '/chats';
  static const chat = '/chat';
  static const chatList = '/chat-list';
  static const messageRequests = '/message-requests';
  static const rooms = '/rooms';
  static const room = '/room';
  static const liveRoom = '/room/live';
  static const createRoom = '/rooms/create';
  static const settings = '/settings';
  static const accountSettings = '/settings/account';
  static const privacySettings = '/settings/privacy';
  static const notificationSettings = '/settings/notifications';
  static const blockedUsers = '/blocked-users';
  static const notifications = '/notifications';
  static const events = '/events';
  static const eventDetails = '/events/details';
  static const coins = '/coins';
  static const adminDashboard = '/admin/dashboard';
  static const routeTest = '/dev/routes';
  static const providerDebug = '/dev/providers';
  static const onboarding = '/onboarding';
  static const matches = '/matches';
  static const discoverRooms = '/discover-rooms';
  static const discoverRoomsLive = '/discover-rooms-live';
  static const suggestedUsers = '/suggested-users';
  static const trendingUsers = '/trending-users';
  static const activeNow = '/active-now';
  static const createShortVideo = '/create-short-video';
  static const storyViewer = '/story-viewer';
  static const createStory = '/create-story';
  static const reportUser = '/report-user';
  static const profileMedia = '/profile/media';
  static const socialFeed = '/feed';
  static const agoraTest = '/agora-test';
  static const app = '/app';
  // Add more as needed from codebase references.

  /// Centralized route generator stub (UI mapping handled in app_router.dart).
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    // Only route strings here. UI mapping is handled in app_router.dart.
    switch (settings.name) {
      case home:
      case login:
      case chat:
      case messageRequests:
      case userProfile:
      case signup:
      case landing:
      case discovery:
      case friends:
      case notifications:
      case events:
      case eventDetails:
      case coins:
      case accountSettings:
      case privacySettings:
      case notificationSettings:
      case blockedUsers:
      case routeTest:
      case providerDebug:
      case onboarding:
      case matches:
      case discoverRooms:
      case discoverRoomsLive:
      case suggestedUsers:
      case trendingUsers:
      case activeNow:
      case createShortVideo:
      case storyViewer:
      case createStory:
      case reportUser:
      case profileMedia:
      case socialFeed:
      case agoraTest:
      case app:
        // UI mapping handled in app_router.dart
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Route not found or mapped externally')),
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Route not found')),
          ),
        );
    }
  }
}
