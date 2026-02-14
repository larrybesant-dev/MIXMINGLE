import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:provider/provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'firebase_options.dart';
import 'auth_gate_root.dart';
import 'features/landing/landing_page.dart';
import 'features/auth/screens/neon_login_page.dart';
import 'features/auth/screens/neon_signup_page.dart';
import 'features/auth/forgot_password_page.dart';
import 'core/theme/neon_theme.dart';
// TODO: Re-enable once Riverpod providers are migrated to 3.x
// import 'services/push_notification_service.dart';
import 'core/utils/app_logger.dart';
import 'core/health_check_system.dart';
import 'core/crashlytics/crashlytics_service.dart';
import 'core/performance/performance_service.dart';
import 'services/notification_service.dart';
import 'services/agora_service.dart';
import 'services/room_firestore_service.dart';
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Handle background message through notification service
  if (message.notification != null) {
    // Initialize notification service
    // final notificationService = NotificationService();
    debugPrint('Handling background message: ${message.notification!.title}');
  }
}

void main() {
  // CRITICAL: All initialization MUST happen inside runZonedGuarded to avoid zone mismatch
  runZonedGuarded(
    () async {
      // Initialize Flutter bindings FIRST - inside the guarded zone
      WidgetsFlutterBinding.ensureInitialized();

      debugPrint('🚀 Starting app initialization...');

      // Set custom error widget for release mode (shows grey by default)
      ErrorWidget.builder = (FlutterErrorDetails details) {
        debugPrint('🔴 ErrorWidget building for: ${details.exception}');
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            backgroundColor: const Color(0xFF080C14),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFFF6B35), size: 64),
                  const SizedBox(height: 24),
                  const Text(
                    'Something went wrong',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${details.exception}'.length > 100
                        ? '${details.exception}'.substring(0, 100)
                        : '${details.exception}',
                    style: const TextStyle(color: Color(0xFF888888), fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      };

      try {
        // Initialize Firebase ONCE - block on this
        debugPrint('🔥 Initializing Firebase...');
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
        debugPrint('✅ Firebase initialized successfully');
        AppLogger.info('Firebase initialized successfully');

        // Initialize Crashlytics BEFORE anything else that might error
        debugPrint('💥 Initializing Crashlytics...');
        await CrashlyticsService.instance.initialize();

        // Set up Flutter error handler for Crashlytics
        FlutterError.onError = (FlutterErrorDetails details) {
          debugPrint('❌ FLUTTER ERROR: ${details.exception}');
          debugPrint('Stack: ${details.stack}');
          AppLogger.error('Flutter Error: ${details.exception}');
          // Skip Crashlytics on web (not supported)
          if (!kIsWeb) {
            FirebaseCrashlytics.instance.recordFlutterFatalError(details);
          }
        };
        debugPrint('✅ Crashlytics initialized');

        // Initialize Performance Monitoring
        debugPrint('📊 Initializing Performance Monitoring...');
        await PerformanceService.instance.initialize();
        debugPrint('✅ Performance Monitoring initialized');

        // Set up FCM background message handler
        debugPrint('📱 Setting up FCM...');
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
        debugPrint('✅ FCM background handler registered');

        // Initialize local notifications (don't block app startup if it fails)
        debugPrint('📱 Initializing local notifications...');
        NotificationService().initialize().then((_) {
          debugPrint('✅ Notifications initialized successfully');
        }).catchError((e) {
          debugPrint('⚠️  Notification initialization non-fatal failure: $e');
          AppLogger.warning('Notifications unavailable: $e');
          CrashlyticsService.instance.recordError(e, reason: 'notification_init_failure');
        });

        // Initialize FCM notifications (don't block app startup if it fails)
        debugPrint('📱 FCM notification setup deferred to auth gate...');

        // Run health checks
        debugPrint('🏥 Running project health checks...');
        final healthChecker = ProjectHealthChecker();
        await healthChecker.runAllChecks();
        final healthStatus = healthChecker.isHealthy ? '✅ HEALTHY' : '⚠️  ISSUES DETECTED';
        debugPrint('Health check status: $healthStatus');
        AppLogger.info('Health check completed: $healthStatus');
      } catch (e, stackTrace) {
        debugPrint('❌ Initialization error: $e');
        AppLogger.error('Initialization failed: $e');
        CrashlyticsService.instance.recordError(e, stackTrace: stackTrace, reason: 'app_init_failure');
        // App will still start even if services fail, but user may experience missing features
      }

      debugPrint('🚀 Running app with Riverpod and Provider setup...');

      runApp(
        riverpod.ProviderScope(
          child: MultiProvider(
            providers: [
              // ✅ Agora Service (singleton)
              Provider<AgoraService>(
                create: (_) => AgoraService(),
              ),

              // ✅ Room Firestore Service (singleton)
              Provider<RoomFirestoreService>(
                create: (_) => RoomFirestoreService(),
              ),
            ],
            child: const _AlwaysLandingApp(),
          ),
        ),
      );
    },
    (error, stackTrace) {
      // Handle async errors with Crashlytics
      debugPrint('❌ ASYNC ERROR: $error');
      debugPrint('Stack: $stackTrace');
      AppLogger.error('Async Error: $error');
      CrashlyticsService.instance.recordError(
        error,
        stackTrace: stackTrace,
        reason: 'async_error',
      );
    },
  );
}

/// Always show landing page first - user must manually login
class _AlwaysLandingApp extends StatelessWidget {
  const _AlwaysLandingApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mix & Mingle - Vibes Around the World',
      debugShowCheckedModeBanner: false,
      theme: NeonTheme.darkTheme,
      home: const LandingPage(),
      onGenerateRoute: (settings) {
        debugPrint('🌐 [AlwaysLanding] Route: ${settings.name}');
        switch (settings.name) {
          case '/':
          case '/landing':
            return MaterialPageRoute(builder: (_) => const LandingPage());
          case '/login':
            return MaterialPageRoute(builder: (_) => const NeonLoginPage());
          case '/signup':
            return MaterialPageRoute(builder: (_) => const NeonSignupPage());
          case '/forgot-password':
            return MaterialPageRoute(builder: (_) => const ForgotPasswordPage());
          case '/app':
            // After login, go to the auth-protected app
            return MaterialPageRoute(builder: (_) => const RootAuthGate());
          default:
            // Unknown routes go back to landing
            debugPrint('⛔ [AlwaysLanding] Unknown route: ${settings.name}');
            return MaterialPageRoute(builder: (_) => const LandingPage());
        }
      },
    );
  }
}
