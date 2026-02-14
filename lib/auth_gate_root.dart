import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/design_system/design_constants.dart';
import 'features/auth/screens/neon_login_page.dart';
import 'features/auth/screens/neon_signup_page.dart';
import 'features/auth/forgot_password_page.dart';
import 'features/onboarding_flow.dart';
import 'features/landing/landing_page.dart';
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
/// 3. If user is null → Show unauthenticated app (landing/login/signup)
/// 4. If user exists → Watch currentUserProvider (loaded profile)
/// 5. If profile incomplete → Show profile creation
/// 6. If profile complete → Show main app
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
        debugPrint('⏳ [RootAuthGate] Firebase auth state still loading...');
        return const _SplashLoadingScreen();
      },

      // Auth error - show splash and log
      error: (error, stack) {
        debugPrint('❌ [RootAuthGate] Auth state error: $error');
        AppLogger.error('Auth gate error: $error');
        return const _SplashLoadingScreen();
      },

      // No user authenticated - show login/signup flow
      data: (user) {
        if (user == null) {
          debugPrint('🔓 [RootAuthGate] No user authenticated');
          return const _UnauthenticatedApp();
        }

        // User is authenticated - check if profile is complete
        debugPrint('✅ [RootAuthGate] User authenticated: ${user.email}');

        return _AuthenticatedAppGate(userId: user.uid);
      },
    );
  }
}

/// ============================================================================
/// UNAUTHENTICATED APP - Landing → Login/Signup
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
        debugPrint('🔓 [Unauthenticated] Route: ${settings.name}');
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
            debugPrint('⛔ [Unauthenticated] Blocked access to: ${settings.name}');
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

    debugPrint('👤 [AuthenticatedGate] Checking profile for: $userId');

    return userState.when(
      // Still loading profile
      loading: () {
        debugPrint('⏳ [AuthenticatedGate] Loading user profile...');
        return const _SplashLoadingScreen();
      },

      // Error loading profile - still show splash
      error: (error, stack) {
        debugPrint('⚠️ [AuthenticatedGate] Profile load error: $error');
        return const _SplashLoadingScreen();
      },

      // Profile loaded
      data: (user) {
        // Check if profile is complete - displayName must exist and not be empty
        debugPrint('📄 [AuthenticatedGate] User data: ${user != null ? "exists" : "null"}');
        if (user != null) {
          debugPrint('🔑 [AuthenticatedGate] User fields: displayName="${user.displayName}", username="${user.username}", email="${user.email}"');
        }

        final displayName = user?.displayName ?? '';
        debugPrint('👤 [AuthenticatedGate] displayName extracted: "$displayName" (isEmpty: ${displayName.isEmpty})');

        if (displayName.isNotEmpty) {
          debugPrint('✅ [AuthenticatedGate] Profile complete. Showing app.');

          // Initialize optional services non-blocking
          _initializeOptionalServices(ref, userId);

          // Show main app (onboarding check is handled by the OnboardingFlow which
          // checks onboardingComplete in Firestore and shows itself if needed)
          return const MixMingleApp();
        }

        debugPrint('🚧 [AuthenticatedGate] Profile incomplete. Forcing completion.');
        return _ProfileIncompleteApp(userId: userId);
      },
    );
  }

  /// Initialize optional services that don't block app rendering
  void _initializeOptionalServices(WidgetRef ref, String userId) {
    Future.microtask(() async {
      try {
        // Initialize presence (non-blocking)
        debugPrint('📱 [Init] Initializing presence for $userId...');
        final presenceService = ref.read(presenceServiceProvider);
        await presenceService.initializePresence();
        await presenceService.goOnline();
        debugPrint('✅ [Init] Presence initialized');

        // Initialize FCM notifications (non-blocking)
        debugPrint('📱 [Init] Initializing FCM notifications...');
        // FCM setup happens in main.dart, this is just for reference
        debugPrint('✅ [Init] FCM notifications ready');

        AppLogger.info('Post-auth initialization complete');
      } catch (e) {
        debugPrint('⚠️ [Init] Optional service init failed (non-fatal): $e');
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
    debugPrint('🚧 [ProfileIncomplete] Showing onboarding for $userId');

    return MaterialApp(
      title: 'Mix & Mingle - Complete Your Profile',
      debugShowCheckedModeBanner: false,
      theme: NeonTheme.darkTheme,
      home: OnboardingFlow(),
      onGenerateRoute: (settings) {
        debugPrint('🚧 [ProfileIncomplete] Route: ${settings.name}');
        switch (settings.name) {
          case '/create-profile':
          case '/onboarding':
            return MaterialPageRoute(builder: (_) => OnboardingFlow());
          case '/logout':
            // Allow logout even from profile creation
            return MaterialPageRoute(builder: (_) => const LandingPage());
          default:
            // Everything else blocked - stay on onboarding
            return MaterialPageRoute(builder: (_) => OnboardingFlow());
        }
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


