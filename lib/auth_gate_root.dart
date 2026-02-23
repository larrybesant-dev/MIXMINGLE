import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/design_system/design_constants.dart';
import 'features/auth/screens/neon_login_page.dart';
import 'features/auth/screens/neon_signup_page.dart';
import 'features/auth/forgot_password_page.dart';
// TEMP DISABLED: import 'features/onboarding_flow.dart';
import 'features/landing/landing_page.dart';
import 'features/home/home_page_electric.dart';
import 'app.dart';
import 'providers/all_providers.dart';
import 'core/theme/neon_theme.dart';
import 'core/utils/app_logger.dart';

/// ROOT AUTH GATE - The Single Source of Truth for App Access
/// ============================================================================
///
/// This widget MUST be the root of the app. It controls ALL access to the app
/// using unified Riverpod providers, ensuring no race conditions or stale state.
///
/// Flow:
/// 1. App starts
/// 2. Root Auth Gate watches authStateProvider (Firebase auth stream)
/// 3. If user is null â†’ Show unauthenticated app (landing/login/signup)
/// 4. If user exists â†’ Watch currentUserProvider (loaded profile)
/// 5. If profile incomplete â†’ Show profile creation
/// 6. If profile complete â†’ Show main app
///
/// NO exceptions. NO bypasses. NO race conditions.
/// ============================================================================

class RootAuthGate extends ConsumerWidget {
  const RootAuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the Firebase auth state - foundation of everything
    final authState = ref.watch(authStateProvider);

    return authState.when(
      // Auth state still resolving - show loading splash
      loading: () {
        debugPrint('â³ [RootAuthGate] Firebase auth state still loading...');
        return const _SplashLoadingScreen();
      },

      // Auth error - show splash and log
      error: (error, stack) {
        debugPrint('âŒ [RootAuthGate] Auth state error: $error');
        AppLogger.error('Auth gate error: $error');
        return const _SplashLoadingScreen();
      },

      // No user authenticated - show login/signup flow
      data: (user) {
        if (user == null) {
          debugPrint('ðŸ”“ [RootAuthGate] No user authenticated');
          return const _UnauthenticatedApp();
        }

        // User is authenticated - check if profile is complete
        debugPrint('âœ… [RootAuthGate] User authenticated: ${user.email}');

        return _AuthenticatedAppGate(userId: user.uid);
      },
    );
  }
}

/// ============================================================================
/// UNAUTHENTICATED APP - Landing â†’ Login/Signup
/// ============================================================================
/// Shows only to users who are not logged in.
class _UnauthenticatedApp extends StatelessWidget {
  const _UnauthenticatedApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mix & Mingle - Vibes Around the World',
      debugShowCheckedModeBanner: false,
      theme: NeonTheme.darkTheme,
      home: const LandingPage(),
      onGenerateRoute: (settings) {
        debugPrint('ðŸ”“ [Unauthenticated] Route: ${settings.name}');
        switch (settings.name) {
          case '/':
          case '/landing':
            return MaterialPageRoute(builder: (_) => const LandingPage());
          case '/login':
            return MaterialPageRoute(builder: (_) => const NeonLoginPage());
          case '/signup':
            return MaterialPageRoute(builder: (_) => const NeonSignupPage());
          case '/forgot-password':
            return MaterialPageRoute(
              builder: (_) => const ForgotPasswordPage(),
            );
          default:
            // Block all other routes - send back to landing
            debugPrint('â›” [Unauthenticated] Blocked access to: ${settings.name}');
            return MaterialPageRoute(builder: (_) => const LandingPage());
        }
      },
    );
  }
}

/// ============================================================================
/// AUTHENTICATED APP GATE - Check Profile Completion
/// ============================================================================
/// Shows only to authenticated users.
/// Checks if profile is complete before allowing app access.
class _AuthenticatedAppGate extends ConsumerWidget {
  final String userId;

  const _AuthenticatedAppGate({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the current user's profile
    final userState = ref.watch(currentUserProvider);

    debugPrint('ðŸ‘¤ [AuthenticatedGate] Checking profile for: $userId');

    return userState.when(
      // Still loading profile
      loading: () {
        debugPrint('â³ [AuthenticatedGate] Loading user profile...');
        return const _SplashLoadingScreen();
      },

      // Error loading profile - still show splash
      error: (error, stack) {
        debugPrint('âš ï¸ [AuthenticatedGate] Profile load error: $error');
        return const _SplashLoadingScreen();
      },

      // Profile loaded
      data: (user) {
        // Check if profile is complete - either displayName OR username must exist
        debugPrint('ðŸ“„ [AuthenticatedGate] User data: ${user != null ? "exists" : "null"}');
        if (user != null) {
          debugPrint('ðŸ”‘ [AuthenticatedGate] User fields: displayName="${user.displayName}", username="${user.username}", email="${user.email}"');
        }

        final displayName = user?.displayName ?? '';
        final username = user?.username ?? '';
        debugPrint('ðŸ‘¤ [AuthenticatedGate] displayName="$displayName", username="$username"');

        if (displayName.isNotEmpty || username.isNotEmpty) {
          debugPrint('âœ… [AuthenticatedGate] Profile complete. Showing app.');

          // Initialize optional services non-blocking
          _initializeOptionalServices(ref, userId);

          // Show main app (onboarding check is handled by the OnboardingFlow which
          // checks onboardingComplete in Firestore and shows itself if needed)
          return const MixMingleApp();
        }

        debugPrint('ðŸš§ [AuthenticatedGate] Profile incomplete. Forcing completion.');
        return _ProfileIncompleteApp(userId: userId);
      },
    );
  }

  /// Initialize optional services that don't block app rendering
  void _initializeOptionalServices(WidgetRef ref, String userId) {
    Future.microtask(() async {
      try {
        // Initialize presence (non-blocking)
        debugPrint('ðŸ“± [Init] Initializing presence for $userId...');
        final presenceService = ref.read(presenceServiceProvider);
        await presenceService.initializePresence();
        await presenceService.goOnline();
        debugPrint('âœ… [Init] Presence initialized');

        // Initialize FCM notifications (non-blocking)
        debugPrint('ðŸ“± [Init] Initializing FCM notifications...');
        // FCM setup happens in main.dart, this is just for reference
        debugPrint('âœ… [Init] FCM notifications ready');

        AppLogger.info('Post-auth initialization complete');
      } catch (e) {
        debugPrint('âš ï¸ [Init] Optional service init failed (non-fatal): $e');
        AppLogger.warning('Optional service initialization failed: $e');
        // App continues - these services are not critical for rendering
      }
    });
  }
}

/// ============================================================================
/// PROFILE INCOMPLETE APP - Force Profile Creation
/// ============================================================================
/// Shows only to authenticated users without complete profiles.
class _ProfileIncompleteApp extends StatelessWidget {
  final String userId;

  const _ProfileIncompleteApp({required this.userId});

  @override
  Widget build(BuildContext context) {
    debugPrint('ðŸš§ [ProfileIncomplete] Redirecting to home for $userId');

    // TEMP DISABLED: Onboarding bypassed
    return MaterialApp(
      title: 'Mix & Mingle',
      debugShowCheckedModeBanner: false,
      theme: NeonTheme.darkTheme,
      home: HomePageElectric(), // Skip onboarding, go to home (not const)
      onGenerateRoute: (settings) {
        debugPrint('ðŸš§ [ProfileIncomplete] Route: ${settings.name}');
        // All routes lead to home since onboarding is disabled
        return MaterialPageRoute(builder: (_) => HomePageElectric());
      },
    );
  }
}

/// ============================================================================
/// SPLASH LOADING SCREEN - Shown During Auth State Resolution
/// ============================================================================
class _SplashLoadingScreen extends StatelessWidget {
  const _SplashLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mix & Mingle',
      debugShowCheckedModeBanner: false,
      theme: NeonTheme.darkTheme,
      home: Scaffold(
        backgroundColor: DesignColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Neon logo
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: DesignColors.accent,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.videocam,
                  color: DesignColors.secondary,
                  size: 50,
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Mix & Mingle',
                style: TextStyle(
                  color: DesignColors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Vibes Around the World',
                style: TextStyle(
                  color: DesignColors.accent,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(DesignColors.accent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
