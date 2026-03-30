import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mixvy/features/auth/controllers/auth_controller.dart';
import 'package:mixvy/core/services/first_run_service.dart';
import 'package:mixvy/core/services/profile_gate_service.dart';
import 'package:mixvy/features/onboarding/onboarding_screen.dart';
import 'package:mixvy/features/feed/screens/discovery_feed_screen.dart';
import 'package:mixvy/features/profile/user_profile_screen.dart';
import 'package:mixvy/presentation/screens/friend_list_screen.dart';
import 'package:mixvy/presentation/screens/live_room_screen.dart';
import 'package:mixvy/presentation/screens/notifications_screen.dart';
import 'package:mixvy/presentation/screens/settings_screen.dart';
import 'package:mixvy/presentation/screens/account_center_screen.dart';
import 'package:mixvy/presentation/screens/legal_terms_screen.dart';
import 'package:mixvy/presentation/screens/legal_privacy_screen.dart';
import 'package:mixvy/presentation/screens/app_info_screen.dart';
import 'package:mixvy/presentation/screens/moderation_dashboard_screen.dart';
import 'package:mixvy/features/speed_dating/screens/speed_dating_screen.dart';
import 'package:mixvy/core/services/app_settings_service.dart';
import 'package:mixvy/features/messaging/screens/messages_screen.dart';
import 'package:mixvy/features/messaging/screens/chat_screen.dart';
import 'package:mixvy/features/messaging/screens/new_message_screen.dart';
import 'package:mixvy/features/search/screens/search_screen.dart';
import 'package:mixvy/features/bookmarks/screens/bookmarks_screen.dart';
import 'package:mixvy/presentation/providers/user_provider.dart';
import 'package:mixvy/features/follow/screens/follow_screens.dart';
import 'package:mixvy/features/posts/screens/create_post_screen.dart';
import 'package:mixvy/features/stories/screens/create_story_screen.dart';
import 'package:mixvy/features/groups/screens/groups_screen.dart';
import 'package:mixvy/features/groups/screens/create_group_screen.dart';
import 'package:mixvy/features/groups/screens/group_details_screen.dart';
import 'package:mixvy/features/trending/screens/trending_screen.dart';
import 'package:mixvy/presentation/screens/not_found_screen.dart';

import '../features/auth/register_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/payments/payments_screen.dart';

// Supabase logic removed.

import 'package:mixvy/features/auth/screens/login_screen.dart';
import '../features/dashboard/dashboard_screen.dart';

class _CacheEntry<T> {
  const _CacheEntry({required this.value, required this.loadedAt});

  final T value;
  final DateTime loadedAt;
}

class _RouterGateCache {
  static const Duration _profileTtl = Duration(seconds: 20);

  final Map<String, _CacheEntry<bool>> _profileByUid =
      <String, _CacheEntry<bool>>{};
  final Map<String, Future<bool>> _inFlightProfileChecks =
      <String, Future<bool>>{};

  Future<bool> isFirstRun() async {
    // Do not cache here: FirstRunService already caches internally and updates
    // its cache when onboarding is marked as seen.
    return FirstRunService.isFirstRun();
  }

  Future<bool> isProfileComplete(String uid) async {
    final now = DateTime.now();
    final cached = _profileByUid[uid];
    if (cached != null && now.difference(cached.loadedAt) < _profileTtl) {
      return cached.value;
    }

    final inFlight = _inFlightProfileChecks[uid];
    if (inFlight != null) {
      return inFlight;
    }

    final future = ProfileGateService.isProfileComplete(uid)
        .then((isComplete) {
          _profileByUid[uid] = _CacheEntry<bool>(
            value: isComplete,
            loadedAt: DateTime.now(),
          );
          _inFlightProfileChecks.remove(uid);
          return isComplete;
        })
        .catchError((error) {
          _inFlightProfileChecks.remove(uid);
          throw error;
        });

    _inFlightProfileChecks[uid] = future;
    return future;
  }
}

final _routerGateCacheProvider = Provider<_RouterGateCache>((ref) {
  return _RouterGateCache();
});

typedef FirstRunCheck = Future<bool> Function();
typedef ProfileCompleteCheck = Future<bool> Function(String uid);
typedef LegalAcceptedCheck = Future<bool> Function();

String? _pathParamOrNull(GoRouterState state, String key) {
  final value = state.pathParameters[key];
  if (value == null || value.trim().isEmpty) {
    return null;
  }
  return value;
}

final firstRunCheckProvider = Provider<FirstRunCheck>((ref) {
  final gateCache = ref.read(_routerGateCacheProvider);
  return () => gateCache.isFirstRun();
});

final profileCompleteCheckProvider = Provider<ProfileCompleteCheck>((ref) {
  final gateCache = ref.read(_routerGateCacheProvider);
  return (uid) => gateCache.isProfileComplete(uid);
});

final legalAcceptedCheckProvider = Provider<LegalAcceptedCheck>((ref) {
  final service = AppSettingsService();
  return () => service.hasAcceptedCurrentLegal();
});

Future<String?> evaluateAppRedirect({
  required String matchedLocation,
  required String? uid,
  required FirstRunCheck isFirstRun,
  required ProfileCompleteCheck isProfileComplete,
  required LegalAcceptedCheck isLegalAccepted,
  bool isRouteError = false,
}) async {
  if (isRouteError || matchedLocation == '/404') {
    return null;
  }

  final loggedIn = uid != null;
  final isLoggingIn =
      matchedLocation == '/login' || matchedLocation == '/register';
  final isOnboarding = matchedLocation == '/onboarding';
  final isLegalRoute = matchedLocation.startsWith('/legal/');
  final isProfile = matchedLocation == '/profile';
  final firstRun = await isFirstRun();

  if (firstRun && !isOnboarding && !isLegalRoute) return '/onboarding';
  if (!firstRun && isOnboarding) return loggedIn ? '/' : '/login';

  final legalAccepted = await isLegalAccepted();
  if (!legalAccepted && !isOnboarding && !isLegalRoute) {
    return '/legal/terms';
  }

  if (!loggedIn && !isLoggingIn && !isLegalRoute) return '/login';
  if (loggedIn) {
    final profileComplete = await isProfileComplete(uid);
    if (!profileComplete && !isProfile) return '/profile';
    if (profileComplete && isProfile && !firstRun) return '/';
  }
  if (loggedIn && isLoggingIn) return '/';
  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);
  final firstRunCheck = ref.read(firstRunCheckProvider);
  final profileCompleteCheck = ref.read(profileCompleteCheckProvider);
  final legalAcceptedCheck = ref.read(legalAcceptedCheckProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/',
    errorBuilder: (context, state) =>
        NotFoundScreen(path: state.uri.toString()),
    redirect: (context, state) async {
      try {
        return evaluateAppRedirect(
          matchedLocation: state.matchedLocation,
          uid: authState.uid,
          isFirstRun: firstRunCheck,
          isProfileComplete: profileCompleteCheck,
          isLegalAccepted: legalAcceptedCheck,
          isRouteError: state.error != null,
        );
      } catch (error, stackTrace) {
        developer.log(
          'Router redirect failed for ${state.matchedLocation}',
          name: 'AppRouter',
          error: error,
          stackTrace: stackTrace,
        );
        return null;
      }
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(path: '/', builder: (context, state) => const DashboardScreen()),
      GoRoute(
        path: '/discover',
        builder: (context, state) => const DiscoveryFeedScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/profile/:userId',
        builder: (context, state) {
          final userId = _pathParamOrNull(state, 'userId');
          if (userId == null) {
            return NotFoundScreen(path: state.uri.toString());
          }
          return UserProfileScreen(userId: userId);
        },
      ),
      GoRoute(
        path: '/payments',
        builder: (context, state) => const PaymentsScreen(),
      ),
      GoRoute(
        path: '/speed-dating',
        builder: (context, state) => const SpeedDatingScreen(),
      ),
      GoRoute(
        path: '/friends',
        builder: (context, state) => const FriendListScreen(),
      ),
      GoRoute(
        path: '/room/:roomId',
        builder: (context, state) {
          final roomId = _pathParamOrNull(state, 'roomId');
          if (roomId == null) {
            return NotFoundScreen(path: state.uri.toString());
          }
          return LiveRoomScreen(roomId: roomId);
        },
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/account',
        builder: (context, state) => const AccountCenterScreen(),
      ),
      GoRoute(
        path: '/legal/terms',
        builder: (context, state) => const LegalTermsScreen(),
      ),
      GoRoute(
        path: '/legal/privacy',
        builder: (context, state) => const LegalPrivacyScreen(),
      ),
      GoRoute(
        path: '/about',
        builder: (context, state) => const AppInfoScreen(),
      ),
      GoRoute(
        path: '/404',
        builder: (context, state) =>
            NotFoundScreen(path: state.uri.toString()),
      ),
      GoRoute(
        path: '/moderation',
        builder: (context, state) => const ModerationDashboardScreen(),
      ),
      // Messaging routes
      GoRoute(
        path: '/messages',
        builder: (context, state) {
          final user = ref.read(userProvider);
          return MessagesScreen(
            userId: user?.id ?? 'unknown',
            username: user?.username ?? 'User',
          );
        },
      ),
      GoRoute(
        path: '/messages/new',
        builder: (context, state) {
          final user = ref.read(userProvider);
          return NewMessageScreen(
            userId: user?.id ?? 'unknown',
            username: user?.username ?? 'User',
            avatarUrl: user?.avatarUrl,
          );
        },
      ),
      GoRoute(
        path: '/messages/:conversationId',
        builder: (context, state) {
          final conversationId = _pathParamOrNull(state, 'conversationId');
          if (conversationId == null) {
            return NotFoundScreen(path: state.uri.toString());
          }
          final user = ref.read(userProvider);
          return ChatScreen(
            conversationId: conversationId,
            userId: user?.id ?? 'unknown',
            username: user?.username ?? 'User',
            avatarUrl: user?.avatarUrl,
          );
        },
      ),
      // Search route
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),
      // Bookmarks route
      GoRoute(
        path: '/bookmarks',
        builder: (context, state) {
          final user = ref.read(userProvider);
          return BookmarksScreen(userId: user?.id ?? 'unknown');
        },
      ),
      // Followers/Following routes
      GoRoute(
        path: '/followers/:userId',
        builder: (context, state) {
          final userId = _pathParamOrNull(state, 'userId');
          if (userId == null) {
            return NotFoundScreen(path: state.uri.toString());
          }
          return FollowersScreen(userId: userId);
        },
      ),
      GoRoute(
        path: '/following/:userId',
        builder: (context, state) {
          final userId = _pathParamOrNull(state, 'userId');
          if (userId == null) {
            return NotFoundScreen(path: state.uri.toString());
          }
          return FollowingScreen(userId: userId);
        },
      ),
      // Post creation route
      GoRoute(
        path: '/create-post',
        builder: (context, state) {
          final user = ref.read(userProvider);
          return CreatePostScreen(
            userId: user?.id ?? 'unknown',
            username: user?.username ?? 'User',
            avatarUrl: user?.avatarUrl,
          );
        },
      ),
      // Story creation route
      GoRoute(
        path: '/create-story',
        builder: (context, state) {
          final user = ref.read(userProvider);
          return CreateStoryScreen(
            userId: user?.id ?? 'unknown',
            username: user?.username ?? 'User',
            avatarUrl: user?.avatarUrl,
          );
        },
      ),
      // Groups routes
      GoRoute(
        path: '/groups',
        builder: (context, state) {
          final user = ref.read(userProvider);
          return GroupsScreen(userId: user?.id ?? 'unknown');
        },
      ),
      GoRoute(
        path: '/create-group',
        builder: (context, state) {
          final user = ref.read(userProvider);
          return CreateGroupScreen(userId: user?.id ?? 'unknown');
        },
      ),
      GoRoute(
        path: '/group/:groupId',
        builder: (context, state) {
          final groupId = _pathParamOrNull(state, 'groupId');
          if (groupId == null) {
            return NotFoundScreen(path: state.uri.toString());
          }
          final user = ref.read(userProvider);
          return GroupDetailsScreen(
            groupId: groupId,
            userId: user?.id ?? 'unknown',
          );
        },
      ),
      // Trending route
      GoRoute(
        path: '/trending',
        builder: (context, state) => const TrendingScreen(),
      ),
    ],
  );
});

final GlobalKey<NavigatorState> rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'mixvy-root-navigator');

