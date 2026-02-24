// lib/services/token_service.dart
import 'package:cloud_functions/cloud_functions.dart';

class TokenService {
  static final TokenService _instance = TokenService._internal();
  factory TokenService() => _instance;
  TokenService._internal();

  // Lazy-loaded to ensure Firebase is initialized
  FirebaseFunctions? _functionsInstance;
  FirebaseFunctions get _functions =>
      _functionsInstance ??
      FirebaseFunctions.instanceFor(region: 'us-central1');

  // Generate Agora token for video chat
  Future<String> generateAgoraToken({
    required String channelName,
    required String userId,
    required bool isBroadcaster,
  }) async {
    try {
      final HttpsCallable callable =
          _functions.httpsCallable('generateAgoraToken');
      final result = await callable.call(<String, dynamic>{
        'roomId': channelName,
        'userId': userId,
      });

      final token = result.data['token'] as String;
      return token;
    } catch (e) {
      throw Exception('Failed to generate Agora token: $e');
    }
  }

  // Validate token (optional - for security)
  Future<bool> validateToken(String token) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('validateToken');

      final result = await callable.call(<String, dynamic>{
        'token': token,
      });

      return result.data['valid'] as bool;
    } catch (e) {
      return false;
    }
  }

  // Refresh token if needed
  Future<String> refreshToken({
    required String channelName,
    required String userId,
    required bool isBroadcaster,
  }) async {
    // For now, just generate a new token
    // In production, you might want to check if current token is still valid
    return generateAgoraToken(
      channelName: channelName,
      userId: userId,
      isBroadcaster: isBroadcaster,
    );
  }
}
