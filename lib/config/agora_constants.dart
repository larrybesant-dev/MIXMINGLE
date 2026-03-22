import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Loads Agora App ID from .env file using flutter_dotenv.
/// Ensure you call `await dotenv.load()` in main() before using this constant.
class AgoraConstants {
  static String get appId => dotenv.env['AGORA_APP_ID'] ?? '';
  static const String tokenEndpoint = 'https://us-central1-mix-and-mingle-v2.cloudfunctions.net/generateAgoraToken';
}
