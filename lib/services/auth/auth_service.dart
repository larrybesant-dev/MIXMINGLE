import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../analytics/analytics_service.dart';
import 'account_deletion_service.dart';
import '../infra/data_export_service.dart';
import '../infra/error_tracking_service.dart';
import '../notifications/push_notification_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn? _googleSignIn = kIsWeb ? null : GoogleSignIn.instance;
  final AnalyticsService _analytics;
  final AccountDeletionService _deletionService;
  final DataExportService _exportService;
  final ErrorTrackingService _errorTracking = ErrorTrackingService();
  final PushNotificationService _pushNotifications = PushNotificationService();

  AuthService({
    AnalyticsService? analytics,
    AccountDeletionService? deletionService,
    DataExportService? exportService,
  })  : _analytics = analytics ?? AnalyticsService(),
        _deletionService = deletionService ?? AccountDeletionService(),
        _exportService = exportService ?? DataExportService();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential?> signInWithEmailAndPassword(String email, String password, {bool rememberMe = false}) async {
    try {
      _errorTracking.log('Sign in attempt: $email');

      // Set persistence based on remember me preference
      if (rememberMe) {
        await _auth.setPersistence(Persistence.LOCAL);
      } else {
        await _auth.setPersistence(Persistence.SESSION);
      }

      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Track successful login
      await _analytics.trackLogin('email');

      // Set user context for error tracking
      if (result.user != null) {
        await _errorTracking.setUserId(result.user!.uid);
        await _errorTracking.setCustomKeys({
          'email': email,
          'login_method': 'email',
          'account_created': result.user!.metadata.creationTime?.toIso8601String() ?? 'unknown',
        });

        // Initialize push notifications for this user
        await _pushNotifications.initialize();
        _errorTracking.log('Push notifications initialized for user');
      }

      return result;
    } on FirebaseAuthException catch (e, stack) {
      debugPrint('ðŸ”´ Firebase Auth Error: ${e.code}');
      debugPrint('ðŸ”´ Message: ${e.message}');

      // Track authentication errors
      await _errorTracking.recordError(
        e,
        stack,
        reason: 'Email sign in failed: ${e.code}',
        information: ['Email: $email'],
      );

      throw Exception('Sign in failed: [${e.code}] ${e.message}');
    } catch (e, stack) {
      debugPrint('ðŸ”´ Unexpected error: $e');
      await _errorTracking.recordError(e, stack, reason: 'Unexpected sign in error');
      throw Exception('Sign in failed: $e');
    }
  }

  Future<UserCredential?> createUserWithEmailAndPassword(String email, String password) async {
    try {
      _errorTracking.log('Sign up attempt: $email');

      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _analytics.trackSignUp('email');

      // Set user context for new account
      if (result.user != null) {
        await _errorTracking.setUserId(result.user!.uid);
        await _errorTracking.setCustomKeys({
          'email': email,
          'signup_method': 'email',
          'account_created': result.user!.metadata.creationTime?.toIso8601String() ?? 'unknown',
        });

        // Initialize push notifications
        await _pushNotifications.initialize();
      }

      return result;
    } on FirebaseAuthException catch (e, stack) {
      await _errorTracking.recordError(e, stack, reason: 'Email sign up failed: ${e.code}');
      throw Exception('Sign up failed: $e');
    } catch (e, stack) {
      await _errorTracking.recordError(e, stack, reason: 'Unexpected sign up error');
      throw Exception('Sign up failed: $e');
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    // Google Sign-In not supported on web without proper config
    if (kIsWeb || _googleSignIn == null) {
      throw Exception('Google sign in is not configured for web');
    }

    try {
      _errorTracking.log('Google sign in attempt');

      // Trigger the authentication flow
      // authenticate() returns GoogleSignInAccount or throws if cancelled
      final googleUser = await _googleSignIn.authenticate();

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the credential
      final result = await _auth.signInWithCredential(credential);
      await _analytics.trackLogin('google');

      // Set user context for Google sign in
      if (result.user != null) {
        await _errorTracking.setUserId(result.user!.uid);
        await _errorTracking.setCustomKeys({
          'email': result.user!.email ?? 'unknown',
          'login_method': 'google',
          'display_name': result.user!.displayName ?? 'unknown',
        });

        // Initialize push notifications
        await _pushNotifications.initialize();
      }

      return result;
    } on FirebaseAuthException catch (e, stack) {
      await _errorTracking.recordError(e, stack, reason: 'Google sign in failed: ${e.code}');
      throw Exception('Google sign in failed: $e');
    } catch (e, stack) {
      await _errorTracking.recordError(e, stack, reason: 'Unexpected Google sign in error');
      throw Exception('Google sign in failed: $e');
    }
  }

  // Phone Authentication
  Future<void> verifyPhoneNumber(
    String phoneNumber,
    Function(String verificationId) onCodeSent,
    Function(PhoneAuthCredential credential) onVerificationCompleted,
    Function(FirebaseAuthException error) onVerificationFailed,
  ) async {
    _errorTracking.log('Phone verification initiated: $phoneNumber');

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (credential) {
        _errorTracking.log('Phone auto-verification completed');
        onVerificationCompleted(credential);
      },
      verificationFailed: (error) {
        _errorTracking.recordError(error, StackTrace.current, reason: 'Phone verification failed: ${error.code}');
        onVerificationFailed(error);
      },
      codeSent: (String verificationId, int? resendToken) {
        _errorTracking.log('Phone verification code sent');
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _errorTracking.log('Phone code auto-retrieval timeout');
      },
      timeout: const Duration(seconds: 60),
    );
  }

  Future<UserCredential?> signInWithPhoneCredential(
    String verificationId,
    String smsCode,
  ) async {
    try {
      _errorTracking.log('Phone sign in attempt');

      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final result = await _auth.signInWithCredential(credential);
      await _analytics.trackLogin('phone');

      // Set user context for phone sign in
      if (result.user != null) {
        await _errorTracking.setUserId(result.user!.uid);
        await _errorTracking.setCustomKeys({
          'phone': result.user!.phoneNumber ?? 'unknown',
          'login_method': 'phone',
        });

        // Initialize push notifications
        await _pushNotifications.initialize();
      }

      return result;
    } on FirebaseAuthException catch (e, stack) {
      await _errorTracking.recordError(e, stack, reason: 'Phone sign in failed: ${e.code}');
      throw Exception('Phone sign in failed: $e');
    } catch (e, stack) {
      await _errorTracking.recordError(e, stack, reason: 'Unexpected phone sign in error');
      throw Exception('Phone sign in failed: $e');
    }
  }

  Future<UserCredential?> createUserWithPhoneCredential(
    String verificationId,
    String smsCode,
  ) async {
    try {
      _errorTracking.log('Phone sign up attempt');

      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final result = await _auth.signInWithCredential(credential);
      await _analytics.trackSignUp('phone');

      // Set user context for new phone account
      if (result.user != null) {
        await _errorTracking.setUserId(result.user!.uid);
        await _errorTracking.setCustomKeys({
          'phone': result.user!.phoneNumber ?? 'unknown',
          'signup_method': 'phone',
          'account_created': result.user!.metadata.creationTime?.toIso8601String() ?? 'unknown',
        });

        // Initialize push notifications
        await _pushNotifications.initialize();
      }

      return result;
    } on FirebaseAuthException catch (e, stack) {
      await _errorTracking.recordError(e, stack, reason: 'Phone sign up failed: ${e.code}');
      throw Exception('Phone sign up failed: $e');
    } catch (e, stack) {
      await _errorTracking.recordError(e, stack, reason: 'Unexpected phone sign up error');
      throw Exception('Phone sign up failed: $e');
    }
  }

  Future<void> signOut() async {
    try {
      _errorTracking.log('Sign out initiated');

      final userId = currentUser?.uid;

      // Delete FCM token before sign out
      await _pushNotifications.deleteFCMToken();

      // Sign out
      await _auth.signOut();

      // Clear user context from error tracking
      await _errorTracking.clearUserData();

      _errorTracking.log('Sign out completed for user: $userId');
    } catch (e, stack) {
      await _errorTracking.recordError(e, stack, reason: 'Sign out failed');
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Convenience aliases for common naming patterns
  Future<UserCredential?> login(String email, String password, {bool rememberMe = false}) =>
      signInWithEmailAndPassword(email, password, rememberMe: rememberMe);

  Future<UserCredential?> signup({
    required String email,
    required String password,
    String? username,
    String? displayName,
  }) =>
      createUserWithEmailAndPassword(email, password);

  Future<void> logout() => signOut();

  /// Deletes the current user account and all associated data (GDPR compliant)
  /// Throws exception if user needs to reauthenticate
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }

    try {
      // Use comprehensive deletion service
      await _deletionService.deleteUserAccount(user.uid);
      await _analytics.trackEvent('account_deleted', parameters: {
        'user_id': user.uid,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        // User needs to reauthenticate before deletion
        throw Exception('Please sign in again before deleting your account');
      }
      rethrow;
    }
  }

  /// Validates if account can be deleted and returns warnings
  Future<List<String>> validateAccountDeletion() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }
    return await _deletionService.validateDeletion(user.uid);
  }

  // ========== Data Export (GDPR) ==========

  /// Exports all user data as JSON (GDPR Right to Data Portability)
  Future<String> exportUserData() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }

    try {
      final jsonData = await _exportService.exportUserData(user.uid);
      await _analytics.trackEvent('data_exported', parameters: {
        'user_id': user.uid,
        'timestamp': DateTime.now().toIso8601String(),
      });
      return jsonData;
    } catch (e) {
      throw Exception('Failed to export data: $e');
    }
  }

  /// Gets a summary of data to be exported
  Future<Map<String, int>> getExportSummary() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }
    return await _exportService.getExportSummary(user.uid);
  }

  // ========== Social Login Linking ==========

  /// Links Google account to current user
  Future<UserCredential> linkWithGoogle() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }

    if (kIsWeb || _googleSignIn == null) {
      throw Exception('Google sign in is not configured for web');
    }

    try {
      // Trigger the authentication flow
      // authenticate() returns GoogleSignInAccount or throws if cancelled
      final googleUser = await _googleSignIn.authenticate();

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // Link the credential to the current user
      final result = await user.linkWithCredential(credential);
      await _analytics.trackEvent('account_linked', parameters: {
        'provider': 'google',
      });
      return result;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'credential-already-in-use') {
        throw Exception('This Google account is already linked to another user');
      } else if (e.code == 'provider-already-linked') {
        throw Exception('A Google account is already linked to this user');
      }
      throw Exception('Failed to link Google account: ${e.message}');
    } catch (e) {
      throw Exception('Failed to link Google account: $e');
    }
  }

  /// Unlinks a provider from current user
  Future<User> unlinkProvider(String providerId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }

    try {
      // Ensure user has at least one other sign-in method
      if (user.providerData.length <= 1) {
        throw Exception('Cannot unlink the only sign-in method. Please link another method first.');
      }

      final result = await user.unlink(providerId);
      await _analytics.trackEvent('account_unlinked', parameters: {
        'provider': providerId,
      });
      return result;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'no-such-provider') {
        throw Exception('This provider is not linked to your account');
      }
      throw Exception('Failed to unlink provider: ${e.message}');
    }
  }

  /// Gets list of linked providers for current user
  List<String> getLinkedProviders() {
    final user = _auth.currentUser;
    if (user == null) return [];

    return user.providerData.map((info) => info.providerId).toList();
  }

  /// Checks if a specific provider is linked
  bool isProviderLinked(String providerId) {
    return getLinkedProviders().contains(providerId);
  }

  /// Gets user-friendly name for provider ID
  String getProviderName(String providerId) {
    switch (providerId) {
      case 'google.com':
        return 'Google';
      case 'password':
        return 'Email/Password';
      case 'phone':
        return 'Phone';
      case 'facebook.com':
        return 'Facebook';
      case 'apple.com':
        return 'Apple';
      default:
        return providerId;
    }
  }
}
