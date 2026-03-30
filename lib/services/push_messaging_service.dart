import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    developer.log(
      'Background push received: ${message.messageId}',
      name: 'PushMessagingService',
    );
  } catch (error, stackTrace) {
    developer.log(
      'Failed to process background push',
      name: 'PushMessagingService',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

class PushMessagingService {
  PushMessagingService._();

  static final PushMessagingService instance = PushMessagingService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;

  bool _isInitialized = false;
  String? _lastRegisteredUid;
  String? _lastRegisteredToken;

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    _isInitialized = true;

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onOpenedMessage);
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((token) {
      unawaited(_registerTokenIfPossible(token));
    });
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        unawaited(_registerCurrentToken());
      }
    });

    await _requestPermission();

    await _handleInitialMessage();

    await _registerCurrentToken();
  }

  Future<void> _handleInitialMessage() async {
    try {
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _onOpenedMessage(initialMessage);
      }
    } on MissingPluginException catch (error, stackTrace) {
      // Some web runtime/plugin combinations do not implement getInitialMessage.
      developer.log(
        'Push initial message not available on this platform runtime.',
        name: 'PushMessagingService',
        error: error,
        stackTrace: stackTrace,
      );
    } catch (error, stackTrace) {
      developer.log(
        'Failed to process initial push message',
        name: 'PushMessagingService',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      developer.log(
        'Push permission status: ${settings.authorizationStatus.name}',
        name: 'PushMessagingService',
      );
    } catch (error, stackTrace) {
      developer.log(
        'Push permission request failed',
        name: 'PushMessagingService',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _registerCurrentToken() async {
    try {
      final token = await _messaging.getToken();
      if (token == null || token.trim().isEmpty) {
        return;
      }
      await _registerTokenIfPossible(token);
    } catch (error, stackTrace) {
      developer.log(
        'Failed to fetch push token',
        name: 'PushMessagingService',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _registerTokenIfPossible(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    final trimmedToken = token.trim();
    if (trimmedToken.isEmpty) {
      return;
    }

    if (_lastRegisteredUid == user.uid && _lastRegisteredToken == trimmedToken) {
      return;
    }

    try {
      await _functions.httpsCallable('registerFcmToken').call({
        'token': trimmedToken,
        'platform': _platformLabel(),
      });
      _lastRegisteredUid = user.uid;
      _lastRegisteredToken = trimmedToken;
    } catch (error, stackTrace) {
      developer.log(
        'Failed to register push token',
        name: 'PushMessagingService',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> unregisterCurrentToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _lastRegisteredUid = null;
      _lastRegisteredToken = null;
      return;
    }

    try {
      final token = await _messaging.getToken();
      await _functions.httpsCallable('unregisterFcmToken').call({
        if (token != null && token.trim().isNotEmpty) 'token': token.trim(),
      });
    } catch (error, stackTrace) {
      developer.log(
        'Failed to unregister push token',
        name: 'PushMessagingService',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _lastRegisteredUid = null;
      _lastRegisteredToken = null;
    }
  }

  String _platformLabel() {
    if (kIsWeb) {
      return 'web';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    developer.log(
      'Foreground push received: ${message.messageId}',
      name: 'PushMessagingService',
    );
  }

  void _onOpenedMessage(RemoteMessage message) {
    developer.log(
      'Push opened by user: ${message.messageId}',
      name: 'PushMessagingService',
    );
  }

  Future<void> dispose() async {
    await _authSubscription?.cancel();
    await _tokenRefreshSubscription?.cancel();
    _authSubscription = null;
    _tokenRefreshSubscription = null;
    _isInitialized = false;
  }
}
