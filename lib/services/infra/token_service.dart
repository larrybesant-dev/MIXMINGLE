// lib/services/token_service.dart
import 'package:cloud_functions/cloud_functions.dart';

class TokenService {
  static final TokenService _instance = TokenService._internal();
  factory TokenService() => _instance;
  TokenService._internal();

  // Lazy-loaded to ensure Firebase is initialized
  FirebaseFunctions? _functionsInstance;
  FirebaseFunctions get _functions => _functionsInstance ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  // Generate Agora token for video chat
  Future<String> generateAgoraToken({
    required String channelName,
    required String userId,
    required bool isBroadcaster,
  }) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('generateAgoraToken');
      final result = await callable.call(<String, dynamic>{
        'roomId': channelName,
        'userId': userId,
      });

      final response = result.data as Map<String, dynamic>;
      final token = response['token'] as String?;
      if (token == null || token.isEmpty) {
        throw Exception('generateAgoraToken response missing token');
      }
      return token;
    } on FirebaseFunctionsException catch (e) {
      final details = e.details == null ? '' : ' (${e.details})';
      throw Exception('Token request failed [${e.code}]: ${e.message ?? 'Unknown backend error'}$details');
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


